package com.usdt.mall.service;

import com.usdt.mall.common.Result;
import com.usdt.mall.vo.request.LoginReqVO;
import com.usdt.mall.vo.request.RegisterReqVO;
import com.usdt.mall.vo.response.UserInfoRespVO;

import javax.servlet.http.HttpServletRequest;

public interface AuthService {

	/**
	 * 用户注册
	 */
	Result<?> register(RegisterReqVO reqVO);

	/**
	 * 用户登录
	 */
	String login(LoginReqVO reqVO);

	/**
	 * 刷新Token
	 */
	String refreshToken(String token);

	/**
	 * 获取用户信息
	 */
	UserInfoRespVO getUserInfo(HttpServletRequest request);

	/**
	 * 设置用户在线状态
	 */
	void setOnlineStatus(Integer status, HttpServletRequest request);

	/**
	 * 更新用户昵称
	 */
	void updateNickname(String nickname, HttpServletRequest request);

	/**
	 * 更新用户头像
	 */
	void updateAvatar(String avatar, HttpServletRequest request);

	/**
	 * 修改登录密码
	 */
	void updatePassword(String oldPassword, String newPassword, HttpServletRequest request);

	/**
	 * 设置支付密码
	 */
	void setPaymentPassword(String paymentPassword, HttpServletRequest request);

	/**
	 * 修改支付密码
	 */
	void updatePaymentPassword(String oldPaymentPassword, String newPaymentPassword, HttpServletRequest request);
}
