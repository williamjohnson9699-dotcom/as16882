package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.*;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.*;
import com.usdt.mall.service.OrderService;
import com.usdt.mall.service.ShopProductService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.vo.request.ShopProductQueryReqVO;
import com.usdt.mall.vo.response.ProductInfoRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 店铺商品服务实现�?
 */
@Slf4j
@Service
public class ShopProductServiceImpl implements ShopProductService {

	@Autowired
	private ProductMapper productMapper;

	@Autowired
	private ShopMapper shopMapper;

	@Autowired
	private CategoryMapper categoryMapper;

	@Autowired
	private ProductImageMapper productImageMapper;

	@Autowired
	private ShopProductMapper shopProductMapper;

	@Autowired
	private OrderService orderService;

	/**
	 * 店铺用户超过48小时未支付货款时，拒绝继续操作店铺商品。
	 *
	 * @param userId 当前用户ID
	 */
	private void rejectIfSellerPaymentOverdue(Long userId) {
		if (orderService.isSellerPaymentOverdue(userId)) {
			throw new CustomException(ResultCode.PERMISSION_DENIED);
		}
	}

	@Override
	public Map<String, Object> queryShopProducts(Long userId, ShopProductQueryReqVO reqVO) {
		rejectIfSellerPaymentOverdue(userId);
		// 查询用户的店�?
		QueryWrapper<Shop> shopWrapper = new QueryWrapper<>();
		shopWrapper.eq("user_id", userId);
		Shop shop = shopMapper.selectOne(shopWrapper);

		if (shop == null) {
			throw new CustomException(ResultCode.USER_HAS_NO_SHOP);
		}

		// 查询该店铺的所有商品ID
		QueryWrapper<ShopProduct> shopProductWrapper = new QueryWrapper<>();
		shopProductWrapper.eq("shop_id", shop.getId());
		List<ShopProduct> shopProducts = shopProductMapper.selectList(shopProductWrapper);

		if (shopProducts.isEmpty()) {
			// 如果店铺没有商品，返回空结果
			Map<String, Object> result = new HashMap<>();
			result.put("list", new ArrayList<>());
			result.put("total", 0);
			result.put("page", reqVO.getPage());
			result.put("pageSize", reqVO.getPageSize());
			result.put("totalPages", 0);
			return result;
		}

		List<Long> productIds = shopProducts.stream()
				.map(ShopProduct::getProductId)
				.collect(Collectors.toList());

		// 构建商品查询条件
		QueryWrapper<Product> queryWrapper = new QueryWrapper<>();

		// 只查询该店铺的商�?
		queryWrapper.in("id", productIds);

		// 关键词搜索（商品名称�?
		if (reqVO.getKeyword() != null && !reqVO.getKeyword().trim().isEmpty()) {
			queryWrapper.like("name", reqVO.getKeyword().trim());
		}

		// 分类筛�?
		if (reqVO.getCategory() != null && !reqVO.getCategory().trim().isEmpty()
				&& !"all".equals(reqVO.getCategory())) {
			// 通过分类名称查找分类ID
			QueryWrapper<Category> categoryWrapper = new QueryWrapper<>();
			categoryWrapper.eq("name", reqVO.getCategory());
			Category category = categoryMapper.selectOne(categoryWrapper);
			if (category != null) {
				queryWrapper.eq("category_id", category.getId());
			}
		}

		// 按创建时间倒序排列
		queryWrapper.orderByDesc("create_time");

		// 分页查询
		Page<Product> page = new Page<>(reqVO.getPage(), reqVO.getPageSize());
		IPage<Product> productPage = productMapper.selectPage(page, queryWrapper);

		// 转换为响应VO
		List<ProductInfoRespVO> productList = productPage.getRecords().stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());

		// 构建返回结果
		Map<String, Object> result = new HashMap<>();
		result.put("list", productList);
		result.put("total", productPage.getTotal());
		result.put("page", productPage.getCurrent());
		result.put("pageSize", productPage.getSize());
		result.put("totalPages", productPage.getPages());

		return result;
	}

	@Override
	public void deleteShopProduct(Long userId, Long productId) {
		rejectIfSellerPaymentOverdue(userId);
		// 查询用户的店�?
		QueryWrapper<Shop> shopWrapper = new QueryWrapper<>();
		shopWrapper.eq("user_id", userId);
		Shop shop = shopMapper.selectOne(shopWrapper);

		if (shop == null) {
			throw new CustomException(ResultCode.USER_HAS_NO_SHOP);
		}

		// 查询商品是否属于该店�?
		QueryWrapper<ShopProduct> shopProductWrapper = new QueryWrapper<>();
		shopProductWrapper.eq("shop_id", shop.getId());
		shopProductWrapper.eq("product_id", productId);
		ShopProduct shopProduct = shopProductMapper.selectOne(shopProductWrapper);

		if (shopProduct == null) {
			throw new CustomException(ResultCode.PRODUCT_NOT_BELONG_TO_SHOP);
		}

		// 删除店铺商品关联
		shopProductMapper.deleteById(shopProduct.getId());
		log.info("删除店铺商品关联成功: shopId=, productId={}", shop.getId(), productId);
	}

	/**
	 * 转换为响应VO
	 */
	private ProductInfoRespVO convertToRespVO(Product product) {
		ProductInfoRespVO vo = new ProductInfoRespVO();
		vo.setId(product.getId());
		vo.setName(product.getName());

		// 通过categoryId查询分类名称
		if (product.getCategoryId() != null) {
			Category category = categoryMapper.selectById(product.getCategoryId());
			if (category != null) {
				vo.setCategory(category.getName());
			}
		}

		vo.setPrice(product.getPrice().toString());
		vo.setStock(product.getStock());
		vo.setSales(product.getSales() != null ? product.getSales() : 0);
		vo.setStatus(product.getStatus() == 1 ? "active" : "inactive");
		vo.setMainImage(product.getMainImage());
		vo.setDescription(product.getDescription());
		vo.setCreateTime(product.getCreateTime());

		// 查询商品的所有图�?
		QueryWrapper<ProductImage> imageWrapper = new QueryWrapper<>();
		imageWrapper.eq("product_id", product.getId());
		imageWrapper.orderByAsc("sort_order");
		List<ProductImage> productImages = productImageMapper.selectList(imageWrapper);
		if (productImages != null && !productImages.isEmpty()) {
			List<String> imageUrls = productImages.stream()
					.map(ProductImage::getImageUrl)
					.collect(Collectors.toList());
			vo.setImages(imageUrls);
		}

		return vo;
	}

	@Override
	public Map<String, Object> queryAllProducts(Long userId, String keyword, String category, Integer page, Integer pageSize) {
		rejectIfSellerPaymentOverdue(userId);
		// 查询用户的店�?
		QueryWrapper<Shop> shopWrapper = new QueryWrapper<>();
		shopWrapper.eq("user_id", userId);
		Shop shop = shopMapper.selectOne(shopWrapper);

		// 获取店铺中的所有商品ID
		List<Long> shopProductIds = new ArrayList<>();
		if (shop != null) {
			QueryWrapper<ShopProduct> shopProductWrapper = new QueryWrapper<>();
			shopProductWrapper.eq("shop_id", shop.getId());
			List<ShopProduct> shopProducts = shopProductMapper.selectList(shopProductWrapper);
			shopProductIds = shopProducts.stream()
					.map(ShopProduct::getProductId)
					.collect(Collectors.toList());
		}

		// 构建商品查询条件
		QueryWrapper<Product> queryWrapper = new QueryWrapper<>();

		// 关键词搜索（商品名称�?
		if (keyword != null && !keyword.trim().isEmpty()) {
			queryWrapper.like("name", keyword.trim());
		}

		// 分类筛�?
		if (category != null && !category.trim().isEmpty() && !"all".equals(category)) {
			QueryWrapper<Category> categoryWrapper = new QueryWrapper<>();
			categoryWrapper.eq("name", category);
			Category categoryObj = categoryMapper.selectOne(categoryWrapper);
			if (categoryObj != null) {
				queryWrapper.eq("category_id", categoryObj.getId());
			}
		}

		// 按创建时间倒序排列
		queryWrapper.orderByDesc("create_time");

		// 分页查询
		Page<Product> pageObj = new Page<>(page, pageSize);
		IPage<Product> productPage = productMapper.selectPage(pageObj, queryWrapper);

		// 转换为响应VO，并标记是否已在店铺�?
		final List<Long> finalShopProductIds = shopProductIds;
		List<Map<String, Object>> productList = productPage.getRecords().stream()
				.map(product -> {
					ProductInfoRespVO vo = convertToRespVO(product);
					Map<String, Object> map = new HashMap<>();
					map.put("id", vo.getId());
					map.put("name", vo.getName());
					map.put("category", vo.getCategory());
					map.put("price", vo.getPrice());
					map.put("stock", vo.getStock());
					map.put("sales", vo.getSales());
					map.put("status", vo.getStatus());
					map.put("mainImage", vo.getMainImage());
					map.put("description", vo.getDescription());
					map.put("images", vo.getImages());
					map.put("createTime", vo.getCreateTime());
					map.put("inShop", finalShopProductIds.contains(product.getId()));
					return map;
				})
				.collect(Collectors.toList());

		// 构建返回结果
		Map<String, Object> result = new HashMap<>();
		result.put("list", productList);
		result.put("total", productPage.getTotal());
		result.put("page", productPage.getCurrent());
		result.put("pageSize", productPage.getSize());
		result.put("totalPages", productPage.getPages());

		return result;
	}

	@Override
	public void addProductToShop(Long userId, Long productId) {
		rejectIfSellerPaymentOverdue(userId);
		// 查询用户的店�?
		QueryWrapper<Shop> shopWrapper = new QueryWrapper<>();
		shopWrapper.eq("user_id", userId);
		Shop shop = shopMapper.selectOne(shopWrapper);

		if (shop == null) {
			throw new CustomException(ResultCode.USER_HAS_NO_SHOP);
		}

		// 检查商品是否存�?
		Product product = productMapper.selectById(productId);
		if (product == null) {
			throw new CustomException(ResultCode.PARAMETER_ERROR, "商品不存在");
		}

		// 检查商品是否已经在店铺�?
		QueryWrapper<ShopProduct> shopProductWrapper = new QueryWrapper<>();
		shopProductWrapper.eq("shop_id", shop.getId());
		shopProductWrapper.eq("product_id", productId);
		ShopProduct existingShopProduct = shopProductMapper.selectOne(shopProductWrapper);

		if (existingShopProduct != null) {
			throw new CustomException(ResultCode.PRODUCT_ALREADY_IN_SHOP);
		}

		// 添加商品到店�?
		ShopProduct shopProduct = new ShopProduct();
		shopProduct.setShopId(shop.getId());
		shopProduct.setProductId(productId);
		shopProductMapper.insert(shopProduct);

		log.info("添加商品到店铺成�? shopId={}, productId={}", shop.getId(), productId);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void createAndAddProduct(Long userId, String name, String category, String price, Integer stock, String description, List<String> images) {
		rejectIfSellerPaymentOverdue(userId);
		// 验证图片数量
		if (images != null && images.size() > 5) {
			throw new CustomException(ResultCode.PRODUCT_IMAGES_LIMIT_EXCEEDED);
		}

		// 查询用户的店�?
		QueryWrapper<Shop> shopWrapper = new QueryWrapper<>();
		shopWrapper.eq("user_id", userId);
		Shop shop = shopMapper.selectOne(shopWrapper);

		if (shop == null) {
			throw new CustomException(ResultCode.USER_HAS_NO_SHOP);
		}

		// 查找分类ID
		QueryWrapper<Category> categoryWrapper = new QueryWrapper<>();
		categoryWrapper.eq("name", category);
		Category categoryEntity = categoryMapper.selectOne(categoryWrapper);

		if (categoryEntity == null) {
			throw new CustomException(ResultCode.CATEGORY_NOT_FOUND);
		}

		// 创建商品
		Product product = new Product();
		product.setName(name);
		product.setCategoryId(categoryEntity.getId());
		product.setPrice(new java.math.BigDecimal(price));
		product.setStock(stock);
		product.setDescription(description);
		product.setStatus(1); // 默认上架
		product.setSales(0);

		// 设置主图
		if (images != null && !images.isEmpty()) {
			product.setMainImage(images.get(0));
		}

		productMapper.insert(product);

		// 保存图片�?product_image �?
		if (images != null && !images.isEmpty()) {
			for (int i = 0; i < images.size(); i++) {
				ProductImage productImage = new ProductImage();
				productImage.setProductId(product.getId());
				productImage.setImageUrl(images.get(i));
				productImage.setSortOrder(i);
				productImage.setIsMain(i == 0 ? 1 : 0); // 第一张为主图
				productImageMapper.insert(productImage);
			}
		}

		// 将商品添加到店铺
		ShopProduct shopProduct = new ShopProduct();
		shopProduct.setShopId(shop.getId());
		shopProduct.setProductId(product.getId());
		shopProduct.setCreateTime(DateTimeUtil.nowUtc());
		shopProduct.setUpdateTime(DateTimeUtil.nowUtc());
		shopProductMapper.insert(shopProduct);

		log.info("创建商品并添加到店铺成功: shopId={}, productId={}, productName={}", shop.getId(), product.getId(), name);
	}
}
