package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.usdt.mall.entity.Shop;
import com.usdt.mall.entity.User;
import com.usdt.mall.entity.VirtualImportTask;
import com.usdt.mall.mapper.ShopMapper;
import com.usdt.mall.mapper.ShopOnSaleCount;
import com.usdt.mall.mapper.ShopProductMapper;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.mapper.VirtualImportTaskMapper;
import com.usdt.mall.service.VirtualDataService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.vo.request.VirtualOrderGenerateReqVO;
import com.usdt.mall.vo.request.VirtualProductGenerateReqVO;
import com.usdt.mall.vo.request.VirtualShopGenerateReqVO;
import com.usdt.mall.vo.response.VirtualImportTaskPageRespVO;
import com.usdt.mall.vo.response.VirtualImportTaskRespVO;
import com.usdt.mall.vo.response.VirtualOrderSubmitRespVO;
import com.usdt.mall.vo.response.VirtualProductSubmitRespVO;
import com.usdt.mall.vo.response.VirtualShopOptionPageRespVO;
import com.usdt.mall.vo.response.VirtualShopOptionRespVO;
import com.usdt.mall.vo.response.VirtualShopPreviewRespVO;
import com.usdt.mall.vo.response.VirtualShopSubmitRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.sql.SQLIntegrityConstraintViolationException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.RejectedExecutionException;
import java.util.stream.Collectors;

@Slf4j
@Service
public class VirtualDataServiceImpl implements VirtualDataService {

	private static final int SHOP_BATCH_SIZE = 20;

	private static final String LOGIN_PASSWORD = "Virtual@2026";

	private static final String PAYMENT_PASSWORD = "123456";

	private static final String TYPE_SHOP = "SHOP";

	private static final String TYPE_ORDER_LEDGER = "ORDER_LEDGER";

	private static final String TYPE_PRODUCT = "PRODUCT";

	private static final int MAX_ORDER_SHOPS = 50;

	private static final int MAX_ORDER_COUNT = 500;

	@Resource
	private VirtualImportTaskMapper virtualImportTaskMapper;

	@Resource
	private UserMapper userMapper;

	@Resource
	private ShopMapper shopMapper;

	@Resource
	private ShopProductMapper shopProductMapper;

	@Resource
	private ObjectMapper objectMapper;

	@Resource
	private PlatformTransactionManager transactionManager;

	@Resource
	@Qualifier("virtualImportExecutor")
	private ThreadPoolTaskExecutor virtualImportExecutor;

	@Resource
	private BCryptPasswordEncoder passwordEncoder;

	@Resource
	private VirtualOrderLedgerWorker virtualOrderLedgerWorker;

	@Resource
	private VirtualProductWorker virtualProductWorker;

	@Override
	public VirtualImportTaskPageRespVO listTasks(Long adminUserId, Integer page, Integer pageSize) {
		int current = page == null || page < 1 ? 1 : page;
		int size = pageSize == null || pageSize < 1 ? 10 : Math.min(pageSize, 100);

		LambdaQueryWrapper<VirtualImportTask> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(VirtualImportTask::getAdminUserId, adminUserId);
		wrapper.orderByDesc(VirtualImportTask::getCreateTime);

		Page<VirtualImportTask> result = virtualImportTaskMapper.selectPage(new Page<>(current, size), wrapper);
		List<VirtualImportTaskRespVO> records = result.getRecords().stream()
				.map(this::toResp)
				.collect(Collectors.toList());

		VirtualImportTaskPageRespVO resp = new VirtualImportTaskPageRespVO();
		resp.setRecords(records);
		resp.setTotal(result.getTotal());
		resp.setPage(current);
		resp.setPageSize(size);
		resp.setTotalPages((int) result.getPages());
		return resp;
	}

	@Override
	public VirtualImportTaskRespVO getTask(Long adminUserId, Long taskId) {
		VirtualImportTask task = virtualImportTaskMapper.selectById(taskId);
		if (task == null || task.getAdminUserId() == null || !task.getAdminUserId().equals(adminUserId)) {
			return null;
		}
		return toResp(task);
	}

	@Override
	public VirtualShopOptionPageRespVO listShops(String keyword, Integer page, Integer pageSize) {
		int current = page == null || page < 1 ? 1 : page;
		int size = pageSize == null || pageSize < 1 ? 20 : Math.min(pageSize, 100);
		String trimmed = keyword == null ? "" : keyword.trim();
		String likeKeyword = trimmed.isEmpty() ? null : escapeLike(trimmed);

		IPage<VirtualShopOptionRespVO> result = shopMapper.selectVirtualShopOptions(
				new Page<>(current, size), likeKeyword);
		List<VirtualShopOptionRespVO> records = result.getRecords();
		Map<Long, Integer> onSaleCounts = countOnSale(records);
		for (VirtualShopOptionRespVO record : records) {
			Integer count = onSaleCounts.get(record.getShopId());
			record.setOnSaleCount(count == null ? 0 : count);
		}

		VirtualShopOptionPageRespVO resp = new VirtualShopOptionPageRespVO();
		resp.setRecords(records);
		resp.setTotal(result.getTotal());
		resp.setPage(current);
		resp.setPageSize(size);
		return resp;
	}

	private Map<Long, Integer> countOnSale(List<VirtualShopOptionRespVO> records) {
		List<Long> shopIds = new ArrayList<>();
		for (VirtualShopOptionRespVO record : records) {
			if (record.getShopId() != null) {
				shopIds.add(record.getShopId());
			}
		}
		if (shopIds.isEmpty()) {
			return Collections.emptyMap();
		}
		Map<Long, Integer> counts = new HashMap<>();
		for (ShopOnSaleCount row : shopProductMapper.countOnSaleByShopIds(shopIds)) {
			if (row.getShopId() == null || row.getOnSaleCount() == null) {
				continue;
			}
			counts.put(row.getShopId(), row.getOnSaleCount().intValue());
		}
		return counts;
	}

	private String escapeLike(String keyword) {
		return keyword.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
	}

	@Override
	public String validateShopGenerate(VirtualShopGenerateReqVO req) {
		if (req == null) {
			return "参数不能为空";
		}
		String prefix = req.getPrefix() == null ? "" : req.getPrefix().trim();
		req.setPrefix(prefix);
		if (!prefix.matches("[A-Za-z0-9]{2,20}")) {
			return "前缀只允许字母和数字，长度 2 到 20";
		}
		Integer count = req.getCount();
		if (count == null || count < 1 || count > 200) {
			return "数量必须是 1 到 200 的整数";
		}
		String rangeError = planShops(prefix, count).error;
		return rangeError;
	}

	@Override
	public VirtualShopPreviewRespVO previewShops(VirtualShopGenerateReqVO req) {
		ShopPlan plan = planShops(req.getPrefix(), req.getCount());
		if (plan.error != null) {
			throw new IllegalArgumentException(plan.error);
		}
		return plan.preview;
	}

	@Override
	public VirtualShopSubmitRespVO submitShops(Long adminUserId, VirtualShopGenerateReqVO req) {
		ShopPlan plan = planShops(req.getPrefix(), req.getCount());
		if (plan.error != null) {
			throw new IllegalArgumentException(plan.error);
		}

		String passwordError = passwordError(req.getPassword());
		if (passwordError != null) {
			throw new IllegalArgumentException(passwordError);
		}

		Map<String, Object> request = new LinkedHashMap<>();
		request.put("prefix", plan.preview.getPrefix());
		request.put("count", req.getCount());
		request.put("usernames", plan.preview.getUsernames());
		request.put("passwordHash", passwordEncoder.encode(req.getPassword()));

		LocalDateTime now = DateTimeUtil.nowUtc();
		VirtualImportTask task = new VirtualImportTask();
		task.setType(TYPE_SHOP);
		task.setStatus("PENDING");
		task.setAdminUserId(adminUserId);
		task.setRequestJson(writeJson(request));
		task.setTotalCount(plan.preview.getUsernames().size());
		task.setSuccessCount(0);
		task.setFailCount(0);
		task.setMessage("等待生成商户号");
		task.setFailDetails("[]");
		task.setCreateTime(now);
		task.setUpdateTime(now);
		virtualImportTaskMapper.insert(task);

		Long taskId = task.getId();
		try {
			virtualImportExecutor.execute(() -> runShopImport(taskId));
		} catch (RejectedExecutionException e) {
			log.warn("virtual shop import queue rejected task {}", taskId);
			markShopTaskFinished(taskId, "FAILED", 0, 0, "生成任务过多，请稍后再试", Collections.emptyList());
		}

		VirtualShopSubmitRespVO resp = new VirtualShopSubmitRespVO();
		resp.setTaskId(taskId);
		return resp;
	}

	@Override
	public String validateOrderGenerate(VirtualOrderGenerateReqVO req) {
		return planOrders(req).error;
	}

	@Override
	public VirtualOrderSubmitRespVO submitOrders(Long adminUserId, VirtualOrderGenerateReqVO req) {
		OrderPlan plan = planOrders(req);
		if (plan.error != null) {
			throw new IllegalArgumentException(plan.error);
		}

		Map<String, Object> request = new LinkedHashMap<>();
		request.put("shopIds", plan.shopIds);
		request.put("pendingShipment", plan.pendingShipment);
		request.put("pendingReceipt", plan.pendingReceipt);
		request.put("completed", plan.completed);
		request.put("cancelled", plan.cancelled);
		request.put("rechargeCount", plan.rechargeCount);
		request.put("withdrawCount", plan.withdrawCount);

		int perShop = plan.pendingShipment + plan.pendingReceipt + plan.completed + plan.cancelled
				+ plan.rechargeCount + plan.withdrawCount;
		int totalCount = plan.shopIds.size() * perShop;

		LocalDateTime now = DateTimeUtil.nowUtc();
		VirtualImportTask task = new VirtualImportTask();
		task.setType(TYPE_ORDER_LEDGER);
		task.setStatus("PENDING");
		task.setAdminUserId(adminUserId);
		task.setRequestJson(writeJson(request));
		task.setTotalCount(totalCount);
		task.setSuccessCount(0);
		task.setFailCount(0);
		task.setMessage("等待生成订单和资金");
		task.setFailDetails("[]");
		task.setCreateTime(now);
		task.setUpdateTime(now);
		virtualImportTaskMapper.insert(task);

		Long taskId = task.getId();
		try {
			virtualImportExecutor.execute(() -> virtualOrderLedgerWorker.run(taskId));
		} catch (RejectedExecutionException e) {
			log.warn("virtual order import queue rejected task {}", taskId);
			markShopTaskFinished(taskId, "FAILED", 0, 0, "生成任务过多，请稍后再试", Collections.emptyList());
		}

		VirtualOrderSubmitRespVO resp = new VirtualOrderSubmitRespVO();
		resp.setTaskId(taskId);
		return resp;
	}

	@Override
	public String validateProductGenerate(VirtualProductGenerateReqVO req) {
		return planProducts(req).error;
	}

	@Override
	public VirtualProductSubmitRespVO submitProducts(Long adminUserId, VirtualProductGenerateReqVO req) {
		ProductPlan plan = planProducts(req);
		if (plan.error != null) {
			throw new IllegalArgumentException(plan.error);
		}

		Map<String, Object> request = new LinkedHashMap<>();
		request.put("shopIds", plan.shopIds);
		request.put("count", plan.count);

		LocalDateTime now = DateTimeUtil.nowUtc();
		VirtualImportTask task = new VirtualImportTask();
		task.setType(TYPE_PRODUCT);
		task.setStatus("PENDING");
		task.setAdminUserId(adminUserId);
		task.setRequestJson(writeJson(request));
		task.setTotalCount(plan.shopIds.size() * plan.count);
		task.setSuccessCount(0);
		task.setFailCount(0);
		task.setMessage("等待生成商品");
		task.setFailDetails("[]");
		task.setCreateTime(now);
		task.setUpdateTime(now);
		virtualImportTaskMapper.insert(task);

		Long taskId = task.getId();
		try {
			virtualImportExecutor.execute(() -> virtualProductWorker.run(taskId));
		} catch (RejectedExecutionException e) {
			log.warn("virtual product import queue rejected task {}", taskId);
			markShopTaskFinished(taskId, "FAILED", 0, 0, "生成任务过多，请稍后再试", Collections.emptyList());
		}

		VirtualProductSubmitRespVO resp = new VirtualProductSubmitRespVO();
		resp.setTaskId(taskId);
		return resp;
	}

	private void runShopImport(Long taskId) {
		try {
			doRunShopImport(taskId);
		} catch (Exception e) {
			log.error("virtual shop import interrupted, taskId={}", taskId, e);
			VirtualImportTask task = virtualImportTaskMapper.selectById(taskId);
			if (task != null && ("PENDING".equals(task.getStatus()) || "RUNNING".equals(task.getStatus()))) {
				markShopTaskFinished(taskId, "FAILED",
						task.getSuccessCount() == null ? 0 : task.getSuccessCount(),
						task.getFailCount() == null ? 0 : task.getFailCount(),
						"生成中断", readFailDetails(task.getFailDetails()));
			}
		}
	}

	private void doRunShopImport(Long taskId) {
		VirtualImportTask task = virtualImportTaskMapper.selectById(taskId);
		if (task == null || !TYPE_SHOP.equals(task.getType())) {
			return;
		}

		Map<String, Object> request = readRequest(task.getRequestJson());
		String prefix = request.get("prefix") instanceof String ? (String) request.get("prefix") : "";
		List<String> usernames = readUsernames(request.get("usernames"));
		if (prefix.isEmpty() || usernames.isEmpty()) {
			markShopTaskFinished(taskId, "FAILED", 0, 0, "任务参数无法读取", Collections.emptyList());
			return;
		}

		task.setStatus("RUNNING");
		task.setMessage("正在生成，共 " + usernames.size() + " 个");
		task.setUpdateTime(DateTimeUtil.nowUtc());
		virtualImportTaskMapper.updateById(task);

		String loginHash = request.get("passwordHash") instanceof String
				? (String) request.get("passwordHash")
				: "";
		if (loginHash.isEmpty()) {
			loginHash = passwordEncoder.encode(LOGIN_PASSWORD);
		}
		String payHash = passwordEncoder.encode(PAYMENT_PASSWORD);
		TransactionTemplate transactionTemplate = new TransactionTemplate(transactionManager);

		int success = 0;
		int fail = 0;
		List<Map<String, String>> failDetails = new ArrayList<>();
		for (int offset = 0; offset < usernames.size(); offset += SHOP_BATCH_SIZE) {
			int end = Math.min(offset + SHOP_BATCH_SIZE, usernames.size());
			for (int i = offset; i < end; i++) {
				String username = usernames.get(i);
				String reason = createShopAccount(transactionTemplate, prefix, username, loginHash, payHash);
				if (reason == null) {
					success++;
				} else {
					fail++;
					Map<String, String> item = new LinkedHashMap<>();
					item.put("target", username);
					item.put("reason", reason);
					failDetails.add(item);
				}
			}
			int done = end;
			updateShopProgress(taskId, success, fail,
					"已处理 " + done + "/" + usernames.size() + "，成功 " + success + "，失败 " + fail,
					failDetails);
		}

		String status;
		if (fail == 0) {
			status = "SUCCESS";
		} else if (success == 0) {
			status = "FAILED";
		} else {
			status = "PARTIAL";
		}
		markShopTaskFinished(taskId, status, success, fail,
				"生成完成，成功 " + success + "，失败 " + fail, failDetails);
	}

	/**
	 * 每个账号单独提交。失败只记下这一条，不回滚本批已经写入的店。
	 */
	private String createShopAccount(TransactionTemplate transactionTemplate, String prefix, String username,
			String loginHash, String payHash) {
		String serial = serialSuffix(prefix, username);
		if (serial == null) {
			return "用户名格式不正确";
		}
		String shopName = prefix + "店" + serial;
		try {
			return transactionTemplate.execute(status -> {
				if (usernameTaken(username)) {
					return "用户名已存在";
				}
				try {
					LocalDateTime now = DateTimeUtil.nowUtc();
					User user = new User();
					user.setUsername(username);
					user.setNickname(username);
					user.setPassword(loginHash);
					user.setPaymentPassword(payHash);
					user.setRole("SHOP");
					user.setInviteCode(username);
					user.setBalance(BigDecimal.ZERO);
					user.setStatus(1);
					user.setOnlineStatus(0);
					user.setCreateTime(now);
					user.setUpdateTime(now);
					userMapper.insert(user);

					Shop shop = new Shop();
					shop.setUserId(user.getId());
					shop.setName(shopName);
					shop.setLevel(1);
					shop.setRating(5.0);
					shop.setFollowCount(0);
					shop.setViews(0);
					shop.setCreditScore(100);
					shop.setStatus(1);
					shop.setCreateTime(now);
					shop.setUpdateTime(now);
					shopMapper.insert(shop);
					return null;
				} catch (Exception e) {
					status.setRollbackOnly();
					if (isDuplicate(e)) {
						return "用户名已存在";
					}
					log.warn("create virtual shop failed, username={}", username, e);
					return "创建失败";
				}
			});
		} catch (Exception e) {
			log.warn("create virtual shop failed, username={}", username, e);
			if (isDuplicate(e)) {
				return "用户名已存在";
			}
			return "创建失败";
		}
	}

	private boolean usernameTaken(String username) {
		LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(User::getUsername, username);
		Long count = userMapper.selectCount(wrapper);
		return count != null && count > 0;
	}

	private void updateShopProgress(Long taskId, int success, int fail, String message,
			List<Map<String, String>> failDetails) {
		VirtualImportTask update = new VirtualImportTask();
		update.setId(taskId);
		update.setSuccessCount(success);
		update.setFailCount(fail);
		update.setMessage(message);
		update.setFailDetails(writeJson(failDetails));
		update.setUpdateTime(DateTimeUtil.nowUtc());
		virtualImportTaskMapper.updateById(update);
	}

	private void markShopTaskFinished(Long taskId, String status, int success, int fail, String message,
			List<Map<String, String>> failDetails) {
		VirtualImportTask update = new VirtualImportTask();
		update.setId(taskId);
		update.setStatus(status);
		update.setSuccessCount(success);
		update.setFailCount(fail);
		update.setMessage(message);
		update.setFailDetails(writeJson(failDetails));
		update.setFinishTime(DateTimeUtil.nowUtc());
		update.setUpdateTime(update.getFinishTime());
		virtualImportTaskMapper.updateById(update);
	}

	private OrderPlan planOrders(VirtualOrderGenerateReqVO req) {
		OrderPlan plan = new OrderPlan();
		if (req == null) {
			plan.error = "参数不能为空";
			return plan;
		}
		if (req.getShopIds() == null || req.getShopIds().isEmpty()) {
			plan.error = "请至少选择 1 个店铺";
			return plan;
		}

		LinkedHashSet<Long> shopIds = new LinkedHashSet<>();
		for (Long shopId : req.getShopIds()) {
			if (shopId == null || shopId <= 0) {
				plan.error = "店铺编号无效";
				return plan;
			}
			shopIds.add(shopId);
		}
		if (shopIds.size() > MAX_ORDER_SHOPS) {
			plan.error = "一次最多选择 50 个店铺";
			return plan;
		}

		String countError = countError("待发货", req.getPendingShipment());
		if (countError == null) {
			countError = countError("待收货", req.getPendingReceipt());
		}
		if (countError == null) {
			countError = countError("已完成", req.getCompleted());
		}
		if (countError == null) {
			countError = countError("已取消", req.getCancelled());
		}
		if (countError == null) {
			countError = countError("充值", req.getRechargeCount());
		}
		if (countError == null) {
			countError = countError("提现", req.getWithdrawCount());
		}
		if (countError != null) {
			plan.error = countError;
			return plan;
		}
		if (req.getPendingShipment() + req.getPendingReceipt() + req.getCompleted() + req.getCancelled()
				+ req.getRechargeCount() + req.getWithdrawCount() == 0) {
			plan.error = "数量不能全部为 0";
			return plan;
		}

		List<Long> distinctShopIds = new ArrayList<>(shopIds);
		List<Shop> shops = shopMapper.selectBatchIds(distinctShopIds);
		Set<Long> found = new LinkedHashSet<>();
		if (shops != null) {
			for (Shop shop : shops) {
				if (shop.getId() != null) {
					found.add(shop.getId());
				}
			}
		}
		List<Long> missing = new ArrayList<>();
		for (Long shopId : distinctShopIds) {
			if (!found.contains(shopId)) {
				missing.add(shopId);
			}
		}
		if (!missing.isEmpty()) {
			plan.error = "店铺不存在";
			return plan;
		}

		req.setShopIds(distinctShopIds);
		plan.shopIds = distinctShopIds;
		plan.pendingShipment = req.getPendingShipment();
		plan.pendingReceipt = req.getPendingReceipt();
		plan.completed = req.getCompleted();
		plan.cancelled = req.getCancelled();
		plan.rechargeCount = req.getRechargeCount();
		plan.withdrawCount = req.getWithdrawCount();
		return plan;
	}

	private ProductPlan planProducts(VirtualProductGenerateReqVO req) {
		ProductPlan plan = new ProductPlan();
		if (req == null) {
			plan.error = "参数不能为空";
			return plan;
		}
		if (req.getShopIds() == null || req.getShopIds().isEmpty()) {
			plan.error = "请至少选择 1 个店铺";
			return plan;
		}

		LinkedHashSet<Long> shopIds = new LinkedHashSet<>();
		for (Long shopId : req.getShopIds()) {
			if (shopId == null || shopId <= 0) {
				plan.error = "店铺编号无效";
				return plan;
			}
			shopIds.add(shopId);
		}
		if (shopIds.size() > MAX_ORDER_SHOPS) {
			plan.error = "一次最多选择 50 个店铺";
			return plan;
		}
		Integer count = req.getCount();
		if (count == null || count < 1 || count > MAX_ORDER_COUNT) {
			plan.error = "商品数量必须是 1 到 500 的整数";
			return plan;
		}

		List<Long> distinctShopIds = new ArrayList<>(shopIds);
		List<Shop> shops = shopMapper.selectBatchIds(distinctShopIds);
		Set<Long> found = new LinkedHashSet<>();
		if (shops != null) {
			for (Shop shop : shops) {
				if (shop.getId() != null) {
					found.add(shop.getId());
				}
			}
		}
		for (Long shopId : distinctShopIds) {
			if (!found.contains(shopId)) {
				plan.error = "店铺不存在";
				return plan;
			}
		}

		req.setShopIds(distinctShopIds);
		req.setCount(count);
		plan.shopIds = distinctShopIds;
		plan.count = count;
		return plan;
	}

	private String countError(String label, Integer value) {
		if (value == null || value < 0 || value > MAX_ORDER_COUNT) {
			return label + "数量必须是 0 到 500 的整数";
		}
		return null;
	}

	private String passwordError(String password) {
		if (password == null || password.length() < 6 || password.length() > 32) {
			return "登录密码长度必须是 6 到 32";
		}
		return null;
	}

	private ShopPlan planShops(String prefix, int count) {
		long max = -1L;
		boolean found = false;
		List<User> users = userMapper.selectList(new LambdaQueryWrapper<User>()
				.likeRight(User::getUsername, prefix)
				.select(User::getUsername));
		for (User user : users) {
			Long serial = parseSerial(prefix, user.getUsername());
			if (serial == null) {
				continue;
			}
			if (serial > Integer.MAX_VALUE) {
				ShopPlan plan = new ShopPlan();
				plan.error = "已有账号序号过大，无法继续生成";
				return plan;
			}
			found = true;
			if (serial > max) {
				max = serial;
			}
		}

		long start = found ? max + 1 : 1;
		long end = start + count - 1L;
		if (end > Integer.MAX_VALUE) {
			ShopPlan plan = new ShopPlan();
			plan.error = "序号超出范围，无法继续生成";
			return plan;
		}

		List<String> usernames = new ArrayList<>(count);
		for (long no = start; no <= end; no++) {
			usernames.add(prefix + formatSerial(no));
		}

		VirtualShopPreviewRespVO preview = new VirtualShopPreviewRespVO();
		preview.setPrefix(prefix);
		preview.setCurrentMax(found ? (int) max : null);
		preview.setStartNo((int) start);
		preview.setEndNo((int) end);
		preview.setUsernames(usernames);

		ShopPlan plan = new ShopPlan();
		plan.preview = preview;
		return plan;
	}

	/**
	 * 只认「前缀 + 纯数字」。大小写按库的唯一索引处理，比较时不区分大小写。
	 */
	private Long parseSerial(String prefix, String username) {
		if (username == null || prefix == null || username.length() <= prefix.length()) {
			return null;
		}
		if (!username.regionMatches(true, 0, prefix, 0, prefix.length())) {
			return null;
		}
		String suffix = username.substring(prefix.length());
		if (suffix.isEmpty() || !suffix.chars().allMatch(Character::isDigit)) {
			return null;
		}
		if (suffix.length() > 18) {
			return Long.MAX_VALUE;
		}
		try {
			return Long.parseLong(suffix);
		} catch (NumberFormatException e) {
			return Long.MAX_VALUE;
		}
	}

	private String serialSuffix(String prefix, String username) {
		Long serial = parseSerial(prefix, username);
		if (serial == null || serial > Integer.MAX_VALUE) {
			return null;
		}
		return formatSerial(serial);
	}

	private String formatSerial(long no) {
		return String.format("%02d", no);
	}

	private boolean isDuplicate(Throwable error) {
		Throwable current = error;
		while (current != null) {
			if (current instanceof DuplicateKeyException || current instanceof SQLIntegrityConstraintViolationException) {
				return true;
			}
			String message = current.getMessage();
			if (message != null && (message.contains("Duplicate entry") || message.contains("uk_username"))) {
				return true;
			}
			current = current.getCause();
		}
		return false;
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

	private List<String> readUsernames(Object raw) {
		if (!(raw instanceof List)) {
			return Collections.emptyList();
		}
		List<String> usernames = new ArrayList<>();
		for (Object item : (List<?>) raw) {
			if (item != null) {
				usernames.add(String.valueOf(item));
			}
		}
		return usernames;
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
			return value instanceof List ? "[]" : "{}";
		}
	}

	private VirtualImportTaskRespVO toResp(VirtualImportTask task) {
		VirtualImportTaskRespVO resp = new VirtualImportTaskRespVO();
		resp.setId(task.getId());
		resp.setType(task.getType());
		resp.setStatus(task.getStatus());
		resp.setAdminUserId(task.getAdminUserId());
		resp.setRequestJson(parseJson(task.getRequestJson(), Collections.emptyMap()));
		resp.setTotalCount(task.getTotalCount());
		resp.setSuccessCount(task.getSuccessCount());
		resp.setFailCount(task.getFailCount());
		resp.setMessage(task.getMessage());
		resp.setFailDetails(parseJson(task.getFailDetails(), Collections.emptyList()));
		resp.setCreateTime(task.getCreateTime());
		resp.setUpdateTime(task.getUpdateTime());
		resp.setFinishTime(task.getFinishTime());
		return resp;
	}

	private Object parseJson(String raw, Object empty) {
		if (raw == null || raw.trim().isEmpty()) {
			return empty;
		}
		try {
			return objectMapper.readValue(raw, Object.class);
		} catch (Exception e) {
			return empty;
		}
	}

	private static class ProductPlan {
		private String error;
		private List<Long> shopIds;
		private int count;
	}

	private static class OrderPlan {
		private String error;
		private List<Long> shopIds;
		private int pendingShipment;
		private int pendingReceipt;
		private int completed;
		private int cancelled;
		private int rechargeCount;
		private int withdrawCount;
	}

	private static class ShopPlan {
		private String error;
		private VirtualShopPreviewRespVO preview;
	}
}
