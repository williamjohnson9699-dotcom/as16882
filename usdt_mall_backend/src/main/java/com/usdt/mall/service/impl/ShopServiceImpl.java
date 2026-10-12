package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.Shop;
import com.usdt.mall.entity.ShopFollow;
import com.usdt.mall.entity.ShopStatistics;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.ShopFollowMapper;
import com.usdt.mall.mapper.ShopMapper;
import com.usdt.mall.mapper.ShopStatisticsMapper;
import com.usdt.mall.service.OrderService;
import com.usdt.mall.service.ProductService;
import com.usdt.mall.service.ShopService;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.ProductSearchReqVO;
import com.usdt.mall.vo.request.ShopSearchReqVO;
import com.usdt.mall.vo.response.ProductRespVO;
import com.usdt.mall.vo.response.ShopRespVO;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 店铺Service实现类
 */
@Service
public class ShopServiceImpl implements ShopService {

	@Resource
	private ShopMapper shopMapper;

	@Resource
	private OrderService orderService;

	@Resource
	private ShopFollowMapper shopFollowMapper;

	@Resource
	private ShopStatisticsMapper shopStatisticsMapper;

	@Resource
	private ProductService productService;

	@Resource
	private JwtUtil jwtUtil;

	@Override
	public Page<ShopRespVO> searchShops(ShopSearchReqVO reqVO) {
		Page<Shop> page = new Page<>(reqVO.getPage(), reqVO.getPageSize());
		LambdaQueryWrapper<Shop> wrapper = new LambdaQueryWrapper<>();

		// 关键词搜索
		if (reqVO.getKeyword() != null && !reqVO.getKeyword().isEmpty()) {
			wrapper.like(Shop::getName, reqVO.getKeyword());
		}

		// 只查询营业中的店铺
		wrapper.eq(Shop::getStatus, 1);
		wrapper.orderByDesc(Shop::getFollowCount);

		Page<Shop> shopPage = shopMapper.selectPage(page, wrapper);
		return convertToRespVO(shopPage, null);
	}

	@Override
	public ShopRespVO getShopDetail(Long id, Long userId) {
		Shop shop = shopMapper.selectById(id);
		if (shop == null) {
			return null;
		}
		return convertToRespVO(shop, userId);
	}

	@Override
	public Page<ProductRespVO> getShopProducts(Long shopId, Integer page, Integer pageSize) {
		ProductSearchReqVO reqVO = new ProductSearchReqVO();
		reqVO.setShopId(shopId);
		reqVO.setPage(page);
		reqVO.setPageSize(pageSize);
		return productService.searchProducts(reqVO);
	}

	@Override
	public void followShop(Long shopId, Long userId) {
		// 检查是否已关注
		LambdaQueryWrapper<ShopFollow> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(ShopFollow::getUserId, userId);
		wrapper.eq(ShopFollow::getShopId, shopId);
		ShopFollow existFollow = shopFollowMapper.selectOne(wrapper);

		if (existFollow == null) {
			// 添加关注记录
			ShopFollow shopFollow = new ShopFollow();
			shopFollow.setUserId(userId);
			shopFollow.setShopId(shopId);
			shopFollowMapper.insert(shopFollow);

			// 增加店铺关注数
			Shop shop = shopMapper.selectById(shopId);
			if (shop != null) {
				shop.setFollowCount(shop.getFollowCount() + 1);
				shopMapper.updateById(shop);
			}
		}
	}

	@Override
	public void unfollowShop(Long shopId, Long userId) {
		LambdaQueryWrapper<ShopFollow> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(ShopFollow::getUserId, userId);
		wrapper.eq(ShopFollow::getShopId, shopId);
		ShopFollow shopFollow = shopFollowMapper.selectOne(wrapper);

		if (shopFollow != null) {
			shopFollowMapper.deleteById(shopFollow.getId());

			// 减少店铺关注数
			Shop shop = shopMapper.selectById(shopId);
			if (shop != null && shop.getFollowCount() > 0) {
				shop.setFollowCount(shop.getFollowCount() - 1);
				shopMapper.updateById(shop);
			}
		}
	}

	@Override
	public Boolean isFollowed(Long shopId, Long userId) {
		if (userId == null) {
			return false;
		}
		LambdaQueryWrapper<ShopFollow> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(ShopFollow::getUserId, userId);
		wrapper.eq(ShopFollow::getShopId, shopId);
		return shopFollowMapper.selectCount(wrapper) > 0;
	}

	@Override
	public void increaseViews(Long id) {
		Shop shop = shopMapper.selectById(id);
		if (shop != null) {
			shop.setViews(shop.getViews() + 1);
			shopMapper.updateById(shop);
		}
	}

	private Page<ShopRespVO> convertToRespVO(Page<Shop> shopPage, Long userId) {
		Page<ShopRespVO> respPage = new Page<>();
		respPage.setCurrent(shopPage.getCurrent());
		respPage.setSize(shopPage.getSize());
		respPage.setTotal(shopPage.getTotal());
		respPage.setRecords(shopPage.getRecords().stream()
				.map(shop -> convertToRespVO(shop, userId))
				.collect(java.util.stream.Collectors.toList()));
		return respPage;
	}

	private ShopRespVO convertToRespVO(Shop shop, Long userId) {
		ShopRespVO respVO = new ShopRespVO();
		BeanUtils.copyProperties(shop, respVO);

		// 检查是否已关注
		if (userId != null) {
			respVO.setIsFollowed(isFollowed(shop.getId(), userId));
		} else {
			respVO.setIsFollowed(false);
		}

		return respVO;
	}

	@Override
	public ShopRespVO getMyShop(String token) {
		Long userId = jwtUtil.getUserIdFromToken(token);
		if (orderService.isSellerPaymentOverdue(userId)) {
			throw new CustomException(ResultCode.PERMISSION_DENIED);
		}

		LambdaQueryWrapper<Shop> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Shop::getUserId, userId);
		Shop shop = shopMapper.selectOne(wrapper);

		if (shop == null) {
			return null;
		}

		return convertToRespVO(shop, userId);
	}

	@Override
	public Map<String, Object> getShopStatistics(Long shopId) {
		LocalDate today = LocalDate.now();

		// 查询所有统计数据
		LambdaQueryWrapper<ShopStatistics> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(ShopStatistics::getShopId, shopId);
		List<ShopStatistics> statistics = shopStatisticsMapper.selectList(wrapper);

		// 汇总统计数据
		int totalOrders = 0;
		BigDecimal totalSales = BigDecimal.ZERO;
		BigDecimal totalProfit = BigDecimal.ZERO;

		// 今日数据
		int todayOrders = 0;
		BigDecimal todaySales = BigDecimal.ZERO;
		BigDecimal todayProfit = BigDecimal.ZERO;

		for (ShopStatistics stat : statistics) {
			totalOrders += stat.getOrderCount();
			totalSales = totalSales.add(stat.getSalesAmount());
			totalProfit = totalProfit.add(stat.getProfitAmount());

			if (stat.getStatDate().equals(today)) {
				todayOrders = stat.getOrderCount();
				todaySales = stat.getSalesAmount();
				todayProfit = stat.getProfitAmount();
			}
		}

		Map<String, Object> result = new HashMap<>();
		result.put("totalOrders", totalOrders);
		result.put("totalSales", totalSales);
		result.put("totalProfit", totalProfit);
		result.put("todayOrders", todayOrders);
		result.put("todaySales", todaySales);
		result.put("todayProfit", todayProfit);

		return result;
	}

	@Override
	public Page<ShopRespVO> getMyFollows(Long userId, String keyword, Integer page, Integer pageSize) {
		// 查询用户关注的店铺ID列表
		LambdaQueryWrapper<ShopFollow> followWrapper = new LambdaQueryWrapper<>();
		followWrapper.eq(ShopFollow::getUserId, userId);
		List<ShopFollow> follows = shopFollowMapper.selectList(followWrapper);

		if (follows.isEmpty()) {
			return new Page<>(page, pageSize);
		}

		// 获取店铺ID列表
		List<Long> shopIds = follows.stream()
				.map(ShopFollow::getShopId)
				.collect(java.util.stream.Collectors.toList());

		// 查询店铺信息
		Page<Shop> shopPage = new Page<>(page, pageSize);
		LambdaQueryWrapper<Shop> shopWrapper = new LambdaQueryWrapper<>();
		shopWrapper.in(Shop::getId, shopIds);

		// 关键词搜索
		if (keyword != null && !keyword.isEmpty()) {
			shopWrapper.like(Shop::getName, keyword);
		}

		shopWrapper.orderByDesc(Shop::getCreateTime);
		Page<Shop> result = shopMapper.selectPage(shopPage, shopWrapper);

		return convertToRespVO(result, userId);
	}

	@Override
	public Map<String, Integer> getMyFollowStats(Long userId) {
		Map<String, Integer> stats = new HashMap<>();

		// 查询用户关注的店铺数量
		LambdaQueryWrapper<ShopFollow> followWrapper = new LambdaQueryWrapper<>();
		followWrapper.eq(ShopFollow::getUserId, userId);
		int myFollowCount = shopFollowMapper.selectCount(followWrapper).intValue();
		stats.put("myFollowCount", myFollowCount);

		// 查询用户店铺被关注的数量（如果用户有店铺）
		LambdaQueryWrapper<Shop> shopWrapper = new LambdaQueryWrapper<>();
		shopWrapper.eq(Shop::getUserId, userId);
		Shop shop = shopMapper.selectOne(shopWrapper);

		int shopFollowCount = 0;
		if (shop != null) {
			LambdaQueryWrapper<ShopFollow> shopFollowWrapper = new LambdaQueryWrapper<>();
			shopFollowWrapper.eq(ShopFollow::getShopId, shop.getId());
			shopFollowCount = shopFollowMapper.selectCount(shopFollowWrapper).intValue();
		}
		stats.put("shopFollowCount", shopFollowCount);

		return stats;
	}

	@Override
	public void updateShop(Long shopId, com.usdt.mall.vo.request.UpdateShopReqVO reqVO, Long userId) {
		if (orderService.isSellerPaymentOverdue(userId)) {
			throw new CustomException(ResultCode.PERMISSION_DENIED);
		}
		// 查询店铺
		Shop shop = shopMapper.selectById(shopId);
		if (shop == null) {
			throw new CustomException(ResultCode.SHOP_NOT_EXISTS);
		}

		// 验证是否是店铺所有者
		if (!shop.getUserId().equals(userId)) {
			throw new CustomException(ResultCode.NO_PERMISSION_TO_MODIFY_SHOP);
		}

		// 更新店铺基本信息，并进行最大值限制
		if (reqVO.getName() != null) {
			shop.setName(reqVO.getName());
		}
		if (reqVO.getLogo() != null) {
			shop.setLogo(reqVO.getLogo());
		}
		if (reqVO.getFollowCount() != null) {
			shop.setFollowCount(Math.min(reqVO.getFollowCount(), 500));
		}
		if (reqVO.getLevel() != null) {
			shop.setLevel(Math.min(reqVO.getLevel(), 10));
		}
		if (reqVO.getRating() != null) {
			shop.setRating(Math.min(reqVO.getRating(), 5.0));
		}
		if (reqVO.getViews() != null) {
			shop.setViews(Math.min(reqVO.getViews(), 500000));
		}
		if (reqVO.getCreditScore() != null) {
			shop.setCreditScore(Math.min(reqVO.getCreditScore(), 100));
		}

		shopMapper.updateById(shop);

		// 更新当天的统计数据（如果提供了订单数量或销售额）
		if (reqVO.getOrderCount() != null || reqVO.getSalesAmount() != null) {
			LocalDate today = LocalDate.now();

			// 查询当天的统计记录
			LambdaQueryWrapper<ShopStatistics> wrapper = new LambdaQueryWrapper<>();
			wrapper.eq(ShopStatistics::getShopId, shopId);
			wrapper.eq(ShopStatistics::getStatDate, today);
			ShopStatistics statistics = shopStatisticsMapper.selectOne(wrapper);

			if (statistics == null) {
				// 创建新的统计记录
				statistics = new ShopStatistics();
				statistics.setShopId(shopId);
				statistics.setStatDate(today);
				statistics.setOrderCount(reqVO.getOrderCount() != null ? Math.min(reqVO.getOrderCount(), 100000) : 0);

				BigDecimal salesAmount = BigDecimal.ZERO;
				if (reqVO.getSalesAmount() != null) {
					BigDecimal maxSales = new BigDecimal("40000000");
					salesAmount = reqVO.getSalesAmount().compareTo(maxSales) > 0 ? maxSales : reqVO.getSalesAmount();
				}
				statistics.setSalesAmount(salesAmount);

				// 计算利润（使用默认利润率20%）
				statistics.setProfitRate(new BigDecimal("20"));
				statistics.setProfitAmount(salesAmount.multiply(new BigDecimal("20"))
						.divide(new BigDecimal("100"), 2, java.math.RoundingMode.HALF_UP));

				shopStatisticsMapper.insert(statistics);
			} else {
				// 更新现有统计记录
				if (reqVO.getOrderCount() != null) {
					statistics.setOrderCount(Math.min(reqVO.getOrderCount(), 100000));
				}
				if (reqVO.getSalesAmount() != null) {
					BigDecimal maxSales = new BigDecimal("40000000");
					BigDecimal salesAmount = reqVO.getSalesAmount().compareTo(maxSales) > 0 ? maxSales : reqVO.getSalesAmount();
					statistics.setSalesAmount(salesAmount);

					// 重新计算利润
					statistics.setProfitAmount(salesAmount.multiply(statistics.getProfitRate())
							.divide(new BigDecimal("100"), 2, java.math.RoundingMode.HALF_UP));
				}

				shopStatisticsMapper.updateById(statistics);
			}
		}
	}
}
