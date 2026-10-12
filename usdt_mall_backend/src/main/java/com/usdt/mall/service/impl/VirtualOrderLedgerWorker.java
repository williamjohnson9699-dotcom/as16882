package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.usdt.mall.entity.Address;
import com.usdt.mall.entity.Order;
import com.usdt.mall.entity.OrderInfo;
import com.usdt.mall.entity.OrderItem;
import com.usdt.mall.entity.Product;
import com.usdt.mall.entity.RechargeWithdrawRecord;
import com.usdt.mall.entity.Shop;
import com.usdt.mall.entity.ShopProduct;
import com.usdt.mall.entity.User;
import com.usdt.mall.entity.VirtualImportTask;
import com.usdt.mall.mapper.AddressMapper;
import com.usdt.mall.mapper.OrderInfoMapper;
import com.usdt.mall.mapper.OrderItemMapper;
import com.usdt.mall.mapper.OrderMapper;
import com.usdt.mall.mapper.ProductMapper;
import com.usdt.mall.mapper.RechargeWithdrawRecordMapper;
import com.usdt.mall.mapper.ShopMapper;
import com.usdt.mall.mapper.ShopProductMapper;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.mapper.VirtualImportTaskMapper;
import com.usdt.mall.service.SystemConfigService;
import com.usdt.mall.util.DateTimeUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 按真实下单账本写入虚拟订单和资金。每批一家店，一家失败不影响其他店。
 */
@Slf4j
@Component
public class VirtualOrderLedgerWorker {

	private static final DateTimeFormatter ORDER_NO_TIME = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

	private static final int BUYER_COUNT = 40;

	@Resource
	private VirtualImportTaskMapper virtualImportTaskMapper;

	@Resource
	private UserMapper userMapper;

	@Resource
	private ShopMapper shopMapper;

	@Resource
	private ShopProductMapper shopProductMapper;

	@Resource
	private ProductMapper productMapper;

	@Resource
	private OrderMapper orderMapper;

	@Resource
	private OrderItemMapper orderItemMapper;

	@Resource
	private OrderInfoMapper orderInfoMapper;

	@Resource
	private RechargeWithdrawRecordMapper rechargeWithdrawRecordMapper;

	@Resource
	private AddressMapper addressMapper;

	@Resource
	private SystemConfigService systemConfigService;

	@Resource
	private ObjectMapper objectMapper;

	@Resource
	private PlatformTransactionManager transactionManager;

	public void run(Long taskId) {
		try {
			doRun(taskId);
		} catch (Exception e) {
			log.error("virtual order ledger interrupted, taskId={}", taskId, e);
			VirtualImportTask task = virtualImportTaskMapper.selectById(taskId);
			if (task != null && ("PENDING".equals(task.getStatus()) || "RUNNING".equals(task.getStatus()))) {
				finish(taskId, "FAILED",
						task.getSuccessCount() == null ? 0 : task.getSuccessCount(),
						task.getFailCount() == null ? 0 : task.getFailCount(),
						"生成中断", readFailDetails(task.getFailDetails()));
			}
		}
	}

	private void doRun(Long taskId) {
		VirtualImportTask task = virtualImportTaskMapper.selectById(taskId);
		if (task == null || !"ORDER_LEDGER".equals(task.getType()) || !"PENDING".equals(task.getStatus())) {
			return;
		}
		if (claim(taskId) == 0) {
			return;
		}

		Map<String, Object> request = readRequest(task.getRequestJson());
		List<Long> shopIds = readLongs(request.get("shopIds"));
		int pendingShipment = readInt(request.get("pendingShipment"));
		int pendingReceipt = readInt(request.get("pendingReceipt"));
		int completed = readInt(request.get("completed"));
		int cancelled = readInt(request.get("cancelled"));
		int rechargeCount = readInt(request.get("rechargeCount"));
		int withdrawCount = readInt(request.get("withdrawCount"));
		int totalCount = task.getTotalCount() == null ? 0 : task.getTotalCount();
		if (shopIds.isEmpty()) {
			finish(taskId, "FAILED", 0, totalCount, "任务参数无法读取", Collections.emptyList());
			return;
		}

		List<String> missingBuyers = missingBuyers();
		if (!missingBuyers.isEmpty()) {
			String message = "请先导入虚拟买家 vbuyer01 到 vbuyer40";
			if (missingBuyers.size() < BUYER_COUNT) {
				message = message + "，缺少 " + joinNames(missingBuyers);
			}
			List<Map<String, String>> details = new ArrayList<>();
			details.add(detail("vbuyer01-vbuyer40", message));
			finish(taskId, "FAILED", 0, totalCount, message, details);
			return;
		}
		if (findByUsername("sysaccount") == null) {
			List<Map<String, String>> details = new ArrayList<>();
			details.add(detail("sysaccount", "系统账户不存在"));
			finish(taskId, "FAILED", 0, totalCount, "系统账户不存在", details);
			return;
		}

		List<Long> buyerIds = new ArrayList<>();
		for (int i = 1; i <= BUYER_COUNT; i++) {
			User buyer = findByUsername(buyerName(i));
			if (buyer == null || buyer.getId() == null) {
				List<Map<String, String>> details = new ArrayList<>();
				details.add(detail("vbuyer01-vbuyer40", "请先导入虚拟买家 vbuyer01 到 vbuyer40"));
				finish(taskId, "FAILED", 0, totalCount, "请先导入虚拟买家 vbuyer01 到 vbuyer40", details);
				return;
			}
			buyerIds.add(buyer.getId());
		}

		RunContext context = new RunContext();
		context.tx = new TransactionTemplate(transactionManager);
		context.buyerIds = buyerIds;
		context.adminUserId = task.getAdminUserId();
		context.times = new TimeWheel(DateTimeUtil.nowUtc());
		context.seq = new AtomicInteger(ThreadLocalRandom.current().nextInt(10000));

		int success = 0;
		int fail = 0;
		List<Map<String, String>> details = new ArrayList<>();
		int shopIndex = 0;
		for (Long shopId : shopIds) {
			shopIndex++;
			ShopOutcome outcome = processShop(context, shopId, pendingShipment, pendingReceipt, completed,
					cancelled, rechargeCount, withdrawCount);
			success += outcome.success;
			fail += outcome.fail;
			details.addAll(outcome.details);
			progress(taskId, success, fail,
					"已处理 " + shopIndex + "/" + shopIds.size() + " 家店，成功 " + success + "，失败 " + fail,
					details);
		}

		String status;
		if (fail == 0) {
			status = "SUCCESS";
		} else if (success == 0) {
			status = "FAILED";
		} else {
			status = "PARTIAL";
		}
		finish(taskId, status, success, fail, "生成完成，成功 " + success + "，失败 " + fail, details);
	}

	private ShopOutcome processShop(RunContext context, Long shopId, int pendingShipment, int pendingReceipt,
			int completed, int cancelled, int rechargeCount, int withdrawCount) {
		ShopOutcome outcome = new ShopOutcome();
		int plannedOrders = pendingShipment + pendingReceipt + completed + cancelled;
		int planned = rechargeCount + plannedOrders + withdrawCount;
		try {
			Shop shop = shopMapper.selectById(shopId);
			User seller = shop == null || shop.getUserId() == null ? null : userMapper.selectById(shop.getUserId());
			String target = seller != null && seller.getUsername() != null ? seller.getUsername() : String.valueOf(shopId);
			if (shop == null || seller == null) {
				outcome.fail = planned;
				outcome.details.add(detail(target, shop == null ? "店铺不存在" : "店铺用户不存在"));
				return outcome;
			}

			for (int i = 0; i < rechargeCount; i++) {
				String reason = context.tx.execute(status -> {
					try {
						writeShopCash(context, seller.getId(), 1, context.times.next(0));
						return null;
					} catch (Exception e) {
						status.setRollbackOnly();
						log.warn("virtual shop recharge failed, shopId={}", shopId, e);
						return "创建失败";
					}
				});
				mark(outcome, target, "充值", reason);
			}

			List<Product> products = loadOnSaleProducts(shopId);
			if (products.isEmpty()) {
				if (plannedOrders > 0) {
					outcome.fail += plannedOrders;
					outcome.details.add(detail(target, "没有在售商品，计划订单 " + plannedOrders + " 条全部失败"));
				}
			} else {
				int[] cursor = new int[] {0};
				writeOrders(context, outcome, shop, seller, products, cursor, pendingShipment, 0, "待发货");
				writeOrders(context, outcome, shop, seller, products, cursor, pendingReceipt, 1, "待收货");
				writeOrders(context, outcome, shop, seller, products, cursor, completed, 2, "已完成");
				writeOrders(context, outcome, shop, seller, products, cursor, cancelled, 3, "已取消");
			}

			int made = 0;
			for (int i = 0; i < withdrawCount; i++) {
				BigDecimal amount = randomCash();
				Boolean accepted = context.tx.execute(status -> {
					try {
						User locked = lockUser(seller.getId());
						if (locked == null || money(locked.getBalance()).compareTo(amount) < 0) {
							return false;
						}
						writeShopCashAmount(context, locked, 2, amount, context.times.next(0));
						return true;
					} catch (RuntimeException e) {
						status.setRollbackOnly();
						log.warn("virtual shop withdraw failed, shopId={}", shopId, e);
						throw e;
					}
				});
				if (accepted == null || !accepted) {
					break;
				}
				made++;
				outcome.success++;
			}
			int missed = withdrawCount - made;
			if (missed > 0) {
				outcome.fail += missed;
				outcome.details.add(detail(target, "计划提现 " + withdrawCount + " 条，实际生成 " + made + " 条"));
			}
		} catch (Exception e) {
			log.warn("virtual shop ledger failed, shopId={}", shopId, e);
			int rest = planned - outcome.success - outcome.fail;
			if (rest > 0) {
				outcome.fail += rest;
			}
			outcome.details.add(detail(String.valueOf(shopId), "创建失败"));
		}
		return outcome;
	}

	private void writeOrders(RunContext context, ShopOutcome outcome, Shop shop, User seller, List<Product> products,
			int[] cursor, int count, int orderStatus, String statusLabel) {
		for (int i = 0; i < count; i++) {
			Product product = products.get(cursor[0] % products.size());
			cursor[0]++;
			Long buyerId = context.buyerIds.get(context.buyerCursor % context.buyerIds.size());
			context.buyerCursor++;
			String target = seller.getUsername() + " " + statusLabel;
			String reason = context.tx.execute(status -> {
				try {
					writeOrder(context, shop, seller.getId(), buyerId, product, orderStatus);
					return null;
				} catch (LedgerSkip skip) {
					status.setRollbackOnly();
					return skip.reason;
				} catch (Exception e) {
					status.setRollbackOnly();
					log.warn("virtual order failed, shopId={}, status={}", shop.getId(), orderStatus, e);
					return "创建失败";
				}
			});
			mark(outcome, target, statusLabel, reason);
		}
	}

	/**
	 * 金额步骤与 OrderServiceImpl 的下单、卖家支付、确认收货、取消一致。不改库存，不改销量。
	 */
	private void writeOrder(RunContext context, Shop shop, Long sellerId, Long buyerId, Product product, int orderStatus) {
		User sysAccount = findByUsername("sysaccount");
		if (sysAccount == null || sysAccount.getId() == null) {
			throw new LedgerSkip("系统账户不存在");
		}
		Map<Long, User> locked = lockInOrder(buyerId, sellerId, sysAccount.getId());
		User buyer = locked.get(buyerId);
		User seller = locked.get(sellerId);
		User sys = locked.get(sysAccount.getId());
		if (buyer == null) {
			throw new LedgerSkip("虚拟买家不存在");
		}
		if (seller == null) {
			throw new LedgerSkip("店铺用户不存在");
		}
		if (sys == null) {
			throw new LedgerSkip("系统账户不存在");
		}

		BigDecimal total = product.getPrice();
		Integer profitRateValue = systemConfigService.getProfitRate();
		BigDecimal profitRate = new BigDecimal(profitRateValue);
		BigDecimal rate = profitRate.divide(new BigDecimal(100));
		BigDecimal profit = total.multiply(rate);
		BigDecimal cost = total.subtract(profit);

		boolean sellerPays = orderStatus == 1 || orderStatus == 2;
		boolean completes = orderStatus == 2;
		boolean cancels = orderStatus == 3;
		int tailMinutes = completes ? 60 : (orderStatus == 1 ? 40 : (cancels ? 5 : 0));
		LocalDateTime createTime = context.times.next(tailMinutes);
		LocalDateTime payTime = createTime.plusMinutes(20);
		LocalDateTime shipTime = createTime.plusMinutes(40);
		LocalDateTime arriveTime = createTime.plusMinutes(50);
		LocalDateTime rebateTime = createTime.plusMinutes(60);
		LocalDateTime cancelTime = createTime.plusMinutes(5);

		BigDecimal buyerBalance = money(buyer.getBalance());
		BigDecimal sellerBalance = money(seller.getBalance());
		BigDecimal sysBalance = money(sys.getBalance());
		BigDecimal topUp = BigDecimal.ZERO;
		if (buyerBalance.compareTo(total) < 0) {
			topUp = total.subtract(buyerBalance).setScale(2, RoundingMode.CEILING);
			buyerBalance = buyerBalance.add(topUp);
		}
		buyerBalance = buyerBalance.subtract(total);
		sysBalance = sysBalance.add(total);
		if (sellerPays) {
			if (sellerBalance.compareTo(cost) < 0) {
				throw new LedgerSkip("卖家余额不足，无法支付成本");
			}
			sellerBalance = sellerBalance.subtract(cost);
			sysBalance = sysBalance.add(cost);
		}
		if (completes || cancels) {
			// 货款刚刚在本单记入系统账户，退款或回馈只退出这一单。
			// 系统账户原有余额可能已是负数，不能拿历史欠款挡住虚拟订单。
			sysBalance = sysBalance.subtract(total);
			if (completes) {
				sellerBalance = sellerBalance.add(total);
			} else {
				buyerBalance = buyerBalance.add(total);
			}
		}

		Address address = findOrCreateAddress(buyer, createTime);
		String orderNo = allocateOrderNo(context, createTime);

		if (topUp.signum() > 0) {
			insertCashRecord(buyer.getId(), allocateRecordNo(context, "R", createTime.minusSeconds(30)), 1, topUp,
					"USDT", createTime.minusSeconds(30), context.adminUserId, orderNo, "余额不足，补足订单差额");
		}

		Order order = new Order();
		order.setOrderNo(orderNo);
		order.setUserId(buyer.getId());
		order.setShopId(shop.getId());
		order.setAddressId(address.getId());
		order.setTotalAmount(total);
		order.setOrderType(1);
		order.setStatus(orderStatus);
		order.setProfitRate(profitRate);
		order.setCost(cost);
		order.setProfit(profit);
		order.setSellerPaid(sellerPays);
		order.setPlatformRebate(completes);
		order.setIsArrived(completes);
		order.setBuyerFinalRead(false);
		order.setSellerFinalRead(false);
		order.setServiceFinalRead(false);
		order.setCreateTime(createTime);
		if (sellerPays) {
			order.setSellerPaidTime(payTime);
		}
		if (completes) {
			order.setPlatformRebateTime(rebateTime);
			order.setUpdateTime(rebateTime);
		} else if (cancels) {
			order.setCancelReason("虚拟订单取消");
			order.setUpdateTime(cancelTime);
		} else if (orderStatus == 1) {
			order.setUpdateTime(shipTime);
		} else {
			order.setUpdateTime(createTime);
		}
		orderMapper.insert(order);

		OrderItem item = new OrderItem();
		item.setOrderId(order.getId());
		item.setProductId(product.getId());
		item.setProductName(cut(product.getName() == null ? "商品" : product.getName(), 200));
		item.setProductImage(cut(product.getMainImage(), 255));
		item.setPrice(product.getPrice());
		item.setQuantity(1);
		item.setSubtotal(total);
		item.setCreateTime(createTime);
		orderItemMapper.insert(item);

		insertOrderRecord(buyer.getId(), orderNo, 5, total, null, createTime);
		addInfo(order.getId(), "订单已创建", buyer.getId(), buyerNameOf(context, buyer), createTime);

		if (sellerPays) {
			insertOrderRecord(seller.getId(), orderNo, 3, cost, "BALANCE", payTime);
			addInfo(order.getId(), "卖家已支付", seller.getId(), buyerNameOf(context, seller), payTime);
			addInfo(order.getId(), "订单已发货", context.adminUserId, operatorName(context, context.adminUserId), shipTime);
		}
		if (completes) {
			addInfo(order.getId(), "订单已到货", context.adminUserId, operatorName(context, context.adminUserId), arriveTime);
			insertOrderRecord(seller.getId(), orderNo, 4, total, null, rebateTime);
			addInfo(order.getId(), "订单已完成", buyer.getId(), buyerNameOf(context, buyer), rebateTime);
		}
		if (cancels) {
			addInfo(order.getId(), "订单已取消，原因：虚拟订单取消", buyer.getId(), buyerNameOf(context, buyer), cancelTime);
		}

		buyer.setBalance(buyerBalance);
		buyer.setUpdateTime(DateTimeUtil.nowUtc());
		seller.setBalance(sellerBalance);
		seller.setUpdateTime(DateTimeUtil.nowUtc());
		sys.setBalance(sysBalance);
		sys.setUpdateTime(DateTimeUtil.nowUtc());
		userMapper.updateById(buyer);
		userMapper.updateById(seller);
		userMapper.updateById(sys);
	}

	private void writeShopCash(RunContext context, Long userId, int type, LocalDateTime time) {
		User user = lockUser(userId);
		if (user == null) {
			throw new IllegalStateException("店铺用户不存在");
		}
		writeShopCashAmount(context, user, type, randomCash(), time);
	}

	private void writeShopCashAmount(RunContext context, User user, int type, BigDecimal amount, LocalDateTime time) {
		BigDecimal balance = money(user.getBalance());
		if (type == 1) {
			balance = balance.add(amount);
		} else {
			balance = balance.subtract(amount);
		}
		String prefix = type == 1 ? "R" : "W";
		insertCashRecord(user.getId(), allocateRecordNo(context, prefix, time), type, amount, "USDT", time,
				context.adminUserId, null, null);
		user.setBalance(balance);
		user.setUpdateTime(DateTimeUtil.nowUtc());
		userMapper.updateById(user);
	}

	private void insertOrderRecord(Long userId, String orderNo, int type, BigDecimal amount, String paymentMethod,
			LocalDateTime time) {
		RechargeWithdrawRecord record = new RechargeWithdrawRecord();
		record.setUserId(userId);
		record.setOrderNo(orderNo);
		record.setType(type);
		record.setPaymentMethod(paymentMethod);
		record.setAmount(amount);
		record.setStatus(1);
		record.setIsRead(0);
		record.setRelatedOrderNo(orderNo);
		record.setCreateTime(time);
		record.setUpdateTime(time);
		rechargeWithdrawRecordMapper.insert(record);
	}

	private void insertCashRecord(Long userId, String orderNo, int type, BigDecimal amount, String paymentMethod,
			LocalDateTime time, Long auditorId, String relatedOrderNo, String remark) {
		RechargeWithdrawRecord record = new RechargeWithdrawRecord();
		record.setUserId(userId);
		record.setOrderNo(orderNo);
		record.setType(type);
		record.setPaymentMethod(paymentMethod);
		record.setAmount(amount);
		record.setStatus(1);
		record.setIsRead(0);
		record.setAuditorId(auditorId);
		record.setAuditTime(time);
		record.setRelatedOrderNo(relatedOrderNo);
		record.setRemark(remark);
		record.setCreateTime(time);
		record.setUpdateTime(time);
		rechargeWithdrawRecordMapper.insert(record);
	}

	private void addInfo(Long orderId, String content, Long operatorId, String operatorName, LocalDateTime time) {
		OrderInfo info = new OrderInfo();
		info.setOrderId(orderId);
		info.setInfoType("STATUS_CHANGE");
		info.setContent(content);
		info.setOperatorId(operatorId);
		info.setOperatorName(operatorName == null ? "系统" : operatorName);
		info.setCreateTime(time);
		orderInfoMapper.insert(info);
	}

	private Address findOrCreateAddress(User buyer, LocalDateTime time) {
		LambdaQueryWrapper<Address> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Address::getUserId, buyer.getId());
		wrapper.orderByDesc(Address::getIsDefault);
		wrapper.last("LIMIT 1");
		Address address = addressMapper.selectOne(wrapper);
		if (address != null) {
			return address;
		}
		address = new Address();
		address.setUserId(buyer.getId());
		address.setName(cut(buyer.getUsername(), 50));
		address.setPhone("13100000000");
		address.setAddress("Virtual Buyer");
		address.setIsDefault(1);
		address.setCreateTime(time);
		address.setUpdateTime(time);
		addressMapper.insert(address);
		return address;
	}

	private List<Product> loadOnSaleProducts(Long shopId) {
		LambdaQueryWrapper<ShopProduct> linkWrapper = new LambdaQueryWrapper<>();
		linkWrapper.eq(ShopProduct::getShopId, shopId);
		List<ShopProduct> links = shopProductMapper.selectList(linkWrapper);
		List<Long> productIds = new ArrayList<>();
		for (ShopProduct link : links) {
			if (link.getProductId() != null) {
				productIds.add(link.getProductId());
			}
		}
		List<Product> products = new ArrayList<>();
		for (int offset = 0; offset < productIds.size(); offset += 500) {
			List<Long> part = productIds.subList(offset, Math.min(offset + 500, productIds.size()));
			LambdaQueryWrapper<Product> wrapper = new LambdaQueryWrapper<>();
			wrapper.in(Product::getId, part);
			wrapper.eq(Product::getStatus, 1);
			products.addAll(productMapper.selectList(wrapper));
		}
		List<Product> onSale = new ArrayList<>();
		for (Product product : products) {
			if (product.getPrice() != null && product.getPrice().compareTo(BigDecimal.ZERO) > 0) {
				onSale.add(product);
			}
		}
		return onSale;
	}

	private String allocateOrderNo(RunContext context, LocalDateTime time) {
		LocalDateTime cursor = time.withNano(0);
		for (int i = 0; i < 20; i++) {
			String orderNo = cursor.format(ORDER_NO_TIME) + String.format("%04d", Math.floorMod(context.seq.getAndIncrement(), 10000));
			LambdaQueryWrapper<Order> wrapper = new LambdaQueryWrapper<>();
			wrapper.eq(Order::getOrderNo, orderNo);
			Long count = orderMapper.selectCount(wrapper);
			if (count == null || count == 0) {
				return orderNo;
			}
			cursor = cursor.plusSeconds(1);
		}
		throw new IllegalStateException("订单号重复");
	}

	private String allocateRecordNo(RunContext context, String prefix, LocalDateTime time) {
		LocalDateTime cursor = time.withNano(0);
		for (int i = 0; i < 20; i++) {
			String orderNo = prefix + cursor.format(ORDER_NO_TIME)
					+ String.format("%04d", Math.floorMod(context.seq.getAndIncrement(), 10000));
			LambdaQueryWrapper<RechargeWithdrawRecord> wrapper = new LambdaQueryWrapper<>();
			wrapper.eq(RechargeWithdrawRecord::getOrderNo, orderNo);
			Long count = rechargeWithdrawRecordMapper.selectCount(wrapper);
			if (count == null || count == 0) {
				return orderNo;
			}
			cursor = cursor.plusSeconds(1);
		}
		throw new IllegalStateException("资金单号重复");
	}

	private List<String> missingBuyers() {
		List<String> names = new ArrayList<>();
		for (int i = 1; i <= BUYER_COUNT; i++) {
			names.add(buyerName(i));
		}
		LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
		wrapper.in(User::getUsername, names);
		wrapper.select(User::getUsername);
		Set<String> found = new HashSet<>();
		for (User user : userMapper.selectList(wrapper)) {
			if (user.getUsername() != null) {
				found.add(user.getUsername());
			}
		}
		List<String> missing = new ArrayList<>();
		for (String name : names) {
			if (!found.contains(name)) {
				missing.add(name);
			}
		}
		return missing;
	}

	private String buyerName(int index) {
		return String.format("vbuyer%02d", index);
	}

	private Map<Long, User> lockInOrder(Long firstId, Long secondId, Long thirdId) {
		List<Long> ids = new ArrayList<>();
		ids.add(firstId);
		ids.add(secondId);
		ids.add(thirdId);
		Collections.sort(ids);
		Map<Long, User> locked = new HashMap<>();
		for (Long id : ids) {
			if (id != null && !locked.containsKey(id)) {
				locked.put(id, lockUser(id));
			}
		}
		return locked;
	}

	private User lockUser(Long userId) {
		LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(User::getId, userId);
		wrapper.last("FOR UPDATE");
		return userMapper.selectOne(wrapper);
	}

	private User findByUsername(String username) {
		LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(User::getUsername, username);
		return userMapper.selectOne(wrapper);
	}

	private BigDecimal randomCash() {
		int cents = ThreadLocalRandom.current().nextInt(10000, 500001);
		return BigDecimal.valueOf(cents, 2);
	}

	private BigDecimal money(BigDecimal value) {
		return value == null ? BigDecimal.ZERO : value;
	}

	private String cut(String value, int max) {
		if (value == null) {
			return null;
		}
		return value.length() <= max ? value : value.substring(0, max);
	}

	private String buyerNameOf(RunContext context, User user) {
		if (user == null) {
			return "系统";
		}
		String name = user.getNickname() != null ? user.getNickname() : user.getUsername();
		context.names.put(user.getId(), name);
		return name;
	}

	private String operatorName(RunContext context, Long userId) {
		if (userId == null) {
			return "系统";
		}
		if (context.names.containsKey(userId)) {
			return context.names.get(userId);
		}
		User user = userMapper.selectById(userId);
		String name = user == null ? "系统" : (user.getNickname() != null ? user.getNickname() : user.getUsername());
		context.names.put(userId, name);
		return name;
	}

	private void mark(ShopOutcome outcome, String target, String label, String reason) {
		if (reason == null) {
			outcome.success++;
			return;
		}
		outcome.fail++;
		outcome.details.add(detail(target, reason));
	}

	private Map<String, String> detail(String target, String reason) {
		Map<String, String> item = new LinkedHashMap<>();
		item.put("target", target);
		item.put("reason", reason);
		return item;
	}

	private String joinNames(List<String> names) {
		StringBuilder builder = new StringBuilder();
		for (String name : names) {
			if (builder.length() > 180) {
				builder.append("等");
				break;
			}
			if (builder.length() > 0) {
				builder.append("、");
			}
			builder.append(name);
		}
		return builder.toString();
	}

	private int claim(Long taskId) {
		UpdateWrapper<VirtualImportTask> wrapper = new UpdateWrapper<>();
		wrapper.eq("id", taskId).eq("status", "PENDING").eq("type", "ORDER_LEDGER");
		wrapper.set("status", "RUNNING");
		wrapper.set("message", "正在生成订单和资金");
		wrapper.set("update_time", DateTimeUtil.nowUtc());
		return virtualImportTaskMapper.update(null, wrapper);
	}

	private void progress(Long taskId, int success, int fail, String message, List<Map<String, String>> details) {
		VirtualImportTask update = new VirtualImportTask();
		update.setId(taskId);
		update.setSuccessCount(success);
		update.setFailCount(fail);
		update.setMessage(message);
		update.setFailDetails(writeJson(details));
		update.setUpdateTime(DateTimeUtil.nowUtc());
		virtualImportTaskMapper.updateById(update);
	}

	private void finish(Long taskId, String status, int success, int fail, String message,
			List<Map<String, String>> details) {
		VirtualImportTask update = new VirtualImportTask();
		update.setId(taskId);
		update.setStatus(status);
		update.setSuccessCount(success);
		update.setFailCount(fail);
		update.setMessage(cut(message, 500));
		update.setFailDetails(writeJson(details));
		update.setFinishTime(DateTimeUtil.nowUtc());
		update.setUpdateTime(update.getFinishTime());
		virtualImportTaskMapper.updateById(update);
	}

	private Map<String, Object> readRequest(String raw) {
		if (raw == null || raw.trim().isEmpty()) {
			return Collections.emptyMap();
		}
		try {
			return objectMapper.readValue(raw, new TypeReference<Map<String, Object>>() {
			});
		} catch (Exception e) {
			return Collections.emptyMap();
		}
	}

	private List<Long> readLongs(Object raw) {
		if (!(raw instanceof List)) {
			return Collections.emptyList();
		}
		List<Long> values = new ArrayList<>();
		for (Object item : (List<?>) raw) {
			if (item instanceof Number) {
				values.add(((Number) item).longValue());
			}
		}
		return values;
	}

	private int readInt(Object raw) {
		if (raw instanceof Number) {
			return ((Number) raw).intValue();
		}
		return 0;
	}

	private List<Map<String, String>> readFailDetails(String raw) {
		if (raw == null || raw.trim().isEmpty()) {
			return new ArrayList<>();
		}
		try {
			return objectMapper.readValue(raw, new TypeReference<List<Map<String, String>>>() {
			});
		} catch (Exception e) {
			return new ArrayList<>();
		}
	}

	private String writeJson(Object value) {
		try {
			return objectMapper.writeValueAsString(value);
		} catch (Exception e) {
			return "[]";
		}
	}

	private static class RunContext {
		private TransactionTemplate tx;
		private List<Long> buyerIds;
		private int buyerCursor;
		private Long adminUserId;
		private TimeWheel times;
		private AtomicInteger seq;
		private final Map<Long, String> names = new HashMap<>();
	}

	private static class ShopOutcome {
		private int success;
		private int fail;
		private final List<Map<String, String>> details = new ArrayList<>();
	}

	private static class LedgerSkip extends RuntimeException {
		private final String reason;

		private LedgerSkip(String reason) {
			this.reason = reason;
		}
	}

	/**
	 * 以执行时刻为终点，在之前约 30 天里取时间。先占满不同日期，再用不同的时分秒。
	 */
	private static class TimeWheel {
		private final LocalDateTime anchor;
		private final LocalDate startDay;
		private final Set<LocalDateTime> used = new HashSet<>();
		private int cursor;

		private TimeWheel(LocalDateTime anchor) {
			this.anchor = anchor.withNano(0);
			this.startDay = this.anchor.toLocalDate().minusDays(29);
		}

		private LocalDateTime next(int tailMinutes) {
			LocalDate day = anchor.toLocalDate().minusDays(Math.floorMod(cursor, 30));
			int second = Math.floorMod(cursor, 60);
			int minute = Math.floorMod(cursor / 60, 60);
			int hour = 8 + Math.floorMod(cursor / 3600, 10);
			cursor++;
			LocalDateTime create = LocalDateTime.of(day, LocalTime.of(hour, minute, second));
			if (create.plusMinutes(tailMinutes).isAfter(anchor)) {
				create = anchor.minusMinutes(tailMinutes);
			}
			if (create.toLocalDate().isBefore(startDay)) {
				create = LocalDateTime.of(startDay, LocalTime.of(8, 0, 0));
			}
			while (!used.add(create)) {
				create = create.minusSeconds(1);
			}
			return create;
		}
	}
}
