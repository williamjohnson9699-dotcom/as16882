package com.usdt.mall.service;

import com.usdt.mall.vo.request.WithdrawReqVO;
import com.usdt.mall.vo.response.WithdrawRespVO;

import javax.servlet.http.HttpServletRequest;

/**
 * 提现服务接口
 */
public interface WithdrawService {

	/**
	 * 提交提现申请
	 *
	 * @param reqVO   提现请求
	 * @param request HTTP请求
	 * @return 提现记录
	 */
	WithdrawRespVO submitWithdraw(WithdrawReqVO reqVO, HttpServletRequest request);
}
