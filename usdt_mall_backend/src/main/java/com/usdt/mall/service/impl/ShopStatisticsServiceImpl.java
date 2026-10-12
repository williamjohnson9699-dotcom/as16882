package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.usdt.mall.entity.ShopStatistics;
import com.usdt.mall.entity.SystemConfig;
import com.usdt.mall.mapper.ShopStatisticsMapper;
import com.usdt.mall.mapper.SystemConfigMapper;
import com.usdt.mall.service.ShopStatisticsService;
import com.usdt.mall.util.DateTimeUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;

/**
 * 店铺统计服务实现�?
 */
@Slf4j
@Service
public class ShopStatisticsServiceImpl implements ShopStatisticsService {

	@Resource
	private ShopStatisticsMapper shopStatisticsMapper;

	@Resource
	private SystemConfigMapper systemConfigMapper;

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateStatistics(Long shopId, BigDecimal orderAmount) {
		if (shopId == null || orderAmount == null) {
			log.warn("店铺ID或订单金额为空，跳过统计更新");
			return;
		}

		LocalDate today = LocalDate.now();

		// 查询当天的统计记�?
		LambdaQueryWrapper<ShopStatistics> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(ShopStatistics::getShopId, shopId);
		queryWrapper.eq(ShopStatistics::getStatDate, today);
		ShopStatistics statistics = shopStatisticsMapper.selectOne(queryWrapper);

		// 获取系统配置的利润率
		BigDecimal profitRate = getProfitRate();

		if (statistics == null) {
			// 创建新的统计记录
			statistics = new ShopStatistics();
			statistics.setShopId(shopId);
			statistics.setStatDate(today);
			statistics.setOrderCount(1);
			statistics.setSalesAmount(orderAmount);
			statistics.setProfitRate(profitRate);

			// 计算利润: 销售额 * 利润�?
			BigDecimal profitAmount = orderAmount.multiply(profitRate)
					.divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP);
			statistics.setProfitAmount(profitAmount);

			statistics.setCreateTime(DateTimeUtil.nowUtc());
			statistics.setUpdateTime(DateTimeUtil.nowUtc());

			shopStatisticsMapper.insert(statistics);
			log.info("创建店铺统计记录: shopId={}, date={}, orderCount=1, salesAmount={}, profitAmount={}",
					shopId, today, orderAmount, profitAmount);
		} else {
			// 更新现有统计记录
			statistics.setOrderCount(statistics.getOrderCount() + 1);
			statistics.setSalesAmount(statistics.getSalesAmount().add(orderAmount));
			statistics.setProfitRate(profitRate);

			// 重新计算利润: 销售额 * 利润�?
			BigDecimal profitAmount = statistics.getSalesAmount().multiply(profitRate)
					.divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP);
			statistics.setProfitAmount(profitAmount);

			statistics.setUpdateTime(DateTimeUtil.nowUtc());

			shopStatisticsMapper.updateById(statistics);
			log.info("更新店铺统计记录: shopId={}, date={}, orderCount={}, salesAmount={}, profitAmount={}",
					shopId, today, statistics.getOrderCount(), statistics.getSalesAmount(), profitAmount);
		}
	}

	/**
	 * 获取系统配置的利润率
	 */
	private BigDecimal getProfitRate() {
		LambdaQueryWrapper<SystemConfig> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(SystemConfig::getConfigKey, "profit_rate");
		SystemConfig config = systemConfigMapper.selectOne(queryWrapper);

		if (config != null && config.getConfigValue() != null) {
			try {
				return new BigDecimal(config.getConfigValue());
			} catch (NumberFormatException e) {
				log.error("利润率配置值格式错�? {}", config.getConfigValue(), e);
			}
		}

		// 默认利润�?20%
		log.warn("未找到利润率配置，使用默认�?20%");
		return new BigDecimal("20");
	}
}
