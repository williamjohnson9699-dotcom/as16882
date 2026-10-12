package com.usdt.mall.service;

import com.usdt.mall.vo.request.UpdateUserRoleReqVO;
import com.usdt.mall.vo.request.UserQueryReqVO;

import java.util.Map;

/**
 * 用户管理服务接口
 */
public interface UserManagementService {
	/**
	 * 查询用户列表
	 */
	Map<String, Object> queryUsers(UserQueryReqVO reqVO);

	/**
	 * 修改用户角色
	 */
	void updateUserRole(UpdateUserRoleReqVO reqVO);

	/**
	 * 删除用户
	 */
	void deleteUser(Long userId);
}
