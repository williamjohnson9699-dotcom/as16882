package com.usdt.mall.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.service.ProductService;
import com.usdt.mall.vo.request.ProductSearchReqVO;
import com.usdt.mall.vo.response.ProductRespVO;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;

/**
 * 商品Controller
 */
@RestController
@RequestMapping("/api/v1/product")
public class ProductController {

	@Resource
	private ProductService productService;

	/**
	 * 搜索商品
	 */
	@GetMapping("/search")
	public Result<Page<ProductRespVO>> searchProducts(ProductSearchReqVO reqVO) {
		Page<ProductRespVO> page = productService.searchProducts(reqVO);
		return Result.successWith(page);
	}

	/**
	 * 获取商品详情
	 */
	@GetMapping("/{id}")
	public Result<ProductRespVO> getProductDetail(@PathVariable Long id) {
		// 增加浏览量
		productService.increaseViews(id);

		ProductRespVO product = productService.getProductDetail(id);
		if (product == null) {
			return Result.of(ResultCode.PRODUCT_NOT_FOUND);
		}
		return Result.successWith(product);
	}

	/**
	 * 根据分类获取商品列表
	 */
	@GetMapping("/category/{categoryId}")
	public Result<Page<ProductRespVO>> getProductsByCategory(
			@PathVariable Long categoryId,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "20") Integer pageSize) {
		Page<ProductRespVO> result = productService.getProductsByCategory(categoryId, page, pageSize);
		return Result.successWith(result);
	}

	/**
	 * 获取热卖商品列表
	 */
	@GetMapping("/hot")
	public Result<Page<ProductRespVO>> getHotProducts(
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "30") Integer pageSize) {
		Page<ProductRespVO> result = productService.getHotProducts(page, pageSize);
		return Result.successWith(result);
	}

	/**
	 * 获取推荐商品列表（猜你喜欢）
	 */
	@GetMapping("/{id}/recommend")
	public Result<Page<ProductRespVO>> getRecommendProducts(
			@PathVariable Long id,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "10") Integer pageSize) {
		Page<ProductRespVO> result = productService.getRecommendProducts(id, page, pageSize);
		return Result.successWith(result);
	}

	/**
	 * 获取商品关联的店铺列表
	 */
	@GetMapping("/{id}/shops")
	public Result<java.util.List<java.util.Map<String, Object>>> getProductShops(@PathVariable Long id) {
		java.util.List<java.util.Map<String, Object>> shops = productService.getProductShops(id);
		return Result.successWith(shops);
	}
}
