package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.*;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.*;
import com.usdt.mall.service.OrderService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.vo.request.CreateOrderReqVO;
import com.usdt.mall.vo.request.ProxyOrderReqVO;
import com.usdt.mall.vo.response.OrderInfoRespVO;
import com.usdt.mall.vo.response.OrderItemRespVO;
import com.usdt.mall.vo.response.OrderRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 订单服务实现�?
 */
@Slf4j
@Service
public class OrderServiceImpl implements OrderService {

	/** 商家接到订单后必须支付货款的时限，超过后关闭商家页面。 */
	private static final int SELLER_PAY_DEADLINE_HOURS = 48;

	@Resource
	private OrderMapper orderMapper;

	@Resource
	private OrderItemMapper orderItemMapper;

	@Resource
	private CartMapper cartMapper;

	@Resource
	private AddressMapper addressMapper;

	@Resource
	private ProductMapper productMapper;

	@Resource
	private ShopProductMapper shopProductMapper;

	@Resource
	private UserMapper userMapper;

	@Resource
	private ShopMapper shopMapper;

	@Resource
	private PasswordEncoder passwordEncoder;

	@Resource
	private com.usdt.mall.service.ShopStatisticsService shopStatisticsService;

	@Resource
	private com.usdt.mall.service.SystemConfigService systemConfigService;

	@Resource
	private RechargeWithdrawRecordMapper rechargeWithdrawRecordMapper;

	@Resource
	private OrderInfoMapper orderInfoMapper;

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long createOrder(CreateOrderReqVO reqVO, Long userId) {
		// 0. 验证支付密码
		User user = userMapper.selectById(userId);
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		// 检查用户是否设置了支付密码
		if (user.getPaymentPassword() == null || user.getPaymentPassword().trim().isEmpty()) {
			throw new CustomException(ResultCode.PAYMENT_PASSWORD_NOT_SET);
		}

		// 验证支付密码是否正确
		if (!passwordEncoder.matches(reqVO.getPaymentPassword(), user.getPaymentPassword())) {
			throw new CustomException(ResultCode.INVALID_PAYMENT_PASSWORD);
		}

		// 1. 查询购物车商�?
		List<Cart> cartItems = cartMapper.selectBatchIds(reqVO.getCartIds());
		if (cartItems.isEmpty()) {
			throw new CustomException(ResultCode.CART_ITEMS_NOT_FOUND);
		}

		// 验证购物车商品是否属于当前用�?
		boolean allBelongToUser = cartItems.stream()
				.allMatch(cart -> cart.getUserId().equals(userId));
		if (!allBelongToUser) {
			throw new CustomException(ResultCode.CART_ITEMS_NOT_BELONG_TO_USER);
		}

		// 2. 查询收货地址
		Address address = addressMapper.selectById(reqVO.getAddressId());
		if (address == null || !address.getUserId().equals(userId)) {
			throw new CustomException(ResultCode.ADDRESS_NOT_FOUND_OR_NO_ACCESS);
		}

		// 3. 按店铺分�?
		Map<Long, List<Cart>> shopCartMap = new HashMap<>();
		for (Cart cart : cartItems) {
			shopCartMap.computeIfAbsent(cart.getShopId(), k -> new ArrayList<>()).add(cart);
		}

		// 4. 计算总金额并验证库存
		BigDecimal grandTotal = BigDecimal.ZERO;
		for (Cart cart : cartItems) {
			Product product = productMapper.selectById(cart.getProductId());
			if (product == null) {
				throw new CustomException(ResultCode.PRODUCT_NOT_FOUND_WITH_ID);
			}
			if (product.getStock() < cart.getQuantity()) {
				throw new CustomException(ResultCode.PRODUCT_STOCK_INSUFFICIENT);
			}
			grandTotal = grandTotal.add(product.getPrice().multiply(new BigDecimal(cart.getQuantity())));
		}

		// 5. 扣减用户余额
		if (user.getBalance().compareTo(grandTotal) < 0) {
			throw new CustomException(ResultCode.INSUFFICIENT_BALANCE);
		}
		user.setBalance(user.getBalance().subtract(grandTotal));
		userMapper.updateById(user);

		// 6. 按店铺创建订�?
		Long firstOrderId = null;
		for (Map.Entry<Long, List<Cart>> entry : shopCartMap.entrySet()) {
			Long shopId = entry.getKey();
			List<Cart> shopCarts = entry.getValue();

			BigDecimal orderTotal = BigDecimal.ZERO;
			List<OrderItem> orderItems = new ArrayList<>();

			for (Cart cart : shopCarts) {
				Product product = productMapper.selectById(cart.getProductId());
				BigDecimal subtotal = product.getPrice().multiply(new BigDecimal(cart.getQuantity()));
				orderTotal = orderTotal.add(subtotal);

				OrderItem orderItem = new OrderItem();
				orderItem.setProductId(product.getId());
				orderItem.setProductName(product.getName());
				orderItem.setProductImage(product.getMainImage());
				orderItem.setPrice(product.getPrice());
				orderItem.setQuantity(cart.getQuantity());
				orderItem.setSubtotal(subtotal);
				orderItem.setCreateTime(DateTimeUtil.nowUtc());
				orderItems.add(orderItem);
			}

			Integer profitRate = systemConfigService.getProfitRate();
			BigDecimal rate = new BigDecimal(profitRate).divide(new BigDecimal(100));
			BigDecimal profit = orderTotal.multiply(rate);
			BigDecimal cost = orderTotal.subtract(profit);

			Order order = new Order();
			order.setOrderNo(generateOrderNo());
			order.setUserId(userId);
			order.setShopId(shopId);
			order.setAddressId(address.getId());
			order.setTotalAmount(orderTotal);
			order.setOrderType(1);
			order.setStatus(0);
			order.setRemark(reqVO.getRemark());
			order.setProfitRate(new BigDecimal(profitRate));
			order.setCost(cost);
			order.setProfit(profit);
			order.setCreateTime(DateTimeUtil.nowUtc());
			order.setUpdateTime(DateTimeUtil.nowUtc());
			orderMapper.insert(order);

			if (firstOrderId == null) {
				firstOrderId = order.getId();
			}

			for (OrderItem orderItem : orderItems) {
				orderItem.setOrderId(order.getId());
				orderItemMapper.insert(orderItem);
			}

			shopStatisticsService.updateStatistics(shopId, orderTotal);

			// 记录订单信息
			addOrderInfo(order.getId(), "STATUS_CHANGE", "订单已创建", userId);

			// 创建买家结算记录
			RechargeWithdrawRecord settlementRecord = new RechargeWithdrawRecord();
			settlementRecord.setUserId(userId);
			settlementRecord.setOrderNo(order.getOrderNo());
			settlementRecord.setType(5);
			settlementRecord.setAmount(orderTotal);
			settlementRecord.setStatus(1);
			settlementRecord.setIsRead(0);
			settlementRecord.setRelatedOrderNo(order.getOrderNo());
			settlementRecord.setCreateTime(DateTimeUtil.nowUtc());
			settlementRecord.setUpdateTime(DateTimeUtil.nowUtc());
			rechargeWithdrawRecordMapper.insert(settlementRecord);

			// 向sysaccount账户余额中增加订单总额
			User sysAccount = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, "sysaccount"));
			if (sysAccount != null) {
				sysAccount.setBalance(sysAccount.getBalance().add(orderTotal));
				userMapper.updateById(sysAccount);
			}
		}

		// 7. 删除购物车商�?
		cartMapper.deleteBatchIds(reqVO.getCartIds());

		// 8. 扣减库存并增加销�?
		for (Cart cart : cartItems) {
			Product product = productMapper.selectById(cart.getProductId());
			product.setStock(product.getStock() - cart.getQuantity());
			product.setSales(product.getSales() + cart.getQuantity());
			productMapper.updateById(product);
		}

		return firstOrderId;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long createProxyOrder(ProxyOrderReqVO reqVO) {
		// 0. 验证支付密码
		User user = userMapper.selectById(reqVO.getUserId());
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		if (user.getPaymentPassword() == null || user.getPaymentPassword().trim().isEmpty()) {
			throw new CustomException(ResultCode.PAYMENT_PASSWORD_NOT_SET);
		}

		if (!passwordEncoder.matches(reqVO.getPaymentPassword(), user.getPaymentPassword())) {
			throw new CustomException(ResultCode.INVALID_PAYMENT_PASSWORD);
		}

		// 1. 查询收货地址
		Address address = addressMapper.selectById(reqVO.getAddressId());
		if (address == null || !address.getUserId().equals(reqVO.getUserId())) {
			throw new CustomException(ResultCode.ADDRESS_NOT_FOUND_OR_NO_ACCESS);
		}

		// 2. 按店铺分组商�?
		Map<Long, List<ProxyOrderReqVO.ProxyOrderProduct>> shopProductMap = new HashMap<>();
		for (ProxyOrderReqVO.ProxyOrderProduct productReq : reqVO.getProducts()) {
			Product product = productMapper.selectById(productReq.getProductId());
			if (product == null) {
				throw new CustomException(ResultCode.PRODUCT_NOT_FOUND_WITH_ID);
			}
			if (product.getStock() < productReq.getQuantity()) {
				throw new CustomException(ResultCode.PRODUCT_STOCK_INSUFFICIENT);
			}

			LambdaQueryWrapper<ShopProduct> shopProductWrapper = new LambdaQueryWrapper<>();
			shopProductWrapper.eq(ShopProduct::getProductId, product.getId());
			ShopProduct shopProduct = shopProductMapper.selectOne(shopProductWrapper);
			if (shopProduct == null) {
				throw new CustomException(ResultCode.PRODUCT_NOT_FOUND_WITH_ID);
			}

			shopProductMap.computeIfAbsent(shopProduct.getShopId(), k -> new ArrayList<>()).add(productReq);
		}

		// 3. 计算总金�?
		BigDecimal grandTotal = BigDecimal.ZERO;
		for (ProxyOrderReqVO.ProxyOrderProduct productReq : reqVO.getProducts()) {
			Product product = productMapper.selectById(productReq.getProductId());
			grandTotal = grandTotal.add(product.getPrice().multiply(new BigDecimal(productReq.getQuantity())));
		}

		// 4. 扣减用户余额
		if (user.getBalance().compareTo(grandTotal) < 0) {
			throw new CustomException(ResultCode.INSUFFICIENT_BALANCE);
		}
		user.setBalance(user.getBalance().subtract(grandTotal));
		userMapper.updateById(user);

		// 5. 按店铺创建订�?
		Long firstOrderId = null;
		for (Map.Entry<Long, List<ProxyOrderReqVO.ProxyOrderProduct>> entry : shopProductMap.entrySet()) {
			Long shopId = entry.getKey();
			List<ProxyOrderReqVO.ProxyOrderProduct> shopProducts = entry.getValue();

			BigDecimal orderTotal = BigDecimal.ZERO;
			List<OrderItem> orderItems = new ArrayList<>();

			for (ProxyOrderReqVO.ProxyOrderProduct productReq : shopProducts) {
				Product product = productMapper.selectById(productReq.getProductId());
				BigDecimal subtotal = product.getPrice().multiply(new BigDecimal(productReq.getQuantity()));
				orderTotal = orderTotal.add(subtotal);

				OrderItem orderItem = new OrderItem();
				orderItem.setProductId(product.getId());
				orderItem.setProductName(product.getName());
				orderItem.setProductImage(product.getMainImage());
				orderItem.setPrice(product.getPrice());
				orderItem.setQuantity(productReq.getQuantity());
				orderItem.setSubtotal(subtotal);
				orderItem.setCreateTime(DateTimeUtil.nowUtc());
				orderItems.add(orderItem);
			}

			Integer profitRate = systemConfigService.getProfitRate();
			BigDecimal rate = new BigDecimal(profitRate).divide(new BigDecimal(100));
			BigDecimal profit = orderTotal.multiply(rate);
			BigDecimal cost = orderTotal.subtract(profit);

			Order order = new Order();
			order.setOrderNo(generateOrderNo());
			order.setUserId(reqVO.getUserId());
			order.setShopId(shopId);
			order.setAddressId(address.getId());
			order.setTotalAmount(orderTotal);
			order.setOrderType(1);
			order.setStatus(0);
			order.setRemark(reqVO.getRemark());
			order.setProfitRate(new BigDecimal(profitRate));
			order.setCost(cost);
			order.setProfit(profit);
			order.setCreateTime(DateTimeUtil.nowUtc());
			order.setUpdateTime(DateTimeUtil.nowUtc());
			orderMapper.insert(order);

			if (firstOrderId == null) {
				firstOrderId = order.getId();
			}

			for (OrderItem orderItem : orderItems) {
				orderItem.setOrderId(order.getId());
				orderItemMapper.insert(orderItem);
			}

			shopStatisticsService.updateStatistics(shopId, orderTotal);

			// 记录订单信息
			addOrderInfo(order.getId(), "STATUS_CHANGE", "订单已创建", reqVO.getUserId());

			// 创建买家结算记录
			RechargeWithdrawRecord settlementRecord = new RechargeWithdrawRecord();
			settlementRecord.setUserId(reqVO.getUserId());
			settlementRecord.setOrderNo(order.getOrderNo());
			settlementRecord.setType(5);
			settlementRecord.setAmount(orderTotal);
			settlementRecord.setStatus(1);
			settlementRecord.setIsRead(0);
			settlementRecord.setRelatedOrderNo(order.getOrderNo());
			settlementRecord.setCreateTime(DateTimeUtil.nowUtc());
			settlementRecord.setUpdateTime(DateTimeUtil.nowUtc());
			rechargeWithdrawRecordMapper.insert(settlementRecord);

			// 向sysaccount账户余额中增加订单总额
			User sysAccount = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, "sysaccount"));
			if (sysAccount != null) {
				sysAccount.setBalance(sysAccount.getBalance().add(orderTotal));
				userMapper.updateById(sysAccount);
			}
		}

		// 6. 扣减库存并增加销�?
		for (ProxyOrderReqVO.ProxyOrderProduct productReq : reqVO.getProducts()) {
			Product product = productMapper.selectById(productReq.getProductId());
			product.setStock(product.getStock() - productReq.getQuantity());
			product.setSales(product.getSales() + productReq.getQuantity());
			productMapper.updateById(product);
		}

		return firstOrderId;
	}

	@Override
	public List<OrderRespVO> getUserOrders(Long userId) {
		LambdaQueryWrapper<Order> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(Order::getUserId, userId);
		queryWrapper.orderByDesc(Order::getCreateTime);

		List<Order> orders = orderMapper.selectList(queryWrapper);

		return orders.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());
	}

	@Override
	public List<OrderRespVO> getUserOrdersByStatus(Long userId, Integer status) {
		LambdaQueryWrapper<Order> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(Order::getUserId, userId);
		if (status != null) {
			queryWrapper.eq(Order::getStatus, status);
		}
		queryWrapper.orderByDesc(Order::getCreateTime);

		List<Order> orders = orderMapper.selectList(queryWrapper);

		return orders.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());
	}

	@Override
	public OrderRespVO getOrderDetail(Long orderId, Long userId) {
		Order order = orderMapper.selectById(orderId);
		if (order == null || !order.getUserId().equals(userId)) {
			throw new CustomException(ResultCode.ORDER_NOT_FOUND_OR_NO_ACCESS);
		}

		return convertToRespVO(order);
	}

	@Override
	public void confirmShipment(Long orderId, Long userId) {
		Order order = orderMapper.selectById(orderId);
		if (order == null) {
			throw new CustomException(ResultCode.ORDER_NOT_FOUND_OR_NO_ACCESS);
		}

		// 验证权限：只有管理员/客服可以确认发货
		User user = userMapper.selectById(userId);
		boolean isAdminOrService = user != null && ("ADMIN".equalsIgnoreCase(user.getRole()) || "SERVICE".equalsIgnoreCase(user.getRole()));

		if (!isAdminOrService) {
			throw new CustomException(ResultCode.PERMISSION_DENIED);
		}

		if (order.getStatus() != 0) {
			throw new CustomException(ResultCode.ORDER_STATUS_INVALID_FOR_SHIPMENT);
		}

		order.setStatus(1);
		order.setUpdateTime(DateTimeUtil.nowUtc());
		orderMapper.updateById(order);

		// 记录订单信息
		addOrderInfo(orderId, "STATUS_CHANGE", "订单已发货", userId);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void confirmReceipt(Long orderId, Long userId) {
		Order order = orderMapper.selectById(orderId);
		if (order == null || !order.getUserId().equals(userId)) {
			throw new CustomException(ResultCode.ORDER_NOT_FOUND_OR_NO_ACCESS);
		}

		if (order.getStatus() != 1) {
			throw new CustomException(ResultCode.ORDER_STATUS_INVALID_FOR_RECEIPT);
		}

		// 检查是否已到货
		if (order.getIsArrived() == null || !order.getIsArrived()) {
			throw new CustomException(ResultCode.ORDER_NOT_ARRIVED);
		}

		order.setStatus(2); // 2-已完�?
		order.setPlatformRebate(true);
		order.setPlatformRebateTime(DateTimeUtil.nowUtc());
		order.setBuyerFinalRead(false); // 买家未读
		order.setSellerFinalRead(false); // 卖家未读
		order.setServiceFinalRead(false); // 客服未读
		order.setUpdateTime(DateTimeUtil.nowUtc());
		orderMapper.updateById(order);

		// 记录订单信息
		addOrderInfo(orderId, "STATUS_CHANGE", "订单已完成", userId);

		// 从sysaccount账户余额中减去订单总额
		User sysAccount = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, "sysaccount"));
		if (sysAccount == null) {
			throw new CustomException(ResultCode.SYSTEM_ACCOUNT_NOT_FOUND);
		}
		if (sysAccount.getBalance().compareTo(order.getTotalAmount()) < 0) {
			throw new CustomException(ResultCode.SYSTEM_ACCOUNT_INSUFFICIENT_BALANCE);
		}
		sysAccount.setBalance(sysAccount.getBalance().subtract(order.getTotalAmount()));
		userMapper.updateById(sysAccount);

		// 查询店铺信息，获取卖家用户ID
		Shop shop = shopMapper.selectById(order.getShopId());
		if (shop == null) {
			throw new CustomException(ResultCode.SHOP_NOT_FOUND);
		}

		// 创建平台回馈记录（金额为订单总额，记录给店铺用户�?
		RechargeWithdrawRecord rebateRecord = new RechargeWithdrawRecord();
		rebateRecord.setUserId(shop.getUserId());
		rebateRecord.setOrderNo(order.getOrderNo());
		rebateRecord.setType(4);
		rebateRecord.setAmount(order.getTotalAmount());
		rebateRecord.setStatus(1);
		rebateRecord.setIsRead(0);
		rebateRecord.setRelatedOrderNo(order.getOrderNo());
		rebateRecord.setCreateTime(DateTimeUtil.nowUtc());
		rebateRecord.setUpdateTime(DateTimeUtil.nowUtc());
		rechargeWithdrawRecordMapper.insert(rebateRecord);

		// 向卖家（店铺用户）余额中增加订单总额
		User seller = userMapper.selectById(shop.getUserId());
		if (seller != null) {
			seller.setBalance(seller.getBalance().add(order.getTotalAmount()));
			userMapper.updateById(seller);
		}
	}

	@Override
	public void cancelOrder(Long orderId, Long userId, String cancelReason) {
		Order order = orderMapper.selectById(orderId);
		if (order == null || !order.getUserId().equals(userId)) {
			throw new CustomException(ResultCode.ORDER_NOT_FOUND_OR_NO_ACCESS);
		}

		if (order.getStatus() == 2 || order.getStatus() == 3) {
			throw new CustomException(ResultCode.ORDER_CANNOT_BE_CANCELLED);
		}

		order.setStatus(3); // 3-已取�?
		order.setCancelReason(cancelReason);
		order.setBuyerFinalRead(false); // 买家未读
		order.setSellerFinalRead(false); // 卖家未读
		order.setServiceFinalRead(false); // 客服未读
		order.setUpdateTime(DateTimeUtil.nowUtc());
		orderMapper.updateById(order);

		// 记录订单信息
		addOrderInfo(orderId, "STATUS_CHANGE", "订单已取消，原因：" + cancelReason, userId);

		// 验证并从sysaccount余额中扣减订单总额
		User sysAccount = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, "sysaccount"));
		if (sysAccount == null) {
			throw new CustomException(ResultCode.SYSTEM_ACCOUNT_NOT_FOUND);
		}

		// 计算需要扣减的总额
		BigDecimal totalDeduction = order.getTotalAmount();
		if (order.getSellerPaid() != null && order.getSellerPaid()) {
			totalDeduction = totalDeduction.add(order.getCost());
		}

		// 验证余额是否足够
		if (sysAccount.getBalance().compareTo(totalDeduction) < 0) {
			throw new CustomException(ResultCode.SYSTEM_ACCOUNT_INSUFFICIENT_BALANCE);
		}

		// 扣减订单总额
		sysAccount.setBalance(sysAccount.getBalance().subtract(order.getTotalAmount()));
		userMapper.updateById(sysAccount);

		// 退还买家余�?
		User user = userMapper.selectById(order.getUserId());
		if (user != null) {
			user.setBalance(user.getBalance().add(order.getTotalAmount()));
			userMapper.updateById(user);
		}

		// 如果卖家已支�?退还卖家成�?
		if (order.getSellerPaid() != null && order.getSellerPaid()) {
			// 查询卖家
			LambdaQueryWrapper<Shop> shopWrapper = new LambdaQueryWrapper<>();
			shopWrapper.eq(Shop::getId, order.getShopId());
			Shop shop = shopMapper.selectOne(shopWrapper);
			if (shop != null) {
				User seller = userMapper.selectById(shop.getUserId());
				if (seller != null) {
					seller.setBalance(seller.getBalance().add(order.getCost()));
					userMapper.updateById(seller);
				}
			}
			// 从sysaccount余额中扣减订单成�?
			if (sysAccount != null) {
				sysAccount.setBalance(sysAccount.getBalance().subtract(order.getCost()));
				userMapper.updateById(sysAccount);
			}
		}

		// 恢复库存
		LambdaQueryWrapper<OrderItem> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(OrderItem::getOrderId, orderId);
		List<OrderItem> orderItems = orderItemMapper.selectList(queryWrapper);

		for (OrderItem orderItem : orderItems) {
			Product product = productMapper.selectById(orderItem.getProductId());
			if (product != null) {
				product.setStock(product.getStock() + orderItem.getQuantity());
				productMapper.updateById(product);
			}
		}
	}

	/**
	 * 生成订单�?
	 */
	private String generateOrderNo() {
		String timestamp = DateTimeUtil.nowUtc().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
		String random = String.valueOf((int) (Math.random() * 10000));
		return timestamp + String.format("%04d", Integer.parseInt(random));
	}

	/**
	 * 转换为响应VO
	 */
	private OrderRespVO convertToRespVO(Order order) {
		OrderRespVO respVO = new OrderRespVO();
		BeanUtils.copyProperties(order, respVO);

		// 查询买家信息
		User buyer = userMapper.selectById(order.getUserId());
		if (buyer != null) {
			respVO.setBuyerUsername(buyer.getUsername());
			respVO.setBuyerNickname(buyer.getNickname());
		}

		// 查询卖家信息
		Shop shop = shopMapper.selectById(order.getShopId());
		if (shop != null) {
			respVO.setShopName(shop.getName());
			User seller = userMapper.selectById(shop.getUserId());
			if (seller != null) {
				respVO.setShopUsername(seller.getUsername());
				respVO.setShopNickname(seller.getNickname());
			}
		}

		// 查询地址信息
		Address address = addressMapper.selectById(order.getAddressId());
		if (address != null) {
			respVO.setReceiverName(address.getName());
			respVO.setReceiverPhone(address.getPhone());
			respVO.setReceiverAddress(address.getAddress());
		}

		// 查询订单明细
		LambdaQueryWrapper<OrderItem> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(OrderItem::getOrderId, order.getId());
		List<OrderItem> orderItems = orderItemMapper.selectList(queryWrapper);

		List<OrderItemRespVO> itemRespVOs = orderItems.stream()
				.map(this::convertToItemRespVO)
				.collect(Collectors.toList());
		respVO.setItems(itemRespVOs);

		// 查询订单信息记录
		LambdaQueryWrapper<OrderInfo> infoWrapper = new LambdaQueryWrapper<>();
		infoWrapper.eq(OrderInfo::getOrderId, order.getId());
		infoWrapper.orderByDesc(OrderInfo::getCreateTime);
		List<OrderInfo> orderInfos = orderInfoMapper.selectList(infoWrapper);

		log.info("查询订单信息 - orderId: {}, 查询结果数量: {}", order.getId(), orderInfos.size());
		if (!orderInfos.isEmpty()) {
			log.info("第一条记�? {}", orderInfos.get(0));
		}

		List<OrderInfoRespVO> infoRespVOs = orderInfos.stream()
				.map(this::convertToInfoRespVO)
				.collect(Collectors.toList());
		respVO.setOrderInfos(infoRespVOs);

		return respVO;
	}

	/**
	 * 转换订单明细为响应VO
	 */
	private OrderItemRespVO convertToItemRespVO(OrderItem orderItem) {
		OrderItemRespVO respVO = new OrderItemRespVO();
		BeanUtils.copyProperties(orderItem, respVO);
		return respVO;
	}

	/**
	 * 转换订单信息为响应VO
	 */
	private OrderInfoRespVO convertToInfoRespVO(OrderInfo orderInfo) {
		OrderInfoRespVO respVO = new OrderInfoRespVO();
		BeanUtils.copyProperties(orderInfo, respVO);
		return respVO;
	}

	/**
	 * 记录订单信息
	 */
	private void addOrderInfo(Long orderId, String infoType, String content, Long operatorId) {
		User operator = operatorId != null ? userMapper.selectById(operatorId) : null;
		String operatorName = operator != null ? (operator.getNickname() != null ? operator.getNickname() : operator.getUsername()) : "系统";

		OrderInfo orderInfo = new OrderInfo();
		orderInfo.setOrderId(orderId);
		orderInfo.setInfoType(infoType);
		orderInfo.setContent(content);
		orderInfo.setOperatorId(operatorId);
		orderInfo.setOperatorName(operatorName);
		orderInfo.setCreateTime(DateTimeUtil.nowUtc());
		orderInfoMapper.insert(orderInfo);
	}

	@Override
	public List<OrderRespVO> getShopOrders(Long shopId) {
		LambdaQueryWrapper<Order> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(Order::getShopId, shopId);
		queryWrapper.orderByDesc(Order::getCreateTime);

		List<Order> orders = orderMapper.selectList(queryWrapper);

		return orders.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());
	}

	@Override
	public List<OrderRespVO> getShopOrdersByStatus(Long shopId, Integer status) {
		LambdaQueryWrapper<Order> queryWrapper = new LambdaQueryWrapper<>();
		// 如果shopId不为null，则按店铺过滤；否则查询所有订单（管理�?客服�?
		if (shopId != null) {
			queryWrapper.eq(Order::getShopId, shopId);
		}
		if (status != null) {
			queryWrapper.eq(Order::getStatus, status);
		}
		queryWrapper.orderByDesc(Order::getCreateTime);

		List<Order> orders = orderMapper.selectList(queryWrapper);

		return orders.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());
	}

	@Override
	public Map<String, Integer> getShopOrderStats(Long shopId) {
		Map<String, Integer> stats = new HashMap<>();
		LambdaQueryWrapper<Order> wrapper = new LambdaQueryWrapper<>();
		// 如果shopId不为null，则按店铺过滤；否则统计所有订单（管理�?客服�?
		if (shopId != null) {
			wrapper.eq(Order::getShopId, shopId);
		}
		stats.put("all", orderMapper.selectCount(wrapper).intValue());

		wrapper.eq(Order::getStatus, 0);
		stats.put("pendingShipment", orderMapper.selectCount(wrapper).intValue());

		wrapper.clear();
		if (shopId != null) {
			wrapper.eq(Order::getShopId, shopId);
		}
		wrapper.eq(Order::getStatus, 1);
		stats.put("pendingReceipt", orderMapper.selectCount(wrapper).intValue());

		wrapper.clear();
		if (shopId != null) {
			wrapper.eq(Order::getShopId, shopId);
		}
		wrapper.eq(Order::getStatus, 2);
		// 如果是店铺用户，统计卖家未读的已完成订单；如果是管理�?客服，统计客服未读的已完成订�?
		if (shopId != null) {
			wrapper.eq(Order::getSellerFinalRead, false);
		} else {
			wrapper.eq(Order::getServiceFinalRead, false);
		}
		stats.put("completed", orderMapper.selectCount(wrapper).intValue());

		wrapper.clear();
		if (shopId != null) {
			wrapper.eq(Order::getShopId, shopId);
		}
		wrapper.eq(Order::getStatus, 3);
		// 如果是店铺用户，统计卖家未读的已取消订单；如果是管理�?客服，统计客服未读的已取消订�?
		if (shopId != null) {
			wrapper.eq(Order::getSellerFinalRead, false);
		} else {
			wrapper.eq(Order::getServiceFinalRead, false);
		}
		stats.put("cancelled", orderMapper.selectCount(wrapper).intValue());
		putMenuBadge(stats);

		return stats;
	}

	@Override
	public Map<String, Integer> getMyShopOrderStats(Long userId) {
		User user = userMapper.selectById(userId);
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		// 管理员和客服查看所有店铺订�?
		if ("ADMIN".equals(user.getRole()) || "SERVICE".equals(user.getRole())) {
			Map<String, Integer> stats = getShopOrderStats(null);
			stats.put("paymentOverdue", 0);
			return stats;
		}

		// 店铺用户查看自己店铺的订�?
		LambdaQueryWrapper<Shop> shopWrapper = new LambdaQueryWrapper<>();
		shopWrapper.eq(Shop::getUserId, userId);
		Shop shop = shopMapper.selectOne(shopWrapper);
		if (shop == null) {
			Map<String, Integer> stats = getShopOrderStats(null);
			stats.put("paymentOverdue", 0);
			return stats;
		}

		Map<String, Integer> stats = getShopOrderStats(shop.getId());
		stats.put("paymentOverdue", hasUnpaidOrderPastDeadline(shop) ? 1 : 0);
		return stats;
	}

	/**
	 * 判断店铺用户是否存在超过48小时仍未支付货款的待发货订单。
	 *
	 * @param userId 当前登录用户ID
	 * @return 店铺角色且存在超时未支付订单时返回 true
	 */
	@Override
	public boolean isSellerPaymentOverdue(Long userId) {
		User user = userMapper.selectById(userId);
		if (user == null || user.getRole() == null || !"SHOP".equalsIgnoreCase(user.getRole())) {
			return false;
		}
		LambdaQueryWrapper<Shop> shopWrapper = new LambdaQueryWrapper<>();
		shopWrapper.eq(Shop::getUserId, userId);
		Shop shop = shopMapper.selectOne(shopWrapper);
		if (shop == null) {
			return false;
		}
		return hasUnpaidOrderPastDeadline(shop);
	}

	/**
	 * 判断指定店铺是否仍有超过48小时未支付、且晚于管理员解封时间的待发货订单。
	 *
	 * @param shopId 店铺ID
	 * @return 存在这类订单时返回 true
	 */
	@Override
	public boolean isShopPaymentOverdue(Long shopId) {
		if (shopId == null) {
			return false;
		}
		Shop shop = shopMapper.selectById(shopId);
		if (shop == null) {
			return false;
		}
		return hasUnpaidOrderPastDeadline(shop);
	}

	/**
	 * 把店铺的解封时间写成当前UTC时间，使此前的超时未支付订单不再关闭商家页面。
	 *
	 * @param shopId 店铺ID
	 */
	@Override
	public void unlockSellerPaymentLock(Long shopId) {
		Shop shop = shopMapper.selectById(shopId);
		if (shop == null) {
			throw new CustomException(ResultCode.SHOP_NOT_EXISTS);
		}
		LocalDateTime now = DateTimeUtil.nowUtc();
		shop.setPaymentLockWaivedBefore(now);
		shop.setUpdateTime(now);
		shopMapper.updateById(shop);
	}

	/**
	 * 统计指定店铺是否有待发货、卖家未支付、创建时间已超过48小时，
	 * 且晚于管理员解封时间的订单。已取消、已完成、卖家已支付的订单不计入。
	 *
	 * @param shop 店铺，读取店铺ID和解封时间
	 * @return 存在超时未支付订单时返回 true
	 */
	private boolean hasUnpaidOrderPastDeadline(Shop shop) {
		LocalDateTime deadline = DateTimeUtil.nowUtc().minusHours(SELLER_PAY_DEADLINE_HOURS);
		LambdaQueryWrapper<Order> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Order::getShopId, shop.getId());
		wrapper.eq(Order::getStatus, 0);
		wrapper.and(item -> item.isNull(Order::getSellerPaid).or().eq(Order::getSellerPaid, false));
		wrapper.le(Order::getCreateTime, deadline);
		if (shop.getPaymentLockWaivedBefore() != null) {
			wrapper.gt(Order::getCreateTime, shop.getPaymentLockWaivedBefore());
		}
		Long count = orderMapper.selectCount(wrapper);
		return count != null && count > 0;
	}

	@Override
	public int getPendingOrderCount(Long userId) {
		LambdaQueryWrapper<Order> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(Order::getUserId, userId);
		queryWrapper.in(Order::getStatus, 0, 1);
		return orderMapper.selectCount(queryWrapper).intValue();
	}

	@Override
	public Map<String, Integer> getUserOrderStats(Long userId) {
		Map<String, Integer> stats = new HashMap<>();
		LambdaQueryWrapper<Order> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Order::getUserId, userId);

		wrapper.eq(Order::getStatus, 0);
		stats.put("pendingShipment", orderMapper.selectCount(wrapper).intValue());

		wrapper.clear();
		wrapper.eq(Order::getUserId, userId).eq(Order::getStatus, 1);
		stats.put("pendingReceipt", orderMapper.selectCount(wrapper).intValue());

		wrapper.clear();
		wrapper.eq(Order::getUserId, userId).eq(Order::getStatus, 2).eq(Order::getBuyerFinalRead, false);
		stats.put("completed", orderMapper.selectCount(wrapper).intValue());

		wrapper.clear();
		wrapper.eq(Order::getUserId, userId).eq(Order::getStatus, 3).eq(Order::getBuyerFinalRead, false);
		stats.put("cancelled", orderMapper.selectCount(wrapper).intValue());
		putMenuBadge(stats);

		return stats;
	}

	private void putMenuBadge(Map<String, Integer> stats) {
		int pendingShipment = stats.getOrDefault("pendingShipment", 0);
		int pendingReceipt = stats.getOrDefault("pendingReceipt", 0);
		int completed = stats.getOrDefault("completed", 0);
		int cancelled = stats.getOrDefault("cancelled", 0);
		stats.put("menuBadge", pendingShipment + pendingReceipt + completed + cancelled);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void sellerPay(Long orderId, Long userId, String paymentPassword) {
		Order order = orderMapper.selectById(orderId);
		if (order == null) {
			throw new CustomException(ResultCode.ORDER_NOT_FOUND_OR_NO_ACCESS);
		}

		// 验证是否是店铺用�?
		LambdaQueryWrapper<Shop> shopWrapper = new LambdaQueryWrapper<>();
		shopWrapper.eq(Shop::getUserId, userId);
		Shop shop = shopMapper.selectOne(shopWrapper);
		if (shop == null || !order.getShopId().equals(shop.getId())) {
			throw new CustomException(ResultCode.ORDER_NOT_FOUND_OR_NO_ACCESS);
		}

		// 验证支付密码
		User seller = userMapper.selectById(userId);
		if (!passwordEncoder.matches(paymentPassword, seller.getPaymentPassword())) {
			throw new CustomException(ResultCode.INVALID_PAYMENT_PASSWORD);
		}

		// 使用订单成本作为支付金额
		BigDecimal payAmount = order.getCost();

		// 验证卖家余额是否足够
		if (seller.getBalance().compareTo(payAmount) < 0) {
			throw new CustomException(ResultCode.INSUFFICIENT_BALANCE);
		}

		// 扣减卖家余额
		seller.setBalance(seller.getBalance().subtract(payAmount));
		userMapper.updateById(seller);

		// 更新订单支付状�?
		order.setSellerPaid(true);
		order.setSellerPaidTime(DateTimeUtil.nowUtc());
		orderMapper.updateById(order);

		// 记录订单信息
		addOrderInfo(orderId, "STATUS_CHANGE", "卖家已支付", userId);

		// 创建卖家支付记录
		RechargeWithdrawRecord record = new RechargeWithdrawRecord();
		record.setUserId(userId);
		record.setOrderNo(order.getOrderNo());
		record.setType(3);
		record.setPaymentMethod("BALANCE");
		record.setAmount(payAmount);
		record.setStatus(1);
		record.setIsRead(0);
		record.setRelatedOrderNo(order.getOrderNo());
		record.setCreateTime(DateTimeUtil.nowUtc());
		record.setUpdateTime(DateTimeUtil.nowUtc());
		rechargeWithdrawRecordMapper.insert(record);

		// 向sysaccount账户余额中增加支付金�?
		User sysAccount = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, "sysaccount"));
		if (sysAccount != null) {
			sysAccount.setBalance(sysAccount.getBalance().add(payAmount));
			userMapper.updateById(sysAccount);
		}
	}

	@Override
	public void updateLogistics(Long orderId, Long userId, String logisticsInfo) {
		Order order = orderMapper.selectById(orderId);
		if (order == null) {
			throw new CustomException(ResultCode.ORDER_NOT_FOUND_OR_NO_ACCESS);
		}

		// 验证权限：只有管理员/客服可以更新物流
		User user = userMapper.selectById(userId);
		boolean isAdminOrService = user != null && ("ADMIN".equalsIgnoreCase(user.getRole()) || "SERVICE".equalsIgnoreCase(user.getRole()));

		if (!isAdminOrService) {
			throw new CustomException(ResultCode.PERMISSION_DENIED);
		}

		// 只有已发货但未到货的订单可以更新物流
		if (order.getStatus() != 1 || order.getIsArrived() == Boolean.TRUE) {
			throw new CustomException(ResultCode.ORDER_STATUS_INVALID_FOR_SHIPMENT);
		}

		// 更新物流信息（这里可以扩展为保存到物流信息表�?
		order.setRemark(logisticsInfo);
		order.setUpdateTime(DateTimeUtil.nowUtc());
		orderMapper.updateById(order);

		// 记录订单信息
		addOrderInfo(orderId, "LOGISTICS_UPDATE", "物流信息已更新：" + logisticsInfo, userId);

		log.info("订单 {} 物流信息已更新", orderId);
	}

	@Override
	public void markAsArrived(Long orderId, Long userId) {
		Order order = orderMapper.selectById(orderId);
		if (order == null) {
			throw new CustomException(ResultCode.ORDER_NOT_FOUND_OR_NO_ACCESS);
		}

		// 验证权限：只有管理员/客服可以标记到货
		User user = userMapper.selectById(userId);
		boolean isAdminOrService = user != null && ("ADMIN".equalsIgnoreCase(user.getRole()) || "SERVICE".equalsIgnoreCase(user.getRole()));

		if (!isAdminOrService) {
			throw new CustomException(ResultCode.PERMISSION_DENIED);
		}

		// 只有已发货但未到货的订单可以标记到货
		if (order.getStatus() != 1 || order.getIsArrived() == Boolean.TRUE) {
			throw new CustomException(ResultCode.ORDER_STATUS_INVALID_FOR_SHIPMENT);
		}

		order.setIsArrived(true);
		order.setUpdateTime(DateTimeUtil.nowUtc());
		orderMapper.updateById(order);

		// 记录订单信息
		addOrderInfo(orderId, "STATUS_CHANGE", "订单已到货", userId);

		log.info("订单 {} 已标记为到货", orderId);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void markFinalOrdersAsRead(Long userId, Integer status, List<Long> orderIds, String viewType) {
		log.info("开始标记订单为已读 - 用户ID: {}, 视图类型: {}, 状�? {}, 订单数量: {}", userId, viewType, status, orderIds != null ? orderIds.size() : 0);

		// status 为空时同时处理已完成和已取消；传了别的状态则跳过
		if (status != null && status != 2 && status != 3) {
			log.warn("状态 {} 不是终态订单，跳过标记", status);
			return;
		}

		// 如果没有传订单ID，则不处理
		if (orderIds == null || orderIds.isEmpty()) {
			log.warn("订单ID列表为空，跳过标记");
			return;
		}

		LambdaQueryWrapper<Order> wrapper = new LambdaQueryWrapper<>();
		wrapper.in(Order::getId, orderIds);
		if (status == null) {
			wrapper.in(Order::getStatus, 2, 3);
		} else {
			wrapper.eq(Order::getStatus, status);
		}

		// 根据视图类型确定查询条件和更新字�?
		if ("buyer".equals(viewType)) {
			// 买家视图：查询自己的订单，标�?buyerFinalRead
			wrapper.eq(Order::getUserId, userId);
			wrapper.eq(Order::getBuyerFinalRead, false);

			List<Order> orders = orderMapper.selectList(wrapper);
			log.info("买家视图 - 用户 {} 标记状�?{} 的订单为已读，共 {} 个订单", userId, status, orders.size());
			for (Order order : orders) {
				order.setBuyerFinalRead(true);
				orderMapper.updateById(order);
			}
		} else if ("seller".equals(viewType)) {
			// 卖家视图：查询自己店铺的订单，标�?sellerFinalRead
			LambdaQueryWrapper<Shop> shopWrapper = new LambdaQueryWrapper<>();
			shopWrapper.eq(Shop::getUserId, userId);
			Shop shop = shopMapper.selectOne(shopWrapper);

			if (shop != null) {
				log.info("卖家视图 - 找到店铺 ID: {}", shop.getId());
				wrapper.eq(Order::getShopId, shop.getId());
				wrapper.eq(Order::getSellerFinalRead, false);

				List<Order> orders = orderMapper.selectList(wrapper);
				log.info("卖家视图 - 用户 {} 标记状�?{} 的订单为已读，共 {} 个订单", userId, status, orders.size());
				for (Order order : orders) {
					order.setSellerFinalRead(true);
					orderMapper.updateById(order);
				}
			} else {
				log.warn("用户 {} 没有关联的店铺", userId);
			}
		} else if ("service".equals(viewType)) {
			// 客服/管理员视图：查询指定的订单，标记 serviceFinalRead
			wrapper.eq(Order::getServiceFinalRead, false);

			List<Order> orders = orderMapper.selectList(wrapper);
			log.info("客服视图 - 用户 {} 标记状�?{} 的订单为已读，共 {} 个订单", userId, status, orders.size());
			for (Order order : orders) {
				order.setServiceFinalRead(true);
				orderMapper.updateById(order);
			}
		}

		log.info("用户 {} (视图类型: {}) 已标记状�?{} 的终态订单为已读", userId, viewType, status);
	}

	@Override
	public Map<String, Object> getAllShopOrdersByPage(String keyword, Integer status, Integer page, Integer pageSize) {
		LambdaQueryWrapper<Order> wrapper = new LambdaQueryWrapper<>();
		if (status != null) {
			wrapper.eq(Order::getStatus, status);
		}
		wrapper.orderByDesc(Order::getCreateTime);

		List<Order> allOrders = orderMapper.selectList(wrapper);
		List<OrderRespVO> allOrderVOs = allOrders.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());

		// 搜索过滤
		if (keyword != null && !keyword.trim().isEmpty()) {
			String kw = keyword.trim().toLowerCase();
			allOrderVOs = allOrderVOs.stream()
					.filter(vo -> {
						String shopUsername = vo.getShopUsername() != null ? vo.getShopUsername().toLowerCase() : "";
						String shopNickname = vo.getShopNickname() != null ? vo.getShopNickname().toLowerCase() : "";
						String buyerUsername = vo.getBuyerUsername() != null ? vo.getBuyerUsername().toLowerCase() : "";
						String buyerNickname = vo.getBuyerNickname() != null ? vo.getBuyerNickname().toLowerCase() : "";
						return shopUsername.contains(kw) || shopNickname.contains(kw) ||
								buyerUsername.contains(kw) || buyerNickname.contains(kw);
					})
					.collect(Collectors.toList());
		}

		int total = allOrderVOs.size();
		int totalPages = (int) Math.ceil((double) total / pageSize);
		int start = (page - 1) * pageSize;
		int end = Math.min(start + pageSize, total);
		List<OrderRespVO> records = start < total ? allOrderVOs.subList(start, end) : new ArrayList<>();

		Map<String, Object> result = new HashMap<>();
		result.put("records", records);
		result.put("total", total);
		result.put("totalPages", totalPages);
		return result;
	}

	@Override
	public Map<String, Object> getShopOrdersByPage(Long shopId, String keyword, Integer status, Integer page, Integer pageSize) {
		LambdaQueryWrapper<Order> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Order::getShopId, shopId);
		if (status != null) {
			wrapper.eq(Order::getStatus, status);
		}
		wrapper.orderByDesc(Order::getCreateTime);

		List<Order> allOrders = orderMapper.selectList(wrapper);
		List<OrderRespVO> allOrderVOs = allOrders.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());

		// 搜索过滤
		if (keyword != null && !keyword.trim().isEmpty()) {
			String kw = keyword.trim().toLowerCase();
			allOrderVOs = allOrderVOs.stream()
					.filter(vo -> {
						String buyerUsername = vo.getBuyerUsername() != null ? vo.getBuyerUsername().toLowerCase() : "";
						String buyerNickname = vo.getBuyerNickname() != null ? vo.getBuyerNickname().toLowerCase() : "";
						return buyerUsername.contains(kw) || buyerNickname.contains(kw);
					})
					.collect(Collectors.toList());
		}

		int total = allOrderVOs.size();
		int totalPages = (int) Math.ceil((double) total / pageSize);
		int start = (page - 1) * pageSize;
		int end = Math.min(start + pageSize, total);
		List<OrderRespVO> records = start < total ? allOrderVOs.subList(start, end) : new ArrayList<>();

		Map<String, Object> result = new HashMap<>();
		result.put("records", records);
		result.put("total", total);
		result.put("totalPages", totalPages);
		return result;
	}

	@Override
	public Map<String, Object> getUserOrdersByPage(Long userId, Integer status, Integer page, Integer pageSize) {
		LambdaQueryWrapper<Order> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Order::getUserId, userId);
		if (status != null) {
			wrapper.eq(Order::getStatus, status);
		}
		wrapper.orderByDesc(Order::getCreateTime);

		List<Order> allOrders = orderMapper.selectList(wrapper);
		List<OrderRespVO> allOrderVOs = allOrders.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());

		int total = allOrderVOs.size();
		int totalPages = (int) Math.ceil((double) total / pageSize);
		int start = (page - 1) * pageSize;
		int end = Math.min(start + pageSize, total);
		List<OrderRespVO> records = start < total ? allOrderVOs.subList(start, end) : new ArrayList<>();

		Map<String, Object> result = new HashMap<>();
		result.put("records", records);
		result.put("total", total);
		result.put("totalPages", totalPages);
		return result;
	}
}
