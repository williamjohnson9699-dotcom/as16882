package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.ShopProductService;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.ShopProductQueryReqVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.Map;

@Tag(name = "店铺商品管理", description = "店铺商品管理相关接口")
@RestController
@RequestMapping("/api/v1/shop/products")
public class ShopProductController {

	@Autowired
	private ShopProductService shopProductService;

	@Resource
	private JwtUtil jwtUtil;

	@Operation(summary = "查询店铺商品列表", description = "分页查询店铺商品列表")
	@PostMapping("/query")
	public Result<Map<String, Object>> queryProducts(@RequestBody ShopProductQueryReqVO reqVO, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		Map<String, Object> result = shopProductService.queryShopProducts(userId, reqVO);
		return Result.successWith(result);
	}

	@Operation(summary = "删除店铺商品", description = "删除店铺商品")
	@DeleteMapping("/{productId}")
	public Result<?> deleteProduct(@PathVariable Long productId, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		shopProductService.deleteShopProduct(userId, productId);
		return Result.success();
	}

	@Operation(summary = "查询所有商品列表", description = "查询所有商品列表（用于添加视图）")
	@PostMapping("/all")
	public Result<Map<String, Object>> queryAllProducts(@RequestBody Map<String, Object> params, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		String keyword = (String) params.get("keyword");
		String category = (String) params.get("category");
		Integer page = params.get("page") != null ? (Integer) params.get("page") : 1;
		Integer pageSize = params.get("pageSize") != null ? (Integer) params.get("pageSize") : 12;
		Map<String, Object> result = shopProductService.queryAllProducts(userId, keyword, category, page, pageSize);
		return Result.successWith(result);
	}

	@Operation(summary = "添加商品到店铺", description = "添加商品到店铺")
	@PostMapping("/add/{productId}")
	public Result<?> addProductToShop(@PathVariable Long productId, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		shopProductService.addProductToShop(userId, productId);
		return Result.success();
	}

	@Operation(summary = "创建新商品并添加到店铺", description = "创建新商品并添加到店铺")
	@PostMapping("/create")
	public Result<?> createAndAddProduct(@RequestBody Map<String, Object> params, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(com.usdt.mall.common.ResultCode.LOGIN_REQUIRED);
		}

		String name = (String) params.get("name");
		String category = (String) params.get("category");
		String price = (String) params.get("price");
		Integer stock = (Integer) params.get("stock");
		String description = (String) params.get("description");
		java.util.List<String> images = (java.util.List<String>) params.get("images");

		shopProductService.createAndAddProduct(userId, name, category, price, stock, description, images);
		return Result.success();
	}

	/**
	 * 从Token中获取用户ID
	 */
	private Long getUserIdFromToken(HttpServletRequest request) {
		String token = request.getHeader("Authorization");
		if (token != null && token.startsWith("Bearer ")) {
			token = token.substring(7);
			try {
				return jwtUtil.getUserIdFromToken(token);
			} catch (Exception e) {
				return null;
			}
		}
		return null;
	}
}
