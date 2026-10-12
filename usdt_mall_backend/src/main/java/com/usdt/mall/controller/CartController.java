package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.service.CartService;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.AddCartReqVO;
import com.usdt.mall.vo.request.UpdateCartReqVO;
import com.usdt.mall.vo.response.CartRespVO;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.List;

/**
 * 购物车Controller
 */
@RestController
@RequestMapping("/api/v1/cart")
public class CartController {

	@Resource
	private CartService cartService;

	@Resource
	private JwtUtil jwtUtil;

	/**
	 * 添加商品到购物车
	 */
	@PostMapping
	public Result<?> addToCart(@Valid @RequestBody AddCartReqVO reqVO, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		cartService.addToCart(reqVO, userId);
		return Result.success();
	}

	/**
	 * 获取购物车列表
	 */
	@GetMapping
	public Result<List<CartRespVO>> getCartList(HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		List<CartRespVO> cartList = cartService.getCartList(userId);
		return Result.successWith(cartList);
	}

	/**
	 * 获取购物车商品数量
	 */
	@GetMapping("/count")
	public Result<Integer> getCartCount(HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.successWith(0);
		}
		int count = cartService.getCartCount(userId);
		return Result.successWith(count);
	}

	/**
	 * 更新购物车商品数量
	 */
	@PutMapping("/{id}")
	public Result<?> updateCartQuantity(
			@PathVariable Long id,
			@Valid @RequestBody UpdateCartReqVO reqVO,
			HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		cartService.updateCartQuantity(id, reqVO, userId);
		return Result.success();
	}

	/**
	 * 删除购物车商品
	 */
	@DeleteMapping("/{id}")
	public Result<?> deleteCart(@PathVariable Long id, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		cartService.deleteCart(id, userId);
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
