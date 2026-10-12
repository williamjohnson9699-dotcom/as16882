package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.User;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.service.AuthService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.LoginReqVO;
import com.usdt.mall.vo.request.RegisterReqVO;
import com.usdt.mall.vo.response.UserInfoRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletRequest;
import java.math.BigDecimal;

@Slf4j
@Service
public class AuthServiceImpl implements AuthService {

	@Autowired
	private UserMapper userMapper;

	@Autowired
	private JwtUtil jwtUtil;

	@Autowired
	private BCryptPasswordEncoder passwordEncoder;

	@Override
	public Result<?> register(RegisterReqVO reqVO) {
		// 检查用户名是否已存�?
		LambdaQueryWrapper<User> query = new LambdaQueryWrapper<>();
		query.eq(User::getUsername, reqVO.getUsername());
		User existUser = userMapper.selectOne(query);

		if (existUser != null) {
			throw new CustomException(ResultCode.EMAIL_ALREADY_EXISTS);
		}

		// 生成邀请码（最大�?1，从10000开始）
		String inviteCode = generateInviteCode();

		// 创建新用�?
		User user = new User();
		user.setUsername(reqVO.getUsername());
		user.setNickname(reqVO.getNickname());
		user.setPassword(passwordEncoder.encode(reqVO.getPassword()));
		user.setRole("USER");
		user.setInviteCode(inviteCode);
		user.setBalance(BigDecimal.ZERO);
		user.setStatus(1);
		user.setOnlineStatus(0);
		user.setCreateTime(DateTimeUtil.nowUtc());
		user.setUpdateTime(DateTimeUtil.nowUtc());

		userMapper.insert(user);
		log.info("User registered successfully: {}", user.getUsername());

		return Result.success();
	}

	@Override
	public String login(LoginReqVO reqVO) {
		// 通过用户名查询用�?
		LambdaQueryWrapper<User> query = new LambdaQueryWrapper<>();
		query.eq(User::getUsername, reqVO.getUsername());
		User user = userMapper.selectOne(query);

		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		// 验证密码
		if (!passwordEncoder.matches(reqVO.getPassword(), user.getPassword())) {
			throw new CustomException(ResultCode.INVALID_CREDENTIALS);
		}

		// 检查账户状�?
		if (user.getStatus() == 0) {
			throw new CustomException(ResultCode.ACCOUNT_DISABLED);
		}

		// 更新在线状�?
		user.setOnlineStatus(1);
		user.setUpdateTime(DateTimeUtil.nowUtc());
		userMapper.updateById(user);

		// 生成并返回JWT token
		String token = jwtUtil.generateToken(user.getId(), user.getRole());
		log.info("User logged in successfully: {}", reqVO.getUsername());

		return token;
	}

	@Override
	public String refreshToken(String token) {
		if (token == null || token.isEmpty()) {
			throw new CustomException(ResultCode.TOKEN_REQUIRED);
		}

		// 验证token
		if (!jwtUtil.validateToken(token)) {
			throw new CustomException(ResultCode.INVALID_TOKEN);
		}

		// 从token中获取用户信�?
		Long userId = jwtUtil.getUserIdFromToken(token);
		String role = jwtUtil.getRoleFromToken(token);

		// 生成新token
		String newToken = jwtUtil.generateToken(userId, role);
		log.info("Token refreshed for userId: {}", userId);

		return newToken;
	}

	@Override
	public UserInfoRespVO getUserInfo(HttpServletRequest request) {
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

		// 构建返回对象
		UserInfoRespVO respVO = new UserInfoRespVO();
		respVO.setId(user.getId());
		respVO.setUsername(user.getUsername());
		respVO.setNickname(user.getNickname());
		respVO.setAvatar(user.getAvatar());
		respVO.setRole(user.getRole());
		respVO.setInviteCode(user.getInviteCode());
		respVO.setHasPaymentPassword(user.getPaymentPassword() != null && !user.getPaymentPassword().isEmpty());
		respVO.setBalance(user.getBalance());

		return respVO;
	}

	@Override
	public void setOnlineStatus(Integer status, HttpServletRequest request) {
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

		// 更新用户在线状�?
		User user = userMapper.selectById(userId);
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		user.setOnlineStatus(status);
		userMapper.updateById(user);
	}

	@Override
	public void updateNickname(String nickname, HttpServletRequest request) {
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

		// 更新用户昵称
		User user = userMapper.selectById(userId);
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		user.setNickname(nickname);
		user.setUpdateTime(DateTimeUtil.nowUtc());
		userMapper.updateById(user);
		log.info("User nickname updated: userId={}, newNickname={}", userId, nickname);
	}

	@Override
	public void updateAvatar(String avatar, HttpServletRequest request) {
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

		// 更新用户头像
		User user = userMapper.selectById(userId);
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		user.setAvatar(avatar);
		user.setUpdateTime(DateTimeUtil.nowUtc());
		userMapper.updateById(user);
		log.info("User avatar updated: userId={}, newAvatar={}", userId, avatar);
	}

	@Override
	public void updatePassword(String oldPassword, String newPassword, HttpServletRequest request) {
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

		// 查询用户
		User user = userMapper.selectById(userId);
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		// 验证旧密�?
		if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
			throw new CustomException(ResultCode.INVALID_CREDENTIALS);
		}

		// 更新密码
		user.setPassword(passwordEncoder.encode(newPassword));
		user.setUpdateTime(DateTimeUtil.nowUtc());
		userMapper.updateById(user);
		log.info("User password updated: userId={}", userId);
	}

	@Override
	public void setPaymentPassword(String paymentPassword, HttpServletRequest request) {
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

		// 查询用户
		User user = userMapper.selectById(userId);
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		// 检查是否已设置支付密码
		if (user.getPaymentPassword() != null && !user.getPaymentPassword().isEmpty()) {
			throw new CustomException(ResultCode.PAYMENT_PASSWORD_ALREADY_SET);
		}

		// 设置支付密码
		user.setPaymentPassword(passwordEncoder.encode(paymentPassword));
		user.setUpdateTime(DateTimeUtil.nowUtc());
		userMapper.updateById(user);
		log.info("User payment password set: userId={}", userId);
	}

	@Override
	public void updatePaymentPassword(String oldPaymentPassword, String newPaymentPassword, HttpServletRequest request) {
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

		// 查询用户
		User user = userMapper.selectById(userId);
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		// 检查是否已设置支付密码
		if (user.getPaymentPassword() == null || user.getPaymentPassword().isEmpty()) {
			throw new CustomException(ResultCode.PAYMENT_PASSWORD_NOT_SET);
		}

		// 验证旧支付密�?
		if (!passwordEncoder.matches(oldPaymentPassword, user.getPaymentPassword())) {
			throw new CustomException(ResultCode.INVALID_PAYMENT_PASSWORD);
		}

		// 更新支付密码
		user.setPaymentPassword(passwordEncoder.encode(newPaymentPassword));
		user.setUpdateTime(DateTimeUtil.nowUtc());
		userMapper.updateById(user);
		log.info("User payment password updated: userId={}", userId);
	}

	/**
	 * 生成下一个纯数字邀请码。只统计数字邀请码，从 10000 起递增。
	 *
	 * @return 新的邀请码
	 */
	private String generateInviteCode() {
		QueryWrapper<User> query = new QueryWrapper<>();
		query.select("MAX(CAST(invite_code AS UNSIGNED)) AS invite_code");
		query.apply("invite_code REGEXP '^[0-9]+$'");
		User maxUser = userMapper.selectOne(query);

		int nextCode = 10000;
		if (maxUser != null && maxUser.getInviteCode() != null && !maxUser.getInviteCode().isEmpty()) {
			try {
				int currentMax = Integer.parseInt(maxUser.getInviteCode());
				nextCode = Math.max(currentMax + 1, 10000);
			} catch (NumberFormatException e) {
				log.warn("Invalid invite code format: {}", maxUser.getInviteCode());
			}
		}

		return String.valueOf(nextCode);
	}
}
