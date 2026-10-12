package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.UserManagementService;
import com.usdt.mall.vo.request.UpdateUserRoleReqVO;
import com.usdt.mall.vo.request.UserQueryReqVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Tag(name = "用户管理", description = "用户管理相关接口")
@RestController
@RequestMapping("/api/v1/user-management")
public class UserManagementController {

	@Autowired
	private UserManagementService userManagementService;

	@Operation(summary = "查询用户列表", description = "分页查询用户列表")
	@PostMapping("/query")
	public Result<Map<String, Object>> queryUsers(@RequestBody UserQueryReqVO reqVO) {
		Map<String, Object> result = userManagementService.queryUsers(reqVO);
		return Result.successWith(result);
	}

	@Operation(summary = "修改用户角色", description = "修改指定用户的角色")
	@PostMapping("/update-role")
	public Result<?> updateUserRole(@RequestBody @Validated UpdateUserRoleReqVO reqVO) {
		userManagementService.updateUserRole(reqVO);
		return Result.success();
	}

	@Operation(summary = "删除用户", description = "删除指定用户")
	@DeleteMapping("/{userId}")
	public Result<?> deleteUser(@PathVariable Long userId) {
		userManagementService.deleteUser(userId);
		return Result.success();
	}
}
