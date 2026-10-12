package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.User;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.service.UserManagementService;
import com.usdt.mall.vo.request.UpdateUserRoleReqVO;
import com.usdt.mall.vo.request.UserQueryReqVO;
import com.usdt.mall.vo.response.UserInfoRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 用户管理服务实现类
 */
@Slf4j
@Service
public class UserManagementServiceImpl implements UserManagementService {

	@Autowired
	private UserMapper userMapper;

	@Override
	public Map<String, Object> queryUsers(UserQueryReqVO reqVO) {
		// 构建查询条件
		QueryWrapper<User> queryWrapper = new QueryWrapper<>();

		// 过滤掉ADMIN和SYSACCOUNT用户
		queryWrapper.ne("role", "ADMIN").ne("role", "SYSACCOUNT");

		// 关键词搜索（ID、用户名、昵称）
		if (reqVO.getKeyword() != null && !reqVO.getKeyword().trim().isEmpty()) {
			String keyword = reqVO.getKeyword().trim();
			queryWrapper.and(wrapper -> wrapper
					.like("id", keyword)
					.or().like("username", keyword)
					.or().like("nickname", keyword)
			);
		}

		// 角色筛选
		if (reqVO.getRole() != null && !reqVO.getRole().equals("all")) {
			queryWrapper.eq("role", reqVO.getRole());
		}

		// 按创建时间倒序排列
		queryWrapper.orderByDesc("create_time");

		// 分页查询
		Page<User> page = new Page<>(reqVO.getPage(), reqVO.getPageSize());
		IPage<User> userPage = userMapper.selectPage(page, queryWrapper);

		// 转换为响应VO
		List<UserInfoRespVO> userList = userPage.getRecords().stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());

		// 构建返回结果
		Map<String, Object> result = new HashMap<>();
		result.put("list", userList);
		result.put("total", userPage.getTotal());
		result.put("page", userPage.getCurrent());
		result.put("pageSize", userPage.getSize());
		result.put("totalPages", userPage.getPages());

		return result;
	}

	@Override
	public void updateUserRole(UpdateUserRoleReqVO reqVO) {
		// 查询用户
		User user = userMapper.selectById(reqVO.getUserId());
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		// 更新角色
		user.setRole(reqVO.getRole());
		userMapper.updateById(user);

		log.info("用户 {} 的角色已更新为: ", reqVO.getUserId(), reqVO.getRole());
	}

	@Override
	public void deleteUser(Long userId) {
		// 查询用户
		User user = userMapper.selectById(userId);
		if (user == null) {
			throw new CustomException(ResultCode.USER_NOT_FOUND);
		}

		// 软删除：设置status为0
		user.setStatus(0);
		userMapper.updateById(user);

		log.info("用户  已被软删除", userId);
	}

	/**
	 * 转换为响应VO
	 */
	private UserInfoRespVO convertToRespVO(User user) {
		UserInfoRespVO vo = new UserInfoRespVO();
		vo.setId(user.getId());
		vo.setUsername(user.getUsername());
		vo.setNickname(user.getNickname());
		vo.setRole(user.getRole());
		vo.setInviteCode(user.getInviteCode());
		vo.setCreateTime(user.getCreateTime());
		return vo;
	}
}
