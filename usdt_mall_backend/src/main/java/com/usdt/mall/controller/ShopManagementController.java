package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.service.ShopManagementService;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.ShopQueryReqVO;
import com.usdt.mall.vo.request.ShopUpdateReqVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.Map;

@Tag(name = "店铺管理", description = "店铺管理相关接口")
@RestController
@RequestMapping("/api/v1/shop-management")
public class ShopManagementController {

	@Autowired
	private ShopManagementService shopManagementService;

	@Resource
	private JwtUtil jwtUtil;

	@Operation(summary = "查询店铺列表", description = "分页查询店铺列表")
	@PostMapping("/query")
	public Result<Map<String, Object>> queryShops(@RequestBody ShopQueryReqVO reqVO) {
		Map<String, Object> result = shopManagementService.queryShops(reqVO);
		return Result.successWith(result);
	}

	@Operation(summary = "删除店铺", description = "删除店铺及其关联数据")
	@DeleteMapping("/shops/{shopId}")
	public Result<?> deleteShop(@PathVariable Long shopId) {
		shopManagementService.deleteShop(shopId);
		return Result.success();
	}

	@Operation(summary = "更新店铺状态", description = "更新店铺状态（开启/关闭）")
	@PutMapping("/shops/{shopId}/status")
	public Result<?> updateShopStatus(@PathVariable Long shopId, @RequestBody Map<String, String> params) {
		String status = params.get("status");
		Integer statusValue = "active".equals(status) ? 1 : 0;
		shopManagementService.updateShopStatus(shopId, statusValue);
		return Result.success();
	}

	@Operation(summary = "更新店铺信息", description = "管理员更新店铺信息")
	@PutMapping("/shops/{shopId}")
	public Result<?> updateShop(@PathVariable Long shopId, @RequestBody ShopUpdateReqVO reqVO) {
		shopManagementService.updateShop(shopId, reqVO);
		return Result.success();
	}

	/**
	 * 管理员解除店铺因超时未支付产生的商家页面限制。
	 *
	 * @param shopId 店铺ID
	 * @param request 当前请求，用于读取登录用户
	 * @return 解封成功
	 */
	@Operation(summary = "解除店铺支付超时限制", description = "管理员解封因超过48小时未支付货款而关闭的商家页面")
	@PostMapping("/shops/{shopId}/unlock-payment")
	public Result<?> unlockPaymentLock(@PathVariable Long shopId, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		shopManagementService.unlockPaymentLock(shopId, userId);
		return Result.success();
	}

	/**
	 * 从请求头的 Bearer Token 中解析用户ID。
	 *
	 * @param request 当前请求
	 * @return 用户ID，未登录或令牌无效时返回 null
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
