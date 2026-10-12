package com.usdt.mall.service;

import com.usdt.mall.vo.request.CreateOrderReqVO;
import com.usdt.mall.vo.request.ProxyOrderReqVO;
import com.usdt.mall.vo.response.OrderRespVO;

import java.util.List;
import java.util.Map;

/**
 * 订单服务接口
 */
public interface OrderService {

	/**
	 * 创建订单
	 */
	Long createOrder(CreateOrderReqVO reqVO, Long userId);

	/**
	 * 代下订单
	 */
	Long createProxyOrder(ProxyOrderReqVO reqVO);

	/**
	 * 获取用户订单列表
	 */
	List<OrderRespVO> getUserOrders(Long userId);

	/**
	 * 根据状态获取用户订单列表
	 */
	List<OrderRespVO> getUserOrdersByStatus(Long userId, Integer status);

	/**
	 * 获取订单详情
	 */
	OrderRespVO getOrderDetail(Long orderId, Long userId);

	/**
	 * 确认发货
	 */
	void confirmShipment(Long orderId, Long userId);

	/**
	 * 确认收货
	 */
	void confirmReceipt(Long orderId, Long userId);

	/**
	 * 取消订单
	 */
	void cancelOrder(Long orderId, Long userId, String cancelReason);

	/**
	 * 获取店铺订单列表
	 */
	List<OrderRespVO> getShopOrders(Long shopId);

	/**
	 * 根据状态获取店铺订单列表
	 */
	List<OrderRespVO> getShopOrdersByStatus(Long shopId, Integer status);

	/**
	 * 获取店铺订单统计
	 */
	Map<String, Integer> getShopOrderStats(Long shopId);

	/**
	 * 获取当前用户的店铺订单统计
	 */
	Map<String, Integer> getMyShopOrderStats(Long userId);

	/**
	 * 店铺用户是否因接到订单后超过48小时仍未支付货款，而不能打开商家页面。
	 * 只统计该用户自己店铺中状态为待发货、卖家未支付、创建时间早于当前UTC时间48小时的订单。
	 * 管理员、客服、没有店铺的用户返回 false。
	 *
	 * @param userId 当前登录用户ID
	 * @return 存在超时未支付订单时返回 true
	 */
	boolean isSellerPaymentOverdue(Long userId);

	/**
	 * 指定店铺当前是否因超时未支付而不能打开商家页面。
	 * 管理员解封时间及之前创建的订单不计入。
	 *
	 * @param shopId 店铺ID
	 * @return 仍存在超时未支付订单时返回 true
	 */
	boolean isShopPaymentOverdue(Long shopId);

	/**
	 * 管理员解除店铺因超时未支付产生的商家页面限制。
	 * 把解封时间写成当前UTC时间，该时间及之前的未支付订单不再触发限制。
	 *
	 * @param shopId 店铺ID
	 */
	void unlockSellerPaymentLock(Long shopId);

	/**
	 * 获取待处理订单数量
	 */
	int getPendingOrderCount(Long userId);

	/**
	 * 获取用户订单统计
	 */
	Map<String, Integer> getUserOrderStats(Long userId);

	/**
	 * 卖家支付
	 */
	void sellerPay(Long orderId, Long userId, String paymentPassword);

	/**
	 * 管理员/客服分页查询所有订单
	 */
	Map<String, Object> getAllShopOrdersByPage(String keyword, Integer status, Integer page, Integer pageSize);

	/**
	 * 分页查询店铺订单
	 */
	Map<String, Object> getShopOrdersByPage(Long shopId, String keyword, Integer status, Integer page, Integer pageSize);

	/**
	 * 分页查询用户订单
	 */
	Map<String, Object> getUserOrdersByPage(Long userId, Integer status, Integer page, Integer pageSize);

	/**
	 * 更新物流信息
	 */
	void updateLogistics(Long orderId, Long userId, String logisticsInfo);

	/**
	 * 标记为已到货
	 */
	void markAsArrived(Long orderId, Long userId);

	/**
	 * 标记终态订单为已读
	 *
	 * @param userId   用户ID
	 * @param status   订单状态
	 * @param orderIds 订单ID列表
	 * @param viewType 视图类型：buyer-买家视图, seller-卖家视图, service-客服视图
	 */
	void markFinalOrdersAsRead(Long userId, Integer status, List<Long> orderIds, String viewType);
}
