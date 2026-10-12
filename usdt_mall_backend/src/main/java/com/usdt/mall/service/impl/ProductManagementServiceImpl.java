package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.CarouselProduct;
import com.usdt.mall.entity.Category;
import com.usdt.mall.entity.Product;
import com.usdt.mall.entity.ProductImage;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.*;
import com.usdt.mall.service.ProductManagementService;
import com.usdt.mall.vo.request.ProductQueryReqVO;
import com.usdt.mall.vo.response.ProductInfoRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 商品管理服务实现类
 */
@Slf4j
@Service
public class ProductManagementServiceImpl implements ProductManagementService {

	@Autowired
	private ProductMapper productMapper;

	@Autowired
	private CategoryMapper categoryMapper;

	@Autowired
	private ProductImageMapper productImageMapper;

	@Autowired
	private ShopMapper shopMapper;

	@Autowired
	private ShopProductMapper shopProductMapper;

	@Autowired
	private CarouselProductMapper carouselProductMapper;

	@Override
	public Map<String, Object> queryProducts(ProductQueryReqVO reqVO) {
		// 构建查询条件
		QueryWrapper<Product> queryWrapper = new QueryWrapper<>();

		// 关键词搜索（商品名称或编号）
		if (reqVO.getKeyword() != null && !reqVO.getKeyword().trim().isEmpty()) {
			String keyword = reqVO.getKeyword().trim();
			queryWrapper.and(wrapper -> wrapper
					.like("name", keyword)
					.or()
					.like("id", keyword)
			);
		}

		// 分类筛选
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
	public ProductInfoRespVO getProductDetail(Long productId) {
		Product product = productMapper.selectById(productId);
		if (product == null) {
			throw new CustomException(ResultCode.PRODUCT_NOT_FOUND);
		}
		return convertToRespVO(product);
	}

	@Override
	public void addProduct(Long userId, String name, String category, String price, Integer stock, String description, List<String> images) {
		// 验证图片数量
		if (images != null && images.size() > 5) {
			throw new CustomException(ResultCode.PRODUCT_IMAGES_LIMIT_EXCEEDED);
		}

		// 查找分类ID
		QueryWrapper<Category> categoryWrapper = new QueryWrapper<>();
		categoryWrapper.eq("name", category);
		Category categoryEntity = categoryMapper.selectOne(categoryWrapper);

		if (categoryEntity == null) {
			throw new CustomException(ResultCode.CATEGORY_NOT_FOUND);
		}

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

		// 保存图片到 product_image 表
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

		log.info("添加商品成功: {}", name);
	}

	@Override
	public void updateProduct(Long productId, String name, String category, String price, Integer stock, Integer sales, Integer views, String status, String description, List<String> images) {
		// 验证图片数量
		if (images != null && images.size() > 5) {
			throw new CustomException(ResultCode.PRODUCT_IMAGES_LIMIT_EXCEEDED);
		}

		Product product = productMapper.selectById(productId);
		if (product == null) {
			throw new CustomException(ResultCode.PRODUCT_NOT_FOUND);
		}

		// 查找分类ID
		QueryWrapper<Category> categoryWrapper = new QueryWrapper<>();
		categoryWrapper.eq("name", category);
		Category categoryEntity = categoryMapper.selectOne(categoryWrapper);

		if (categoryEntity == null) {
			throw new CustomException(ResultCode.CATEGORY_NOT_FOUND);
		}

		product.setName(name);
		product.setCategoryId(categoryEntity.getId());
		product.setPrice(new java.math.BigDecimal(price));
		product.setStock(stock);
		if (sales != null) {
			product.setSales(sales);
		}
		if (views != null) {
			product.setViews(views);
		}
		product.setDescription(description);
		product.setStatus("active".equals(status) ? 1 : 0);

		// 处理图片
		if (images != null && !images.isEmpty()) {
			product.setMainImage(images.get(0)); // 第一张作为主图

			// 删除旧图片
			QueryWrapper<ProductImage> imageWrapper = new QueryWrapper<>();
			imageWrapper.eq("product_id", productId);
			productImageMapper.delete(imageWrapper);

			// 保存新图片到 product_image 表
			for (int i = 0; i < images.size(); i++) {
				ProductImage productImage = new ProductImage();
				productImage.setProductId(productId);
				productImage.setImageUrl(images.get(i));
				productImage.setSortOrder(i);
				productImage.setIsMain(i == 0 ? 1 : 0); // 第一张为主图
				productImageMapper.insert(productImage);
			}
		}

		productMapper.updateById(product);
		log.info("更新商品成功: {}", productId);
	}

	@Override
	public void deleteProduct(Long productId) {
		Product product = productMapper.selectById(productId);
		if (product == null) {
			throw new CustomException(ResultCode.PRODUCT_NOT_FOUND);
		}

		// 删除商品图片
		QueryWrapper<ProductImage> imageWrapper = new QueryWrapper<>();
		imageWrapper.eq("product_id", productId);
		productImageMapper.delete(imageWrapper);

		// 删除轮播图中的该商品
		QueryWrapper<CarouselProduct> carouselWrapper = new QueryWrapper<>();
		carouselWrapper.eq("product_id", productId);
		carouselProductMapper.delete(carouselWrapper);

		// 删除商品
		productMapper.deleteById(productId);
		log.info("删除商品成功: {}", productId);
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
		vo.setViews(product.getViews() != null ? product.getViews() : 0);
		vo.setStatus(product.getStatus() == 1 ? "active" : "inactive");
		vo.setMainImage(product.getMainImage());
		vo.setDescription(product.getDescription());
		vo.setCreateTime(product.getCreateTime());

		// 查询商品的所有图片
		QueryWrapper<ProductImage> imageWrapper = new QueryWrapper<>();
		imageWrapper.eq("product_id", product.getId());
		imageWrapper.orderByAsc("sort_order");
		List<ProductImage> productImages = productImageMapper.selectList(imageWrapper);
		if (productImages != null && !productImages.isEmpty()) {
			List<String> imageUrls = productImages.stream()
					.map(ProductImage::getImageUrl)
					.collect(java.util.stream.Collectors.toList());
			vo.setImages(imageUrls);
		}

		return vo;
	}
}
