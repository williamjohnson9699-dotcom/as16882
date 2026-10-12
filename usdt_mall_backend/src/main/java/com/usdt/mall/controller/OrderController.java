package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.service.OrderService;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.CreateOrderReqVO;
import com.usdt.mall.vo.request.ProxyOrderReqVO;
import com.usdt.mall.vo.response.OrderRespVO;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.List;
import java.util.Map;

/**
 * 订单Controller
 */
@RestController
@RequestMapping("/api/v1/order")
public class OrderController {

	@Resource
	private OrderService orderService;

	@Resource
	private JwtUtil jwtUtil;

	/**
	 * 创建订单
	 */
	@PostMapping
	public Result<Long> createOrder(@Valid @RequestBody CreateOrderReqVO reqVO, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		Long orderId = orderService.createOrder(reqVO, userId);
		return Result.successWith(orderId);
	}

	/**
	 * 获取用户订单列表
	 */
	@GetMapping
	public Result<Map<String, Object>> getUserOrders(
			@RequestParam(required = false) Integer status,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "10") Integer pageSize,
			HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		Map<String, Object> result = orderService.getUserOrdersByPage(userId, status, page, pageSize);
		return Result.successWith(result);
	}

	/**
	 * 获取订单详情
	 */
	@GetMapping("/{id}")
	public Result<OrderRespVO> getOrderDetail(@PathVariable Long id, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		OrderRespVO order = orderService.getOrderDetail(id, userId);
		return Result.successWith(order);
	}

	/**
	 * 确认发货
	 */
	@PostMapping("/{id}/ship")
	public Result<?> confirmShipment(@PathVariable Long id, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		orderService.confirmShipment(id, userId);
		return Result.success();
	}

	/**
	 * 确认收货
	 */
	@PostMapping("/{id}/receive")
	public Result<?> confirmReceipt(@PathVariable Long id, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		orderService.confirmReceipt(id, userId);
		return Result.success();
	}

	/**
	 * 更新物流信息
	 */
	@PostMapping("/{id}/update-logistics")
	public Result<?> updateLogistics(@PathVariable Long id, @RequestBody Map<String, String> params, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		String logisticsInfo = params.get("logisticsInfo");
		orderService.updateLogistics(id, userId, logisticsInfo);
		return Result.success();
	}

	/**
	 * 标记为已到货
	 */
	@PostMapping("/{id}/mark-arrived")
	public Result<?> markAsArrived(@PathVariable Long id, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		orderService.markAsArrived(id, userId);
		return Result.success();
	}

	/**
	 * 标记终态订单为已读
	 */
	@PostMapping("/mark-final-read")
	public Result<?> markFinalOrdersAsRead(@RequestBody Map<String, Object> params, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		Integer status = (Integer) params.get("status");
		@SuppressWarnings("unchecked")
		List<Long> orderIds = (List<Long>) params.get("orderIds");
		String viewType = (String) params.get("viewType"); // "buyer" 或 "seller" 或 "service"

		orderService.markFinalOrdersAsRead(userId, status, orderIds, viewType);
		return Result.success();
	}

	/**
	 * 取消订单
	 */
	@PostMapping("/{id}/cancel")
	public Result<?> cancelOrder(@PathVariable Long id, @RequestBody Map<String, String> params, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		String cancelReason = params.get("cancelReason");
		if (cancelReason == null || cancelReason.trim().isEmpty()) {
			return Result.error().newCnMsg("请填写取消原因");
		}
		orderService.cancelOrder(id, userId, cancelReason);
		return Result.success();
	}

	/**
	 * 获取店铺订单列表
	 */
	@GetMapping("/shop/{shopId}")
	public Result<Map<String, Object>> getShopOrders(
			@PathVariable Long shopId,
			@RequestParam(required = false) String keyword,
			@RequestParam(required = false) Integer status,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "10") Integer pageSize,
			HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		if (orderService.isSellerPaymentOverdue(userId)) {
			return Result.of(ResultCode.PERMISSION_DENIED);
		}
		Map<String, Object> result = orderService.getShopOrdersByPage(shopId, keyword, status, page, pageSize);
		return Result.successWith(result);
	}

	/**
	 * 获取当前用户的店铺订单统计
	 */
	@GetMapping("/shop/my/stats")
	public Result<Map<String, Integer>> getMyShopOrderStats(HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		Map<String, Integer> stats = orderService.getMyShopOrderStats(userId);
		return Result.successWith(stats);
	}

	/**
	 * 管理员/客服获取所有订单
	 */
	@GetMapping("/shop/all")
	public Result<Map<String, Object>> getAllShopOrders(
			@RequestParam(required = false) String keyword,
			@RequestParam(required = false) Integer status,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "10") Integer pageSize,
			HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		Map<String, Object> result = orderService.getAllShopOrdersByPage(keyword, status, page, pageSize);
		return Result.successWith(result);
	}

	/**
	 * 获取店铺订单统计
	 */
	@GetMapping("/shop/{shopId}/stats")
	public Result<Map<String, Integer>> getShopOrderStats(@PathVariable Long shopId, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		Map<String, Integer> stats = orderService.getShopOrderStats(shopId);
		return Result.successWith(stats);
	}

	/**
	 * 代下订单
	 */
	@PostMapping("/proxy")
	public Result<Long> createProxyOrder(@Valid @RequestBody ProxyOrderReqVO reqVO, HttpServletRequest request) {
		Long adminUserId = getUserIdFromToken(request);
		if (adminUserId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		Long orderId = orderService.createProxyOrder(reqVO);
		return Result.successWith(orderId);
	}

	/**
	 * 获取待处理订单数量
	 */
	@GetMapping("/pending-count")
	public Result<Integer> getPendingOrderCount(HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.successWith(0);
		}
		int count = orderService.getPendingOrderCount(userId);
		return Result.successWith(count);
	}

	/**
	 * 获取用户订单统计
	 */
	@GetMapping("/stats")
	public Result<Map<String, Integer>> getUserOrderStats(HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		Map<String, Integer> stats = orderService.getUserOrderStats(userId);
		return Result.successWith(stats);
	}

	/**
	 * 卖家支付
	 */
	@PostMapping("/{id}/seller-pay")
	public Result<?> sellerPay(@PathVariable Long id, @RequestBody Map<String, Object> params, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}
		String paymentPassword = (String) params.get("paymentPassword");

		orderService.sellerPay(id, userId, paymentPassword);
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

	/**
	 * 从Token中获取用户角色
	 */
	private String getRoleFromToken(HttpServletRequest request) {
		String token = request.getHeader("Authorization");
		if (token != null && token.startsWith("Bearer ")) {
			token = token.substring(7);
			try {
				return jwtUtil.getRoleFromToken(token);
			} catch (Exception e) {
				return "USER";
			}
		}
		return "USER";
	}
}
