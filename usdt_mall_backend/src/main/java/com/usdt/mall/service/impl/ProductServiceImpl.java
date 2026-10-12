package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.entity.*;
import com.usdt.mall.mapper.*;
import com.usdt.mall.service.ProductService;
import com.usdt.mall.util.ProductMainImageResolver;
import com.usdt.mall.vo.request.ProductSearchReqVO;
import com.usdt.mall.vo.response.ProductRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 商品Service实现类
 */
@Slf4j
@Service
public class ProductServiceImpl implements ProductService {

	@Resource
	private ProductMapper productMapper;

	@Resource
	private CategoryMapper categoryMapper;

	@Resource
	private ProductImageMapper productImageMapper;

	@Resource
	private ShopProductMapper shopProductMapper;

	@Resource
	private ShopMapper shopMapper;

	@Resource
	private UserMapper userMapper;

	@Resource
	private ProductMainImageResolver productMainImageResolver;

	@Override
	public Page<ProductRespVO> searchProducts(ProductSearchReqVO reqVO) {
		Page<Product> page = new Page<>(reqVO.getPage(), reqVO.getPageSize());
		LambdaQueryWrapper<Product> wrapper = new LambdaQueryWrapper<>();

		// 店铺筛选
		if (reqVO.getShopId() != null) {
			log.info("查询店铺商品 - 店铺ID: {}", reqVO.getShopId());
			// 先查询该店铺的所有商品ID
			LambdaQueryWrapper<ShopProduct> shopProductWrapper = new LambdaQueryWrapper<>();
			shopProductWrapper.eq(ShopProduct::getShopId, reqVO.getShopId());
			List<ShopProduct> shopProducts = shopProductMapper.selectList(shopProductWrapper);
			log.info("店铺关联商品数量: {}", shopProducts.size());

			if (shopProducts.isEmpty()) {
				// 如果店铺没有商品，返回空结果
				log.warn("店铺 {} 没有关联商品", reqVO.getShopId());
				return new Page<>(reqVO.getPage(), reqVO.getPageSize());
			}

			// 提取商品ID列表
			List<Long> productIds = shopProducts.stream()
					.map(ShopProduct::getProductId)
					.collect(Collectors.toList());
			log.info("店铺商品ID列表: {}", productIds);
			wrapper.in(Product::getId, productIds);
		}

		// 关键词搜索
		if (reqVO.getKeyword() != null && !reqVO.getKeyword().isEmpty()) {
			wrapper.like(Product::getName, reqVO.getKeyword());
		}

		// 分类筛选
		if (reqVO.getCategoryId() != null) {
			wrapper.eq(Product::getCategoryId, reqVO.getCategoryId());
		}

		// 热卖筛选
		if (reqVO.getIsHot() != null) {
			wrapper.eq(Product::getIsHot, reqVO.getIsHot());
		}

		// 只查询上架商品
		wrapper.eq(Product::getStatus, 1);
		wrapper.orderByDesc(Product::getCreateTime);

		Page<Product> productPage = productMapper.selectPage(page, wrapper);
		log.info("查询到商品数量: {}", productPage.getRecords().size());
		return convertToRespVO(productPage, reqVO.getShopId());
	}

	@Override
	public ProductRespVO getProductDetail(Long id) {
		Product product = productMapper.selectById(id);
		if (product == null) {
			return null;
		}
		return convertToRespVO(product, null);
	}

	@Override
	public Page<ProductRespVO> getProductsByCategory(Long categoryId, Integer page, Integer pageSize) {
		Page<Product> productPage = new Page<>(page, pageSize);
		LambdaQueryWrapper<Product> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Product::getCategoryId, categoryId);
		wrapper.eq(Product::getStatus, 1);
		wrapper.orderByDesc(Product::getCreateTime);

		Page<Product> result = productMapper.selectPage(productPage, wrapper);
		return convertToRespVO(result, null);
	}

	@Override
	public Page<ProductRespVO> getHotProducts(Integer page, Integer pageSize) {
		Page<Product> productPage = new Page<>(page, pageSize);
		LambdaQueryWrapper<Product> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Product::getIsHot, 1);
		wrapper.eq(Product::getStatus, 1);
		wrapper.orderByDesc(Product::getSales);

		Page<Product> result = productMapper.selectPage(productPage, wrapper);
		return convertToRespVO(result, null);
	}

	@Override
	public Page<ProductRespVO> getRecommendProducts(Long productId, Integer page, Integer pageSize) {
		Product currentProduct = productMapper.selectById(productId);
		if (currentProduct == null) {
			return new Page<>(page, pageSize);
		}

		Page<Product> productPage = new Page<>(page, pageSize);
		LambdaQueryWrapper<Product> wrapper = new LambdaQueryWrapper<>();

		// 推荐同分类的商品
		wrapper.eq(Product::getCategoryId, currentProduct.getCategoryId());
		// 排除当前商品
		wrapper.ne(Product::getId, productId);
		// 只查询上架商品
		wrapper.eq(Product::getStatus, 1);
		// 按销量排序
		wrapper.orderByDesc(Product::getSales);

		Page<Product> result = productMapper.selectPage(productPage, wrapper);
		return convertToRespVO(result, null);
	}

	@Override
	public void increaseViews(Long id) {
		Product product = productMapper.selectById(id);
		if (product != null) {
			product.setViews(product.getViews() + 1);
			productMapper.updateById(product);
		}
	}

	private Page<ProductRespVO> convertToRespVO(Page<Product> productPage, Long shopId) {
		Page<ProductRespVO> respPage = new Page<>();
		respPage.setCurrent(productPage.getCurrent());
		respPage.setSize(productPage.getSize());
		respPage.setTotal(productPage.getTotal());
		respPage.setRecords(productPage.getRecords().stream()
				.map(product -> convertToRespVO(product, shopId, true))
				.collect(java.util.stream.Collectors.toList()));
		return respPage;
	}

	private ProductRespVO convertToRespVO(Product product, Long shopId) {
		return convertToRespVO(product, shopId, false);
	}

	private ProductRespVO convertToRespVO(Product product, Long shopId, boolean fillEmptyMainImage) {
		ProductRespVO respVO = new ProductRespVO();
		// 手动复制属性，跳过images字段
		respVO.setId(product.getId());
		respVO.setName(product.getName());
		respVO.setDescription(product.getDescription());
		respVO.setPrice(product.getPrice());
		respVO.setStock(product.getStock());
		respVO.setSales(product.getSales());
		respVO.setViews(product.getViews());
		respVO.setMainImage(product.getMainImage());
		respVO.setCategoryId(product.getCategoryId());
		respVO.setStatus(product.getStatus());
		respVO.setIsHot(product.getIsHot());
		respVO.setCreateTime(product.getCreateTime());

		// 查询分类名称
		Category category = categoryMapper.selectById(product.getCategoryId());
		if (category != null) {
			respVO.setCategoryName(category.getName());
		}

		// 查询店铺信息
		if (shopId != null) {
			// 如果指定了店铺ID，直接使用该店铺信息
			Shop shop = shopMapper.selectById(shopId);
			if (shop != null) {
				respVO.setShopId(shop.getId());
				respVO.setShopName(shop.getName());
			}
		} else {
			// 如果没有指定店铺ID，查询商品关联的店铺（取第一个）
			LambdaQueryWrapper<ShopProduct> shopProductWrapper = new LambdaQueryWrapper<>();
			shopProductWrapper.eq(ShopProduct::getProductId, product.getId());
			shopProductWrapper.last("LIMIT 1");
			List<ShopProduct> shopProducts = shopProductMapper.selectList(shopProductWrapper);
			if (!shopProducts.isEmpty()) {
				ShopProduct shopProduct = shopProducts.get(0);
				Shop shop = shopMapper.selectById(shopProduct.getShopId());
				if (shop != null) {
					respVO.setShopId(shop.getId());
					respVO.setShopName(shop.getName());
				}
			}
		}

		// 查询商品图片列表
		LambdaQueryWrapper<ProductImage> imageWrapper = new LambdaQueryWrapper<>();
		imageWrapper.eq(ProductImage::getProductId, product.getId());
		imageWrapper.orderByAsc(ProductImage::getSortOrder);
		List<ProductImage> productImages = productImageMapper.selectList(imageWrapper);

		// 转换为图片URL列表
		List<String> imageList = productImages.stream()
				.map(ProductImage::getImageUrl)
				.collect(Collectors.toList());

		// 如果没有图片但有mainImage，将mainImage添加到列表中
		if (imageList.isEmpty() && product.getMainImage() != null && !product.getMainImage().isEmpty()) {
			imageList.add(product.getMainImage());
		}

		respVO.setImages(imageList);
		if (fillEmptyMainImage) {
			respVO.setMainImage(productMainImageResolver.resolve(product.getMainImage(), imageList));
		}

		return respVO;
	}

	@Override
	public List<java.util.Map<String, Object>> getProductShops(Long productId) {
		// 查询商品关联的店铺列表
		LambdaQueryWrapper<ShopProduct> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(ShopProduct::getProductId, productId);
		List<ShopProduct> shopProducts = shopProductMapper.selectList(wrapper);

		// 获取店铺详情
		List<java.util.Map<String, Object>> result = new ArrayList<>();
		for (ShopProduct shopProduct : shopProducts) {
			Shop shop = shopMapper.selectById(shopProduct.getShopId());
			if (shop != null && shop.getStatus() == 1) { // 只返回营业中的店铺
				// 校验店铺对应的用户是否是店铺角色
				if (shop.getUserId() != null) {
					User user = userMapper.selectById(shop.getUserId());
					if (user != null && "SHOP".equalsIgnoreCase(user.getRole())) {
						java.util.Map<String, Object> shopMap = new java.util.HashMap<>();
						shopMap.put("id", shop.getId());
						shopMap.put("name", shop.getName());
						shopMap.put("logo", shop.getLogo());
						shopMap.put("rating", shop.getRating());
						shopMap.put("level", shop.getLevel());
						result.add(shopMap);
					}
				}
			}
		}
		return result;
	}
}
