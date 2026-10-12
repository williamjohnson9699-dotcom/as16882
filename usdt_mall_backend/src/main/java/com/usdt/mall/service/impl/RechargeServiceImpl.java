package com.usdt.mall.service.impl;

import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.RechargeWithdrawRecord;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.RechargeWithdrawRecordMapper;
import com.usdt.mall.service.RechargeService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.RechargeReqVO;
import com.usdt.mall.vo.response.RechargeRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletRequest;
import java.util.UUID;

/**
 * 充值服务实现类
 */
@Slf4j
@Service
public class RechargeServiceImpl implements RechargeService {

	@Autowired
	private RechargeWithdrawRecordMapper rechargeWithdrawRecordMapper;

	@Autowired
	private JwtUtil jwtUtil;

	@Override
	public RechargeRespVO submitRecharge(RechargeReqVO reqVO, HttpServletRequest request) {
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

		// 生成订单�?
		String orderNo = generateOrderNo();

		// 创建充值记�?
		RechargeWithdrawRecord record = new RechargeWithdrawRecord();
		record.setUserId(userId);
		record.setOrderNo(orderNo);
		record.setType(1); // 1-充�?
		record.setPaymentMethod(reqVO.getPaymentMethod());
		record.setAmount(reqVO.getAmount());
		record.setStatus(0); // 0-待审�?
		record.setProofImage(reqVO.getProofImage());
		record.setReceivingAddress(reqVO.getReceivingAddress());
		record.setRemark(reqVO.getRemark());
		record.setCreateTime(DateTimeUtil.nowUtc());
		record.setUpdateTime(DateTimeUtil.nowUtc());

		rechargeWithdrawRecordMapper.insert(record);

		log.info("用户 {} 提交充值申请，订单�? {}, 金额: {}, 充值方�? {}",
				userId, orderNo, reqVO.getAmount(), reqVO.getPaymentMethod());

		// 构建响应
		RechargeRespVO respVO = new RechargeRespVO();
		respVO.setId(record.getId());
		respVO.setOrderNo(record.getOrderNo());
		respVO.setPaymentMethod(record.getPaymentMethod());
		respVO.setAmount(record.getAmount());
		respVO.setStatus(record.getStatus());
		respVO.setRemark(record.getRemark());
		respVO.setCreateTime(record.getCreateTime());

		return respVO;
	}

	/**
	 * 生成订单�?
	 */
	private String generateOrderNo() {
		return "R" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
	}
}
