package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.service.ProductManagementService;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.ProductQueryReqVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;

@Tag(name = "商品管理", description = "商品管理相关接口")
@RestController
@RequestMapping("/api/v1/product-management")
public class ProductManagementController {

	@Autowired
	private ProductManagementService productManagementService;

	@Resource
	private JwtUtil jwtUtil;

	@Operation(summary = "查询商品列表", description = "分页查询商品列表")
	@PostMapping("/query")
	public Result<Map<String, Object>> queryProducts(@RequestBody ProductQueryReqVO reqVO) {
		Map<String, Object> result = productManagementService.queryProducts(reqVO);
		return Result.successWith(result);
	}

	@Operation(summary = "获取商品详情", description = "根据商品ID获取商品详情")
	@GetMapping("/products/{productId}")
	public Result<?> getProductDetail(@PathVariable Long productId) {
		return Result.successWith(productManagementService.getProductDetail(productId));
	}

	@Operation(summary = "添加商品", description = "添加新商品")
	@PostMapping("/products")
	public Result<?> addProduct(@RequestBody Map<String, Object> params, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}

		String name = (String) params.get("name");
		String category = (String) params.get("category");
		String price = (String) params.get("price");
		Integer stock = (Integer) params.get("stock");
		String description = (String) params.get("description");
		List<String> images = (List<String>) params.get("images");

		productManagementService.addProduct(userId, name, category, price, stock, description, images);
		return Result.success();
	}

	@Operation(summary = "批量添加商品", description = "批量添加多个不同商品")
	@PostMapping("/products/batch")
	public Result<?> batchAddProduct(@RequestBody Map<String, Object> params, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}

		List<Map<String, Object>> products = (List<Map<String, Object>>) params.get("products");
		if (products == null || products.isEmpty()) {
			return Result.error().newCnMsg("商品列表不能为空");
		}

		if (products.size() > 100) {
			return Result.error().newCnMsg("单次最多添加100个商品");
		}

		for (Map<String, Object> product : products) {
			String name = (String) product.get("name");
			String category = (String) product.get("category");
			String price = (String) product.get("price");
			Integer stock = (Integer) product.get("stock");
			String description = (String) product.get("description");
			List<String> images = (List<String>) product.get("images");

			productManagementService.addProduct(userId, name, category, price, stock, description, images);
		}
		return Result.success();
	}

	@Operation(summary = "更新商品", description = "更新商品信息")
	@PutMapping("/products/{productId}")
	public Result<?> updateProduct(@PathVariable Long productId, @RequestBody Map<String, Object> params) {
		String name = (String) params.get("name");
		String category = (String) params.get("category");
		String price = (String) params.get("price");
		Integer stock = (Integer) params.get("stock");
		Integer sales = (Integer) params.get("sales");
		Integer views = (Integer) params.get("views");
		String status = (String) params.get("status");
		String description = (String) params.get("description");
		List<String> images = (List<String>) params.get("images");

		productManagementService.updateProduct(productId, name, category, price, stock, sales, views, status, description, images);
		return Result.success();
	}

	@Operation(summary = "删除商品", description = "删除商品")
	@DeleteMapping("/products/{productId}")
	public Result<?> deleteProduct(@PathVariable Long productId) {
		productManagementService.deleteProduct(productId);
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
