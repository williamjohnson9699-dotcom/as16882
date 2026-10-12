package com.usdt.mall.service.impl;

import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.RechargeWithdrawRecord;
import com.usdt.mall.entity.User;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.RechargeWithdrawRecordMapper;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.service.WithdrawService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.WithdrawReqVO;
import com.usdt.mall.vo.response.WithdrawRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletRequest;
import java.util.UUID;

/**
 * 提现服务实现�?
 */
@Slf4j
@Service
public class WithdrawServiceImpl implements WithdrawService {

	@Autowired
	private RechargeWithdrawRecordMapper rechargeWithdrawRecordMapper;

	@Autowired
	private UserMapper userMapper;

	@Autowired
	private JwtUtil jwtUtil;

	@Autowired
	private BCryptPasswordEncoder passwordEncoder;

	@Override
	public WithdrawRespVO submitWithdraw(WithdrawReqVO reqVO, HttpServletRequest request) {
		// 从请求头获取token
		String token = request.getHeader("Authorization");
		if (token == null || token.isEmpty()) {
			throw new CustomException(ResultCode.TOKEN_REQUIRED);
		}

		// 移除 "Bearer " 前缀
		if (token.startsWith("Bearer ")) {
			token = token.substring(7);
		}

		// 验证token
		if (!jwtUtil.validateToken(token)) {
			throw new CustomException(ResultCode.INVALID_TOKEN);
		}

		// 从token中获取用户ID
		Long userId = jwtUtil.getUserIdFromToken(token);

		// 查询用户信息
		User user = userMapper.selectById(userId);
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		// 验证支付密码
		if (user.getPaymentPassword() == null || user.getPaymentPassword().isEmpty()) {
			throw new CustomException(ResultCode.PAYMENT_PASSWORD_NOT_SET);
		}

		if (!passwordEncoder.matches(reqVO.getPaymentPassword(), user.getPaymentPassword())) {
			throw new CustomException(ResultCode.INVALID_PAYMENT_PASSWORD);
		}

		// 验证余额是否足够
		if (user.getBalance().compareTo(reqVO.getAmount()) < 0) {
			throw new CustomException(ResultCode.INSUFFICIENT_BALANCE);
		}

		// 生成订单�?
		String orderNo = generateOrderNo();

		// 创建提现记录
		RechargeWithdrawRecord record = new RechargeWithdrawRecord();
		record.setUserId(userId);
		record.setOrderNo(orderNo);
		record.setType(2); // 2-提现
		record.setPaymentMethod(reqVO.getPaymentMethod());
		record.setAmount(reqVO.getAmount());
		record.setReceivingAddress(reqVO.getReceivingAddress());
		record.setStatus(0); // 0-待审�?
		record.setCreateTime(DateTimeUtil.nowUtc());
		record.setUpdateTime(DateTimeUtil.nowUtc());

		rechargeWithdrawRecordMapper.insert(record);

		log.info("用户 {} 提交提现申请，订单号: {}, 金额: {}, 提现方式: {}",
				userId, orderNo, reqVO.getAmount(), reqVO.getPaymentMethod());

		// 构建响应
		WithdrawRespVO respVO = new WithdrawRespVO();
		respVO.setId(record.getId());
		respVO.setOrderNo(record.getOrderNo());
		respVO.setPaymentMethod(record.getPaymentMethod());
		respVO.setAmount(record.getAmount());
		respVO.setStatus(record.getStatus());
		respVO.setCreateTime(record.getCreateTime());

		return respVO;
	}

	/**
	 * 生成订单�?
	 */
	private String generateOrderNo() {
		return "W" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
	}
}
