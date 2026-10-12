package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.Shop;
import com.usdt.mall.entity.ShopProduct;
import com.usdt.mall.entity.ShopStatistics;
import com.usdt.mall.entity.User;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.*;
import com.usdt.mall.service.OrderService;
import com.usdt.mall.service.ShopManagementService;
import com.usdt.mall.vo.request.ShopQueryReqVO;
import com.usdt.mall.vo.request.ShopUpdateReqVO;
import com.usdt.mall.vo.response.ShopInfoRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 店铺管理服务实现类
 */
@Slf4j
@Service
public class ShopManagementServiceImpl implements ShopManagementService {

	@Autowired
	private ShopMapper shopMapper;

	@Autowired
	private UserMapper userMapper;

	@Autowired
	private ShopProductMapper shopProductMapper;

	@Autowired
	private OrderMapper orderMapper;

	@Autowired
	private ShopStatisticsMapper shopStatisticsMapper;

	@Autowired
	private OrderService orderService;

	@Override
	public Map<String, Object> queryShops(ShopQueryReqVO reqVO) {
		// 构建查询条件
		QueryWrapper<Shop> queryWrapper = new QueryWrapper<>();

		// 关键词搜索（店铺名称、店主姓名、手机号）
		if (reqVO.getKeyword() != null && !reqVO.getKeyword().trim().isEmpty()) {
			String keyword = reqVO.getKeyword().trim();

			// 先查询符合条件的用户ID列表（按昵称或用户名搜索）
			QueryWrapper<User> userWrapper = new QueryWrapper<>();
			userWrapper.and(wrapper -> wrapper
					.like("nickname", keyword)
					.or()
					.like("username", keyword)
			);
			List<User> users = userMapper.selectList(userWrapper);
			List<Long> userIds = users.stream()
					.map(User::getId)
					.collect(Collectors.toList());

			// 构建店铺查询条件：店铺名称 或 user_id在用户列表中
			queryWrapper.and(wrapper -> {
				wrapper.like("name", keyword);
				if (!userIds.isEmpty()) {
					wrapper.or().in("user_id", userIds);
				}
			});
		}

		// 按创建时间倒序排列
		queryWrapper.orderByDesc("create_time");

		// 分页查询
		Page<Shop> page = new Page<>(reqVO.getPage(), reqVO.getPageSize());
		IPage<Shop> shopPage = shopMapper.selectPage(page, queryWrapper);

		// 转换为响应VO
		List<ShopInfoRespVO> shopList = shopPage.getRecords().stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());

		// 构建返回结果
		Map<String, Object> result = new HashMap<>();
		result.put("list", shopList);
		result.put("total", shopPage.getTotal());
		result.put("page", shopPage.getCurrent());
		result.put("pageSize", shopPage.getSize());
		result.put("totalPages", shopPage.getPages());

		return result;
	}

	/**
	 * 转换为响应VO
	 */
	private ShopInfoRespVO convertToRespVO(Shop shop) {
		ShopInfoRespVO vo = new ShopInfoRespVO();
		vo.setId(shop.getId());
		vo.setUserId(shop.getUserId());
		vo.setShopName(shop.getName());
		vo.setLogo(shop.getLogo());
		vo.setContactName(shop.getContactName());
		vo.setContactPhone(shop.getContactPhone());
		vo.setCategory(shop.getCategory());
		vo.setInviteCode(shop.getInviteCode());
		vo.setAddress(shop.getAddress());
		vo.setLevel(shop.getLevel());
		vo.setRating(shop.getRating());
		vo.setFollowCount(shop.getFollowCount());
		vo.setViews(shop.getViews());
		vo.setCreditScore(shop.getCreditScore());

		// 获取店主昵称
		User user = userMapper.selectById(shop.getUserId());
		if (user != null) {
			vo.setOwnerNickname(user.getNickname());
		}

		// TODO: 获取商品数量
		vo.setProductCount(0);

		// 从shop_statistics表查询订单数和销售额
		LambdaQueryWrapper<ShopStatistics> statsWrapper = new LambdaQueryWrapper<>();
		statsWrapper.eq(ShopStatistics::getShopId, shop.getId());
		statsWrapper.orderByDesc(ShopStatistics::getStatDate);
		statsWrapper.last("LIMIT 1");
		ShopStatistics statistics = shopStatisticsMapper.selectOne(statsWrapper);
		if (statistics != null) {
			vo.setOrderCount(statistics.getOrderCount());
			vo.setSalesAmount(statistics.getSalesAmount() != null ? statistics.getSalesAmount().doubleValue() : 0.0);
		} else {
			vo.setOrderCount(0);
			vo.setSalesAmount(0.0);
		}

		// 设置店铺状态
		vo.setStatus(shop.getStatus() == 1 ? "active" : "inactive");
		vo.setPaymentOverdue(orderService.isShopPaymentOverdue(shop.getId()));

		vo.setCreateTime(shop.getCreateTime());
		return vo;
	}

	@Override
	public void deleteShop(Long shopId) {
		// 检查店铺是否存在
		Shop shop = shopMapper.selectById(shopId);
		if (shop == null) {
			throw new CustomException(ResultCode.SHOP_NOT_EXISTS);
		}

		// 删除店铺商品关联
		QueryWrapper<ShopProduct> shopProductWrapper = new QueryWrapper<>();
		shopProductWrapper.eq("shop_id", shopId);
		shopProductMapper.delete(shopProductWrapper);

		// 删除店铺
		shopMapper.deleteById(shopId);

		log.info("删除店铺成功: shopId={}", shopId);
	}

	@Override
	public void updateShopStatus(Long shopId, Integer status) {
		// 检查店铺是否存在
		Shop shop = shopMapper.selectById(shopId);
		if (shop == null) {
			throw new CustomException(ResultCode.SHOP_NOT_EXISTS);
		}

		// 更新店铺状态
		shop.setStatus(status);
		shopMapper.updateById(shop);

		log.info("更新店铺状态成功: shopId={}, status={}", shopId, status);
	}

	@Override
	public void updateShop(Long shopId, ShopUpdateReqVO reqVO) {
		Shop shop = shopMapper.selectById(shopId);
		if (shop == null) {
			throw new CustomException(ResultCode.SHOP_NOT_EXISTS);
		}

		if (reqVO.getShopName() != null) shop.setName(reqVO.getShopName());
		if (reqVO.getLogo() != null) shop.setLogo(reqVO.getLogo());
		if (reqVO.getContactName() != null) shop.setContactName(reqVO.getContactName());
		if (reqVO.getContactPhone() != null) shop.setContactPhone(reqVO.getContactPhone());
		if (reqVO.getCategory() != null) shop.setCategory(reqVO.getCategory());
		if (reqVO.getAddress() != null) shop.setAddress(reqVO.getAddress());
		if (reqVO.getFollowCount() != null) shop.setFollowCount(reqVO.getFollowCount());
		if (reqVO.getViews() != null) shop.setViews(reqVO.getViews());
		if (reqVO.getLevel() != null) shop.setLevel(reqVO.getLevel());
		if (reqVO.getRating() != null) shop.setRating(reqVO.getRating());
		if (reqVO.getCreditScore() != null) shop.setCreditScore(reqVO.getCreditScore());

		shopMapper.updateById(shop);

		// 处理订单数和销售额（保存到shop_statistics表）
		if (reqVO.getOrderCount() != null || reqVO.getSalesAmount() != null) {
			LocalDate today = LocalDate.now();
			LambdaQueryWrapper<ShopStatistics> wrapper = new LambdaQueryWrapper<>();
			wrapper.eq(ShopStatistics::getShopId, shopId);
			wrapper.eq(ShopStatistics::getStatDate, today);
			ShopStatistics statistics = shopStatisticsMapper.selectOne(wrapper);

			if (statistics == null) {
				statistics = new ShopStatistics();
				statistics.setShopId(shopId);
				statistics.setStatDate(today);
				statistics.setOrderCount(reqVO.getOrderCount() != null ? Math.min(reqVO.getOrderCount(), 100000) : 0);
				BigDecimal salesAmount = BigDecimal.ZERO;
				if (reqVO.getSalesAmount() != null) {
					BigDecimal maxSales = new BigDecimal("40000000");
					salesAmount = reqVO.getSalesAmount() > maxSales.doubleValue() ? maxSales : BigDecimal.valueOf(reqVO.getSalesAmount());
				}
				statistics.setSalesAmount(salesAmount);
				statistics.setProfitRate(new BigDecimal("20"));
				statistics.setProfitAmount(salesAmount.multiply(new BigDecimal("20")).divide(new BigDecimal("100"), 2, java.math.RoundingMode.HALF_UP));
				shopStatisticsMapper.insert(statistics);
			} else {
				if (reqVO.getOrderCount() != null) {
					statistics.setOrderCount(Math.min(reqVO.getOrderCount(), 100000));
				}
				if (reqVO.getSalesAmount() != null) {
					BigDecimal maxSales = new BigDecimal("40000000");
					BigDecimal salesAmount = reqVO.getSalesAmount() > maxSales.doubleValue() ? maxSales : BigDecimal.valueOf(reqVO.getSalesAmount());
					statistics.setSalesAmount(salesAmount);
					statistics.setProfitAmount(salesAmount.multiply(statistics.getProfitRate()).divide(new BigDecimal("100"), 2, java.math.RoundingMode.HALF_UP));
				}
				shopStatisticsMapper.updateById(statistics);
			}
		}

		log.info("更新店铺信息成功: shopId={}", shopId);
	}

	/**
	 * 管理员解除店铺因超时未支付产生的商家页面限制。
	 *
	 * @param shopId 店铺ID
	 * @param operatorUserId 操作人用户ID，必须是管理员
	 */
	@Override
	public void unlockPaymentLock(Long shopId, Long operatorUserId) {
		User operator = userMapper.selectById(operatorUserId);
		if (operator == null || operator.getRole() == null || !"ADMIN".equalsIgnoreCase(operator.getRole())) {
			throw new CustomException(ResultCode.PERMISSION_DENIED);
		}
		orderService.unlockSellerPaymentLock(shopId);
		log.info("管理员解除店铺支付超时限制: shopId={}, operatorUserId={}", shopId, operatorUserId);
	}
}
