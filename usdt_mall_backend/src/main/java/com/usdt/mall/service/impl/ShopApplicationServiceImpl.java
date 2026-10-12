package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.Shop;
import com.usdt.mall.entity.ShopApplication;
import com.usdt.mall.entity.User;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.ShopApplicationMapper;
import com.usdt.mall.mapper.ShopMapper;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.service.ShopApplicationService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.ShopApplicationReqVO;
import com.usdt.mall.vo.response.ShopApplicationRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 店铺申请服务实现�?
 */
@Slf4j
@Service
public class ShopApplicationServiceImpl implements ShopApplicationService {

	@Autowired
	private ShopApplicationMapper shopApplicationMapper;

	@Autowired
	private ShopMapper shopMapper;

	@Autowired
	private UserMapper userMapper;

	@Autowired
	private JwtUtil jwtUtil;

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void submitApplication(String token, ShopApplicationReqVO reqVO) {
		Long userId = jwtUtil.getUserIdFromToken(token);

		// 验证邀请码
		String inviteCode = reqVO.getInviteCode();
		if (inviteCode == null || inviteCode.trim().isEmpty()) {
			throw new CustomException(ResultCode.INVITE_CODE_REQUIRED);
		}

		User inviter = findAdminByInviteCode(inviteCode.trim());
		if (inviter == null) {
			if (inviteCodeExists(inviteCode.trim())) {
				throw new CustomException(ResultCode.INVITE_CODE_NOT_ADMIN);
			}
			throw new CustomException(ResultCode.INVITE_CODE_INVALID);
		}

		// 检查是否已有待审核或通过的申请，一个用户只能有一个店�?
		QueryWrapper<ShopApplication> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("user_id", userId);
		queryWrapper.in("status", "pending", "approved");
		ShopApplication existingApplication = shopApplicationMapper.selectOne(queryWrapper);

		if (existingApplication != null) {
			if ("approved".equals(existingApplication.getStatus())) {
				throw new CustomException(ResultCode.SHOP_APPLICATION_APPROVED);
			} else {
				throw new CustomException(ResultCode.SHOP_APPLICATION_PENDING);
			}
		}

		ShopApplication application = new ShopApplication();
		application.setUserId(userId);
		application.setShopName(reqVO.getShopName());
		application.setShopLogo(reqVO.getShopLogo());
		application.setContactName(reqVO.getContactName());
		application.setContactPhone(reqVO.getContactPhone());
		application.setIdNumber(reqVO.getIdNumber());
		application.setIdFrontImage(reqVO.getIdFrontImage());
		application.setIdBackImage(reqVO.getIdBackImage());
		application.setCategory(reqVO.getCategory());
		application.setAddress(reqVO.getAddress());
		application.setInviteCode(reqVO.getInviteCode());
		application.setStatus("pending");
		application.setCreateTime(DateTimeUtil.nowUtc());
		application.setUpdateTime(DateTimeUtil.nowUtc());

		shopApplicationMapper.insert(application);
	}

	/**
	 * 按邀请码查找管理员。同一邀请码可能同时挂在普通用户上，只认管理员。
	 *
	 * @param inviteCode 已去掉首尾空白的邀请码
	 * @return 管理员用户，没有时返回 null
	 */
	private User findAdminByInviteCode(String inviteCode) {
		QueryWrapper<User> userQueryWrapper = new QueryWrapper<>();
		userQueryWrapper.eq("invite_code", inviteCode);
		userQueryWrapper.eq("role", "ADMIN");
		userQueryWrapper.last("LIMIT 1");
		return userMapper.selectOne(userQueryWrapper);
	}

	/**
	 * 判断是否已有任意用户使用该邀请码。
	 *
	 * @param inviteCode 已去掉首尾空白的邀请码
	 * @return 存在返回 true
	 */
	private boolean inviteCodeExists(String inviteCode) {
		QueryWrapper<User> userQueryWrapper = new QueryWrapper<>();
		userQueryWrapper.eq("invite_code", inviteCode);
		userQueryWrapper.last("LIMIT 1");
		return userMapper.selectOne(userQueryWrapper) != null;
	}

	@Override
	public ShopApplicationRespVO getMyApplication(String token) {
		Long userId = jwtUtil.getUserIdFromToken(token);

		QueryWrapper<ShopApplication> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("user_id", userId);
		queryWrapper.orderByDesc("create_time");
		queryWrapper.last("LIMIT 1");

		ShopApplication application = shopApplicationMapper.selectOne(queryWrapper);

		if (application == null) {
			return null;
		}

		return convertToRespVO(application);
	}

	@Override
	public List<ShopApplicationRespVO> getMyApplicationHistory(String token) {
		Long userId = jwtUtil.getUserIdFromToken(token);

		QueryWrapper<ShopApplication> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("user_id", userId);
		queryWrapper.orderByDesc("create_time");

		List<ShopApplication> applications = shopApplicationMapper.selectList(queryWrapper);

		return applications.stream()
				.map(this::convertToDetailRespVO)
				.collect(Collectors.toList());
	}

	private ShopApplicationRespVO convertToRespVO(ShopApplication application) {
		ShopApplicationRespVO vo = new ShopApplicationRespVO();
		vo.setId(application.getId());
		vo.setShopName(application.getShopName());
		vo.setContactName(application.getContactName());
		vo.setContactPhone(application.getContactPhone());
		vo.setCategory(application.getCategory());
		vo.setStatus(application.getStatus());
		vo.setInviteCode(application.getInviteCode());
		vo.setReviewNote(application.getReviewNote());
		vo.setCreateTime(application.getCreateTime());
		return vo;
	}

	@Override
	public Map<String, Object> getApplicationsByPage(String token, String status, String keyword, Integer page, Integer pageSize) {
		// 构建查询条件
		QueryWrapper<ShopApplication> queryWrapper = new QueryWrapper<>();

		// 按状态过�?
		if (status != null && !"all".equals(status)) {
			queryWrapper.eq("status", status);
		}

		// 按关键词搜索
		if (keyword != null && !keyword.trim().isEmpty()) {
			queryWrapper.and(wrapper -> wrapper
					.like("shop_name", keyword)
					.or()
					.like("contact_name", keyword)
					.or()
					.like("contact_phone", keyword)
			);
		}

		// 按创建时间倒序
		queryWrapper.orderByDesc("create_time");

		// 分页查询
		Page<ShopApplication> pageResult = new Page<>(page, pageSize);
		Page<ShopApplication> resultPage = shopApplicationMapper.selectPage(pageResult, queryWrapper);

		// 转换为响应VO
		List<ShopApplicationRespVO> records = resultPage.getRecords().stream()
				.map(this::convertToDetailRespVO)
				.collect(Collectors.toList());

		// 构建返回结果
		Map<String, Object> result = new HashMap<>();
		result.put("records", records);
		result.put("total", resultPage.getTotal());
		result.put("page", page);
		result.put("pageSize", pageSize);
		result.put("totalPages", (int) Math.ceil((double) resultPage.getTotal() / pageSize));

		return result;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void approveApplication(String token, Long id) {
		ShopApplication application = shopApplicationMapper.selectById(id);
		if (application == null) {
			throw new CustomException(ResultCode.SHOP_APPLICATION_NOT_FOUND);
		}

		if (!"pending".equals(application.getStatus())) {
			throw new CustomException(ResultCode.SHOP_APPLICATION_ALREADY_PROCESSED);
		}

		// 检查该用户是否已有店铺
		QueryWrapper<Shop> shopQuery = new QueryWrapper<>();
		shopQuery.eq("user_id", application.getUserId());
		Shop existingShop = shopMapper.selectOne(shopQuery);
		if (existingShop != null) {
			throw new CustomException(ResultCode.USER_ALREADY_HAS_SHOP);
		}

		// 创建店铺记录
		Shop shop = new Shop();
		shop.setName(application.getShopName());
		shop.setLogo(application.getShopLogo());
		shop.setUserId(application.getUserId());
		shop.setCategory(application.getCategory());
		shop.setContactName(application.getContactName());
		shop.setContactPhone(application.getContactPhone());
		shop.setAddress(application.getAddress());
		shop.setInviteCode(application.getInviteCode());

		// 初始化店铺数�?
		shop.setLevel(1);
		shop.setRating(5.0);
		shop.setFollowCount(0);
		shop.setViews(0);
		shop.setCreditScore(100);
		shop.setStatus(1); // 1-营业
		shop.setCreateTime(DateTimeUtil.nowUtc());
		shop.setUpdateTime(DateTimeUtil.nowUtc());

		shopMapper.insert(shop);

		// 更新用户角色为店铺用�?
		User user = userMapper.selectById(application.getUserId());
		if (user != null) {
			user.setRole("SHOP");
			userMapper.updateById(user);
		}

		// 更新申请状�?
		application.setStatus("approved");
		application.setUpdateTime(DateTimeUtil.nowUtc());
		shopApplicationMapper.updateById(application);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void rejectApplication(String token, Long id, String reviewNote) {
		ShopApplication application = shopApplicationMapper.selectById(id);
		if (application == null) {
			throw new CustomException(ResultCode.SHOP_APPLICATION_NOT_FOUND);
		}

		if (!"pending".equals(application.getStatus())) {
			throw new CustomException(ResultCode.SHOP_APPLICATION_ALREADY_PROCESSED);
		}

		application.setStatus("rejected");
		application.setReviewNote(reviewNote);
		application.setUpdateTime(DateTimeUtil.nowUtc());
		shopApplicationMapper.updateById(application);
	}

	@Override
	public int getPendingCount(String token) {
		QueryWrapper<ShopApplication> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("status", "pending");
		return shopApplicationMapper.selectCount(queryWrapper).intValue();
	}

	private ShopApplicationRespVO convertToDetailRespVO(ShopApplication application) {
		ShopApplicationRespVO vo = new ShopApplicationRespVO();
		vo.setId(application.getId());

		// 查询用户信息
		User user = userMapper.selectById(application.getUserId());
		if (user != null) {
			vo.setUsername(user.getUsername());
			vo.setNickname(user.getNickname());
		}

		vo.setShopName(application.getShopName());
		vo.setShopLogo(application.getShopLogo());
		vo.setContactName(application.getContactName());
		vo.setContactPhone(application.getContactPhone());
		vo.setCategory(application.getCategory());
		vo.setIdNumber(application.getIdNumber());
		vo.setIdFrontImage(application.getIdFrontImage());
		vo.setIdBackImage(application.getIdBackImage());
		vo.setStatus(application.getStatus());
		vo.setInviteCode(application.getInviteCode());
		vo.setAddress(application.getAddress());
		vo.setReviewNote(application.getReviewNote());
		vo.setCreateTime(application.getCreateTime());
		return vo;
	}
}
