package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.usdt.mall.entity.Product;
import com.usdt.mall.entity.ProductImage;
import com.usdt.mall.entity.Shop;
import com.usdt.mall.entity.ShopProduct;
import com.usdt.mall.entity.User;
import com.usdt.mall.entity.VirtualImportTask;
import com.usdt.mall.mapper.ProductImageMapper;
import com.usdt.mall.mapper.ProductMapper;
import com.usdt.mall.mapper.ShopMapper;
import com.usdt.mall.mapper.ShopProductMapper;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.mapper.VirtualImportTaskMapper;
import com.usdt.mall.util.DateTimeUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 把现有商品的名称、图片和价格复制到选中的店铺。每条单独提交，一条失败不影响其他条。
 */
@Slf4j
@Component
public class VirtualProductWorker {

	private static final int POOL_LIMIT = 800;

	private static final int DEFAULT_STOCK = 100;

	private static final int MAX_FAIL_DETAILS = 50;

	@Resource
	private VirtualImportTaskMapper virtualImportTaskMapper;

	@Resource
	private ProductMapper productMapper;

	@Resource
	private ProductImageMapper productImageMapper;

	@Resource
	private ShopMapper shopMapper;

	@Resource
	private ShopProductMapper shopProductMapper;

	@Resource
	private UserMapper userMapper;

	@Resource
	private ObjectMapper objectMapper;

	@Resource
	private PlatformTransactionManager transactionManager;

	public void run(Long taskId) {
		try {
			doRun(taskId);
		} catch (Exception e) {
			log.error("virtual product import interrupted, taskId={}", taskId, e);
			VirtualImportTask task = virtualImportTaskMapper.selectById(taskId);
			if (task != null && ("PENDING".equals(task.getStatus()) || "RUNNING".equals(task.getStatus()))) {
				finish(taskId, "FAILED",
						task.getSuccessCount() == null ? 0 : task.getSuccessCount(),
						task.getFailCount() == null ? 0 : task.getFailCount(),
						"生成中断", readFailDetails(task.getFailDetails()));
			}
		}
	}

	private void doRun(Long taskId) {
		VirtualImportTask task = virtualImportTaskMapper.selectById(taskId);
		if (task == null || !"PRODUCT".equals(task.getType()) || !"PENDING".equals(task.getStatus())) {
			return;
		}
		if (claim(taskId) == 0) {
			return;
		}

		Map<String, Object> request = readRequest(task.getRequestJson());
		List<Long> shopIds = readLongs(request.get("shopIds"));
		int count = readInt(request.get("count"));
		int totalCount = task.getTotalCount() == null ? 0 : task.getTotalCount();
		if (shopIds.isEmpty() || count < 1) {
			finish(taskId, "FAILED", 0, totalCount, "任务参数无法读取", Collections.emptyList());
			return;
		}

		List<Product> pool = loadPool();
		if (pool.isEmpty()) {
			List<Map<String, String>> details = new ArrayList<>();
			details.add(detail("商品库", "没有可复制的商品"));
			finish(taskId, "FAILED", 0, totalCount, "没有可复制的商品", details);
			return;
		}
		Map<Long, List<ProductImage>> images = loadImages(pool);
		TransactionTemplate transactionTemplate = new TransactionTemplate(transactionManager);

		int success = 0;
		int fail = 0;
		List<Map<String, String>> details = new ArrayList<>();
		boolean truncated = false;
		int shopIndex = 0;
		for (Long shopId : shopIds) {
			Shop shop = shopMapper.selectById(shopId);
			User seller = shop == null || shop.getUserId() == null ? null : userMapper.selectById(shop.getUserId());
			String target = seller != null && seller.getUsername() != null && !seller.getUsername().trim().isEmpty()
					? seller.getUsername()
					: String.valueOf(shopId);
			if (shop == null) {
				fail += count;
				truncated = addDetail(details, truncated, target, "店铺不存在");
			} else {
				for (int i = 0; i < count; i++) {
					Product source = pool.get(Math.floorMod(shopIndex * count + i, pool.size()));
					String itemTarget = target + " 第" + (i + 1) + "条";
					String reason = copyProduct(transactionTemplate, shopId, source, images.get(source.getId()));
					if (reason == null) {
						success++;
					} else {
						fail++;
						truncated = addDetail(details, truncated, itemTarget, reason);
					}
				}
			}
			shopIndex++;
			progress(taskId, success, fail,
					"已处理 " + shopIndex + "/" + shopIds.size() + " 家店，成功 " + success + "，失败 " + fail,
					details);
		}
		if (truncated) {
			details.add(detail("其余", "还有失败未逐条列出"));
		}

		String status;
		if (fail == 0) {
			status = "SUCCESS";
		} else if (success == 0) {
			status = "FAILED";
		} else {
			status = "PARTIAL";
		}
		finish(taskId, status, success, fail, "生成完成，成功 " + success + "，失败 " + fail, details);
	}

	private String copyProduct(TransactionTemplate transactionTemplate, Long shopId, Product source,
			List<ProductImage> sourceImages) {
		try {
			return transactionTemplate.execute(status -> {
				try {
					LocalDateTime now = DateTimeUtil.nowUtc();
					Product created = new Product();
					created.setName(cut(source.getName(), 200));
					created.setDescription(source.getDescription());
					created.setPrice(source.getPrice());
					created.setStock(source.getStock() != null && source.getStock() > 0
							? source.getStock() : DEFAULT_STOCK);
					created.setSales(0);
					created.setViews(0);
					created.setMainImage(cut(source.getMainImage(), 255));
					created.setImages(source.getImages());
					created.setCategoryId(source.getCategoryId());
					created.setStatus(1);
					created.setIsHot(0);
					created.setCreateTime(now);
					created.setUpdateTime(now);
					productMapper.insert(created);

					if (sourceImages != null) {
						for (ProductImage image : sourceImages) {
							if (image.getImageUrl() == null || image.getImageUrl().trim().isEmpty()) {
								continue;
							}
							ProductImage copy = new ProductImage();
							copy.setProductId(created.getId());
							copy.setImageUrl(cut(image.getImageUrl(), 500));
							copy.setSortOrder(image.getSortOrder() == null ? 0 : image.getSortOrder());
							copy.setIsMain(image.getIsMain() == null ? 0 : image.getIsMain());
							copy.setCreateTime(now);
							productImageMapper.insert(copy);
						}
					}

					ShopProduct link = new ShopProduct();
					link.setShopId(shopId);
					link.setProductId(created.getId());
					link.setCreateTime(now);
					link.setUpdateTime(now);
					shopProductMapper.insert(link);
					return null;
				} catch (Exception e) {
					status.setRollbackOnly();
					log.warn("copy virtual product failed, shopId={}, sourceId={}", shopId, source.getId(), e);
					return "创建失败";
				}
			});
		} catch (Exception e) {
			log.warn("copy virtual product failed, shopId={}, sourceId={}", shopId, source.getId(), e);
			return "创建失败";
		}
	}

	private List<Product> loadPool() {
		List<Product> withImage = queryPool(true);
		if (!withImage.isEmpty()) {
			return withImage;
		}
		return queryPool(false);
	}

	private List<Product> queryPool(boolean requireImage) {
		LambdaQueryWrapper<Product> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Product::getStatus, 1);
		wrapper.isNotNull(Product::getName);
		wrapper.ne(Product::getName, "");
		wrapper.isNotNull(Product::getPrice);
		wrapper.gt(Product::getPrice, BigDecimal.ZERO);
		if (requireImage) {
			wrapper.isNotNull(Product::getMainImage);
			wrapper.ne(Product::getMainImage, "");
		}
		wrapper.orderByAsc(Product::getId);
		wrapper.last("LIMIT " + POOL_LIMIT);
		List<Product> products = productMapper.selectList(wrapper);
		if (products == null) {
			return Collections.emptyList();
		}
		List<Product> usable = new ArrayList<>();
		for (Product product : products) {
			if (product.getId() == null || product.getName() == null || product.getName().trim().isEmpty()) {
				continue;
			}
			if (product.getPrice() == null || product.getPrice().compareTo(BigDecimal.ZERO) <= 0) {
				continue;
			}
			usable.add(product);
		}
		return usable;
	}

	private Map<Long, List<ProductImage>> loadImages(List<Product> pool) {
		List<Long> ids = new ArrayList<>();
		for (Product product : pool) {
			ids.add(product.getId());
		}
		Map<Long, List<ProductImage>> images = new HashMap<>();
		for (int offset = 0; offset < ids.size(); offset += 500) {
			List<Long> part = ids.subList(offset, Math.min(offset + 500, ids.size()));
			LambdaQueryWrapper<ProductImage> wrapper = new LambdaQueryWrapper<>();
			wrapper.in(ProductImage::getProductId, part);
			wrapper.orderByAsc(ProductImage::getSortOrder);
			List<ProductImage> rows = productImageMapper.selectList(wrapper);
			if (rows == null) {
				continue;
			}
			for (ProductImage row : rows) {
				if (row.getProductId() == null) {
					continue;
				}
				List<ProductImage> list = images.get(row.getProductId());
				if (list == null) {
					list = new ArrayList<>();
					images.put(row.getProductId(), list);
				}
				list.add(row);
			}
		}
		return images;
	}

	private boolean addDetail(List<Map<String, String>> details, boolean truncated, String target, String reason) {
		if (details.size() >= MAX_FAIL_DETAILS) {
			return true;
		}
		details.add(detail(target, reason));
		return truncated;
	}

	private int claim(Long taskId) {
		UpdateWrapper<VirtualImportTask> wrapper = new UpdateWrapper<>();
		wrapper.eq("id", taskId).eq("status", "PENDING").eq("type", "PRODUCT");
		wrapper.set("status", "RUNNING");
		wrapper.set("message", "正在生成商品");
		wrapper.set("update_time", DateTimeUtil.nowUtc());
		return virtualImportTaskMapper.update(null, wrapper);
	}

	private void progress(Long taskId, int success, int fail, String message, List<Map<String, String>> details) {
		VirtualImportTask update = new VirtualImportTask();
		update.setId(taskId);
		update.setSuccessCount(success);
		update.setFailCount(fail);
		update.setMessage(cut(message, 500));
		update.setFailDetails(writeJson(details));
		update.setUpdateTime(DateTimeUtil.nowUtc());
		virtualImportTaskMapper.updateById(update);
	}

	private void finish(Long taskId, String status, int success, int fail, String message,
			List<Map<String, String>> details) {
		VirtualImportTask update = new VirtualImportTask();
		update.setId(taskId);
		update.setStatus(status);
		update.setSuccessCount(success);
		update.setFailCount(fail);
		update.setMessage(cut(message, 500));
		update.setFailDetails(writeJson(details));
		update.setFinishTime(DateTimeUtil.nowUtc());
		update.setUpdateTime(update.getFinishTime());
		virtualImportTaskMapper.updateById(update);
	}

	private Map<String, String> detail(String target, String reason) {
		Map<String, String> item = new LinkedHashMap<>();
		item.put("target", target);
		item.put("reason", reason);
		return item;
	}

	private Map<String, Object> readRequest(String raw) {
		if (raw == null || raw.trim().isEmpty()) {
			return Collections.emptyMap();
		}
		try {
			return objectMapper.readValue(raw, new TypeReference<Map<String, Object>>() {
			});
		} catch (Exception e) {
			return Collections.emptyMap();
		}
	}

	private List<Long> readLongs(Object raw) {
		if (!(raw instanceof List)) {
			return Collections.emptyList();
		}
		List<Long> values = new ArrayList<>();
		for (Object item : (List<?>) raw) {
			if (item instanceof Number) {
				values.add(((Number) item).longValue());
			}
		}
		return values;
	}

	private int readInt(Object raw) {
		if (raw instanceof Number) {
			return ((Number) raw).intValue();
		}
		return 0;
	}

	private List<Map<String, String>> readFailDetails(String raw) {
		if (raw == null || raw.trim().isEmpty()) {
			return new ArrayList<>();
		}
		try {
			return objectMapper.readValue(raw, new TypeReference<List<Map<String, String>>>() {
			});
		} catch (Exception e) {
			return new ArrayList<>();
		}
	}

	private String writeJson(Object value) {
		try {
			return objectMapper.writeValueAsString(value);
		} catch (Exception e) {
			return "[]";
		}
	}

	private String cut(String value, int max) {
		if (value == null) {
			return null;
		}
		if (value.length() <= max) {
			return value;
		}
		return value.substring(0, max);
	}
}
