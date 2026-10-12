package com.usdt.mall.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.service.ShopService;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.ShopSearchReqVO;
import com.usdt.mall.vo.response.ProductRespVO;
import com.usdt.mall.vo.response.ShopRespVO;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.Map;

/**
 * 店铺Controller
 */
@RestController
@RequestMapping("/api/v1/shop")
public class ShopController {

	@Resource
	private ShopService shopService;

	@Resource
	private JwtUtil jwtUtil;

	/**
	 * 搜索店铺
	 */
	@GetMapping("/search")
	public Result<Page<ShopRespVO>> searchShops(ShopSearchReqVO reqVO) {
		Page<ShopRespVO> page = shopService.searchShops(reqVO);
		return Result.successWith(page);
	}

	/**
	 * 获取店铺详情
	 */
	@GetMapping("/{id}")
	public Result<ShopRespVO> getShopDetail(@PathVariable Long id, HttpServletRequest request) {
		// 增加浏览量
		shopService.increaseViews(id);

		// 获取当前用户ID
		Long userId = getUserIdFromToken(request);

		ShopRespVO shop = shopService.getShopDetail(id, userId);
		if (shop == null) {
			return Result.of(ResultCode.SHOP_NOT_FOUND);
		}
		return Result.successWith(shop);
	}

	/**
	 * 获取店铺商品列表
	 */
	@GetMapping("/{id}/products")
	public Result<Page<ProductRespVO>> getShopProducts(
			@PathVariable Long id,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "20") Integer pageSize) {
		Page<ProductRespVO> result = shopService.getShopProducts(id, page, pageSize);
		return Result.successWith(result);
	}

	/**
	 * 关注店铺
	 */
	@PostMapping("/{id}/follow")
	public Result<?> followShop(@PathVariable Long id, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		shopService.followShop(id, userId);
		return Result.success();
	}

	/**
	 * 取消关注店铺
	 */
	@DeleteMapping("/{id}/follow")
	public Result<?> unfollowShop(@PathVariable Long id, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		shopService.unfollowShop(id, userId);
		return Result.success();
	}

	/**
	 * 检查是否关注店铺
	 */
	@GetMapping("/{id}/follow/status")
	public Result<Boolean> checkFollowStatus(@PathVariable Long id, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		Boolean isFollowed = shopService.isFollowed(id, userId);
		return Result.successWith(isFollowed);
	}

	/**
	 * 获取我的店铺信息
	 */
	@GetMapping("/my-shop")
	public Result<ShopRespVO> getMyShop(HttpServletRequest request) {
		String token = request.getHeader("Authorization");
		if (token != null && token.startsWith("Bearer ")) {
			token = token.substring(7);
		}

		ShopRespVO shop = shopService.getMyShop(token);
		if (shop == null) {
			return Result.of(ResultCode.SHOP_NOT_FOUND);
		}
		return Result.successWith(shop);
	}

	/**
	 * 获取店铺统计信息
	 */
	@GetMapping("/{id}/statistics")
	public Result<Map<String, Object>> getShopStatistics(@PathVariable Long id) {
		Map<String, Object> statistics = shopService.getShopStatistics(id);
		return Result.successWith(statistics);
	}

	/**
	 * 获取我的关注列表
	 */
	@GetMapping("/my-follows")
	public Result<Page<ShopRespVO>> getMyFollows(
			@RequestParam(defaultValue = "") String keyword,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "20") Integer pageSize,
			HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		Page<ShopRespVO> result = shopService.getMyFollows(userId, keyword, page, pageSize);
		return Result.successWith(result);
	}

	/**
	 * 获取我的关注统计
	 */
	@GetMapping("/my-follow-stats")
	public Result<Map<String, Integer>> getMyFollowStats(HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		Map<String, Integer> stats = shopService.getMyFollowStats(userId);
		return Result.successWith(stats);
	}

	/**
	 * 更新店铺信息
	 */
	@PutMapping("/{id}")
	public Result<?> updateShop(
			@PathVariable Long id,
			@RequestBody com.usdt.mall.vo.request.UpdateShopReqVO reqVO,
			HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		shopService.updateShop(id, reqVO, userId);
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
