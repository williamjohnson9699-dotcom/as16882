package com.usdt.mall.service;

import com.usdt.mall.vo.request.RechargeReqVO;
import com.usdt.mall.vo.response.RechargeRespVO;

import javax.servlet.http.HttpServletRequest;

/**
 * 充值服务接口
 */
public interface RechargeService {

	/**
	 * 提交充值申请
	 *
	 * @param reqVO   充值请求
	 * @param request HTTP请求
	 * @return 充值记录
	 */
	RechargeRespVO submitRecharge(RechargeReqVO reqVO, HttpServletRequest request);
}
