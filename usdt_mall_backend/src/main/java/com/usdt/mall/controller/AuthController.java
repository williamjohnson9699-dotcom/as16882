package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.AuthService;
import com.usdt.mall.vo.request.LoginReqVO;
import com.usdt.mall.vo.request.RegisterReqVO;
import com.usdt.mall.vo.response.UserInfoRespVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@Tag(name = "认证管理", description = "用户认证相关接口")
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

	@Autowired
	private AuthService authService;

	@Operation(summary = "用户注册", description = "普通用户注册")
	@PostMapping("/register")
	public Result<?> register(@RequestBody @Validated RegisterReqVO reqVO) {
		return authService.register(reqVO);
	}

	@Operation(summary = "用户登录", description = "用户登录，成功后在响应头返回JWT token")
	@PostMapping("/login")
	public Result<?> login(@RequestBody @Validated LoginReqVO reqVO, HttpServletResponse response) {
		String token = authService.login(reqVO);
		response.setHeader("Authorization", token);
		return Result.success();
	}

	@Operation(summary = "刷新Token", description = "刷新JWT token")
	@GetMapping("/refresh")
	public Result<?> refreshToken(HttpServletRequest request, HttpServletResponse response) {
		String token = request.getHeader("Authorization");
		String refreshedToken = authService.refreshToken(token);
		response.setHeader("Authorization", refreshedToken);
		return Result.success();
	}

	@Operation(summary = "用户退出", description = "用户退出登录")
	@PostMapping("/logout")
	public Result<?> logout(HttpServletRequest request) {
		// 前端清除token即可，后端可以记录退出日志
		return Result.success();
	}

	@Operation(summary = "获取用户信息", description = "获取当前登录用户的详细信息")
	@GetMapping("/userinfo")
	public Result<UserInfoRespVO> getUserInfo(HttpServletRequest request) {
		UserInfoRespVO userInfo = authService.getUserInfo(request);
		return Result.successWith(userInfo);
	}

	@Operation(summary = "设置用户在线状态", description = "设置当前用户的在线状态（1:在线, 0:离线）")
	@PostMapping("/online-status")
	public Result<?> setOnlineStatus(@RequestParam Integer status, HttpServletRequest request) {
		authService.setOnlineStatus(status, request);
		return Result.success();
	}

	@Operation(summary = "更新用户昵称", description = "更新当前用户的昵称")
	@PutMapping("/nickname")
	public Result<?> updateNickname(@RequestParam String nickname, HttpServletRequest request) {
		authService.updateNickname(nickname, request);
		return Result.success();
	}

	@Operation(summary = "更新用户头像", description = "更新当前用户的头像")
	@PutMapping("/avatar")
	public Result<?> updateAvatar(@RequestParam String avatar, HttpServletRequest request) {
		authService.updateAvatar(avatar, request);
		return Result.success();
	}

	@Operation(summary = "修改登录密码", description = "修改当前用户的登录密码")
	@PutMapping("/password")
	public Result<?> updatePassword(@RequestParam String oldPassword,
									@RequestParam String newPassword,
									HttpServletRequest request) {
		authService.updatePassword(oldPassword, newPassword, request);
		return Result.success();
	}

	@Operation(summary = "设置支付密码", description = "设置当前用户的支付密码")
	@PostMapping("/payment-password")
	public Result<?> setPaymentPassword(@RequestParam String paymentPassword,
										HttpServletRequest request) {
		authService.setPaymentPassword(paymentPassword, request);
		return Result.success();
	}

	@Operation(summary = "修改支付密码", description = "修改当前用户的支付密码")
	@PutMapping("/payment-password")
	public Result<?> updatePaymentPassword(@RequestParam String oldPaymentPassword,
										   @RequestParam String newPaymentPassword,
										   HttpServletRequest request) {
		authService.updatePaymentPassword(oldPaymentPassword, newPaymentPassword, request);
		return Result.success();
	}
}
