package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.RechargeWithdrawRecord;
import com.usdt.mall.entity.User;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.RechargeWithdrawRecordMapper;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.service.RechargeWithdrawRecordService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.RecordQueryReqVO;
import com.usdt.mall.vo.response.RecordInfoRespVO;
import com.usdt.mall.vo.response.RecordPageRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 充�?提现记录服务实现�?
 */
@Slf4j
@Service
public class RechargeWithdrawRecordServiceImpl implements RechargeWithdrawRecordService {

	@Autowired
	private RechargeWithdrawRecordMapper recordMapper;

	@Autowired
	private UserMapper userMapper;

	@Autowired
	private JwtUtil jwtUtil;

	@Override
	public RecordPageRespVO getRecordsByPage(String token, RecordQueryReqVO reqVO) {
		// 从token中获取用户ID
		Long userId = jwtUtil.getUserIdFromToken(token);

		// 构建查询条件
		QueryWrapper<RechargeWithdrawRecord> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("user_id", userId);

		// 如果指定了类型，则按类型过滤
		if (reqVO.getType() != null) {
			queryWrapper.eq("type", reqVO.getType());
		}

		// 按创建时间倒序排列
		queryWrapper.orderByDesc("create_time");

		// 分页查询
		Page<RechargeWithdrawRecord> page = new Page<>(reqVO.getPage(), reqVO.getPageSize());
		Page<RechargeWithdrawRecord> resultPage = recordMapper.selectPage(page, queryWrapper);

		// 转换为响应VO
		List<RecordInfoRespVO> records = resultPage.getRecords().stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());

		// 构建分页响应
		RecordPageRespVO respVO = new RecordPageRespVO();
		respVO.setRecords(records);
		respVO.setTotal(resultPage.getTotal());
		respVO.setPage(reqVO.getPage());
		respVO.setPageSize(reqVO.getPageSize());
		respVO.setTotalPages((int) Math.ceil((double) resultPage.getTotal() / reqVO.getPageSize()));

		return respVO;
	}

	/**
	 * 实体转换为响应VO
	 */
	private RecordInfoRespVO convertToRespVO(RechargeWithdrawRecord record) {
		RecordInfoRespVO respVO = new RecordInfoRespVO();
		BeanUtils.copyProperties(record, respVO);
		return respVO;
	}

	/**
	 * 实体转换为响应VO（包含用户信息）
	 */
	private RecordInfoRespVO convertToRespVOWithUser(RechargeWithdrawRecord record, Map<Long, User> userMap) {
		RecordInfoRespVO respVO = new RecordInfoRespVO();
		BeanUtils.copyProperties(record, respVO);

		// 添加用户信息
		User user = userMap.get(record.getUserId());
		if (user != null) {
			respVO.setUsername(user.getUsername());
			respVO.setNickname(user.getNickname());
		}

		return respVO;
	}

	@Override
	public RecordPageRespVO getAllRecordsByPage(String token, String keyword, Integer type, Integer page, Integer pageSize) {
		// 验证管理员权�?
		String role = jwtUtil.getRoleFromToken(token);
		if (!"ADMIN".equals(role) && !"SERVICE".equals(role)) {
			throw new CustomException(ResultCode.PERMISSION_DENIED);
		}

		// 构建查询条件
		QueryWrapper<RechargeWithdrawRecord> queryWrapper = new QueryWrapper<>();

		// 如果有搜索关键词，先查询用户
		if (keyword != null && !keyword.trim().isEmpty()) {
			QueryWrapper<User> userQueryWrapper = new QueryWrapper<>();
			userQueryWrapper.and(wrapper -> wrapper
					.like("username", keyword)
					.or()
					.like("nickname", keyword)
			);
			List<User> users = userMapper.selectList(userQueryWrapper);

			if (users.isEmpty()) {
				// 没有匹配的用户，返回空结�?
				RecordPageRespVO respVO = new RecordPageRespVO();
				respVO.setRecords(new ArrayList<>());
				respVO.setTotal(0L);
				respVO.setPage(page);
				respVO.setPageSize(pageSize);
				respVO.setTotalPages(0);
				return respVO;
			}

			List<Long> userIds = users.stream().map(User::getId).collect(Collectors.toList());
			queryWrapper.in("user_id", userIds);
		}

		// 如果指定了类型，则按类型过滤
		if (type != null) {
			queryWrapper.eq("type", type);
		}

		// 按创建时间倒序排列
		queryWrapper.orderByDesc("create_time");

		// 分页查询
		Page<RechargeWithdrawRecord> pageObj = new Page<>(page, pageSize);
		Page<RechargeWithdrawRecord> resultPage = recordMapper.selectPage(pageObj, queryWrapper);

		// 获取所有用户信�?
		List<Long> userIds = resultPage.getRecords().stream()
				.map(RechargeWithdrawRecord::getUserId)
				.distinct()
				.collect(Collectors.toList());

		Map<Long, User> userMap = userIds.isEmpty() ? new HashMap<>() :
				userMapper.selectBatchIds(userIds).stream()
						.collect(Collectors.toMap(User::getId, user -> user));

		// 转换为响应VO
		List<RecordInfoRespVO> records = resultPage.getRecords().stream()
				.map(record -> convertToRespVOWithUser(record, userMap))
				.collect(Collectors.toList());

		// 构建分页响应
		RecordPageRespVO respVO = new RecordPageRespVO();
		respVO.setRecords(records);
		respVO.setTotal(resultPage.getTotal());
		respVO.setPage(page);
		respVO.setPageSize(pageSize);
		respVO.setTotalPages((int) Math.ceil((double) resultPage.getTotal() / pageSize));

		return respVO;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void approveRecord(String token, Long recordId) {
		// 验证管理员权�?
		String role = jwtUtil.getRoleFromToken(token);
		if (!"ADMIN".equals(role) && !"SERVICE".equals(role)) {
			throw new CustomException(ResultCode.PERMISSION_DENIED);
		}

		Long auditorId = jwtUtil.getUserIdFromToken(token);

		// 查询记录
		RechargeWithdrawRecord record = recordMapper.selectById(recordId);
		if (record == null) {
			throw new CustomException(ResultCode.RECORD_NOT_FOUND);
		}

		if (record.getStatus() != 0) {
			throw new CustomException(ResultCode.RECORD_ALREADY_AUDITED);
		}

		// 更新记录状�?
		UpdateWrapper<RechargeWithdrawRecord> updateWrapper = new UpdateWrapper<>();
		updateWrapper.eq("id", recordId);
		updateWrapper.set("status", 1);
		updateWrapper.set("auditor_id", auditorId);
		updateWrapper.set("audit_time", DateTimeUtil.nowUtc());
		recordMapper.update(null, updateWrapper);

		// 更新用户余额
		User user = userMapper.selectById(record.getUserId());
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		BigDecimal newBalance;
		if (record.getType() == 1) {
			// 充值：增加余额
			newBalance = user.getBalance().add(record.getAmount());
		} else {
			// 提现：减少余�?
			newBalance = user.getBalance().subtract(record.getAmount());
			if (newBalance.compareTo(BigDecimal.ZERO) < 0) {
				throw new CustomException(ResultCode.INSUFFICIENT_BALANCE);
			}
		}

		UpdateWrapper<User> userUpdateWrapper = new UpdateWrapper<>();
		userUpdateWrapper.eq("id", user.getId());
		userUpdateWrapper.set("balance", newBalance);
		userMapper.update(null, userUpdateWrapper);

		log.info("审核通过记录: recordId={}, auditorId={}, userId={}, type={}, amount={}",
				recordId, auditorId, record.getUserId(), record.getType(), record.getAmount());
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void rejectRecord(String token, Long recordId) {
		// 验证管理员权�?
		String role = jwtUtil.getRoleFromToken(token);
		if (!"ADMIN".equals(role) && !"SERVICE".equals(role)) {
			throw new CustomException(ResultCode.PERMISSION_DENIED);
		}

		Long auditorId = jwtUtil.getUserIdFromToken(token);

		// 查询记录
		RechargeWithdrawRecord record = recordMapper.selectById(recordId);
		if (record == null) {
			throw new CustomException(ResultCode.RECORD_NOT_FOUND);
		}

		if (record.getStatus() != 0) {
			throw new CustomException(ResultCode.RECORD_ALREADY_AUDITED);
		}

		// 更新记录状�?
		UpdateWrapper<RechargeWithdrawRecord> updateWrapper = new UpdateWrapper<>();
		updateWrapper.eq("id", recordId);
		updateWrapper.set("status", 2);
		updateWrapper.set("auditor_id", auditorId);
		updateWrapper.set("audit_time", DateTimeUtil.nowUtc());
		recordMapper.update(null, updateWrapper);

		log.info("拒绝记录: recordId={}, auditorId={}, userId={}",
				recordId, auditorId, record.getUserId());
	}

	@Override
	public Map<String, Integer> getPendingCount(String token) {
		Long userId = jwtUtil.getUserIdFromToken(token);
		String role = jwtUtil.getRoleFromToken(token);
		boolean isAdminOrService = "ADMIN".equals(role) || "SERVICE".equals(role);

		// 充值和提现：统计待审核的记录（status=0�?
		LambdaQueryWrapper<RechargeWithdrawRecord> rechargeWrapper = new LambdaQueryWrapper<>();
		if (!isAdminOrService) {
			rechargeWrapper.eq(RechargeWithdrawRecord::getUserId, userId);
		}
		rechargeWrapper.eq(RechargeWithdrawRecord::getStatus, 0);
		rechargeWrapper.eq(RechargeWithdrawRecord::getType, 1);
		int rechargeCount = recordMapper.selectCount(rechargeWrapper).intValue();

		LambdaQueryWrapper<RechargeWithdrawRecord> withdrawWrapper = new LambdaQueryWrapper<>();
		if (!isAdminOrService) {
			withdrawWrapper.eq(RechargeWithdrawRecord::getUserId, userId);
		}
		withdrawWrapper.eq(RechargeWithdrawRecord::getStatus, 0);
		withdrawWrapper.eq(RechargeWithdrawRecord::getType, 2);
		int withdrawCount = recordMapper.selectCount(withdrawWrapper).intValue();

		// 卖家支付、平台回馈、买家结算：统计未读的记录（is_read=0�?
		LambdaQueryWrapper<RechargeWithdrawRecord> sellerPayWrapper = new LambdaQueryWrapper<>();
		if (!isAdminOrService) {
			sellerPayWrapper.eq(RechargeWithdrawRecord::getUserId, userId);
		}
		sellerPayWrapper.eq(RechargeWithdrawRecord::getIsRead, 0);
		sellerPayWrapper.eq(RechargeWithdrawRecord::getType, 3);
		int sellerPayCount = recordMapper.selectCount(sellerPayWrapper).intValue();

		LambdaQueryWrapper<RechargeWithdrawRecord> platformRebateWrapper = new LambdaQueryWrapper<>();
		if (!isAdminOrService) {
			platformRebateWrapper.eq(RechargeWithdrawRecord::getUserId, userId);
		}
		platformRebateWrapper.eq(RechargeWithdrawRecord::getIsRead, 0);
		platformRebateWrapper.eq(RechargeWithdrawRecord::getType, 4);
		int platformRebateCount = recordMapper.selectCount(platformRebateWrapper).intValue();

		LambdaQueryWrapper<RechargeWithdrawRecord> buyerSettlementWrapper = new LambdaQueryWrapper<>();
		if (!isAdminOrService) {
			buyerSettlementWrapper.eq(RechargeWithdrawRecord::getUserId, userId);
		}
		buyerSettlementWrapper.eq(RechargeWithdrawRecord::getIsRead, 0);
		buyerSettlementWrapper.eq(RechargeWithdrawRecord::getType, 5);
		int buyerSettlementCount = recordMapper.selectCount(buyerSettlementWrapper).intValue();

		Map<String, Integer> result = new HashMap<>();
		result.put("recharge", rechargeCount);
		result.put("withdraw", withdrawCount);
		result.put("sellerPay", sellerPayCount);
		result.put("platformRebate", platformRebateCount);
		result.put("buyerSettlement", buyerSettlementCount);
		result.put("total", rechargeCount + withdrawCount + sellerPayCount + platformRebateCount + buyerSettlementCount);
		return result;
	}

	@Override
	public void markAsRead(String token, Long recordId) {
		Long userId = jwtUtil.getUserIdFromToken(token);

		RechargeWithdrawRecord record = recordMapper.selectById(recordId);
		if (record == null || !record.getUserId().equals(userId)) {
			throw new CustomException(ResultCode.RECORD_NOT_FOUND);
		}

		UpdateWrapper<RechargeWithdrawRecord> updateWrapper = new UpdateWrapper<>();
		updateWrapper.eq("id", recordId);
		updateWrapper.set("is_read", 1);
		recordMapper.update(null, updateWrapper);
	}

	@Override
	public void batchMarkAsRead(String token, List<Long> recordIds) {
		if (recordIds == null || recordIds.isEmpty()) {
			return;
		}

		Long userId = jwtUtil.getUserIdFromToken(token);

		UpdateWrapper<RechargeWithdrawRecord> updateWrapper = new UpdateWrapper<>();
		updateWrapper.eq("user_id", userId);
		updateWrapper.in("id", recordIds);
		updateWrapper.set("is_read", 1);
		recordMapper.update(null, updateWrapper);
	}
}
