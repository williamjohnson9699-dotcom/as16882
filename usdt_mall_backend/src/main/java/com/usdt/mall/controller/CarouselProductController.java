package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.CarouselProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Tag(name = "轮播商品管理", description = "轮播商品管理相关接口")
@RestController
@RequestMapping("/api/v1/carousel")
public class CarouselProductController {

	@Autowired
	private CarouselProductService carouselProductService;

	@Operation(summary = "获取轮播商品列表", description = "获取首页轮播商品列表")
	@GetMapping("/products")
	public Result<List<Map<String, Object>>> getCarouselProducts() {
		List<Map<String, Object>> products = carouselProductService.getCarouselProducts();
		return Result.successWith(products);
	}

	@Operation(summary = "获取所有商品列表", description = "获取所有商品列表用于选择")
	@GetMapping("/all-products")
	public Result<List<Map<String, Object>>> getAllProducts() {
		List<Map<String, Object>> products = carouselProductService.getAllProducts();
		return Result.successWith(products);
	}

	@Operation(summary = "分页搜索商品", description = "分页搜索商品用于选择")
	@GetMapping("/search-products")
	public Result<Map<String, Object>> searchProducts(
			@RequestParam(required = false) String keyword,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "10") Integer pageSize) {
		Map<String, Object> result = carouselProductService.searchProducts(keyword, page, pageSize);
		return Result.successWith(result);
	}

	@Operation(summary = "添加轮播商品", description = "添加商品到轮播列表")
	@PostMapping("/products/{productId}")
	public Result<?> addCarouselProduct(@PathVariable Long productId) {
		carouselProductService.addCarouselProduct(productId);
		return Result.success();
	}

	@Operation(summary = "删除轮播商品", description = "从轮播列表删除商品")
	@DeleteMapping("/products/{carouselId}")
	public Result<?> deleteCarouselProduct(@PathVariable Long carouselId) {
		carouselProductService.deleteCarouselProduct(carouselId);
		return Result.success();
	}

	@Operation(summary = "更新轮播商品排序", description = "更新轮播商品的排序顺序")
	@PutMapping("/products/order")
	public Result<?> updateCarouselOrder(@RequestBody Map<String, Object> params) {
		@SuppressWarnings("unchecked")
		List<Object> productIdsObj = (List<Object>) params.get("productIds");

		// 将 Integer 转换为 Long
		List<Long> productIds = productIdsObj.stream()
				.map(obj -> {
					if (obj instanceof Integer) {
						return ((Integer) obj).longValue();
					} else if (obj instanceof Long) {
						return (Long) obj;
					} else {
						return Long.parseLong(obj.toString());
					}
				})
				.collect(java.util.stream.Collectors.toList());

		carouselProductService.updateCarouselOrder(productIds);
		return Result.success();
	}
}
