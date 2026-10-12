package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.SystemConfig;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.SystemConfigMapper;
import com.usdt.mall.service.SystemConfigService;
import com.usdt.mall.util.DateTimeUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 系统配置服务实现�?
 */
@Slf4j
@Service
public class SystemConfigServiceImpl implements SystemConfigService {

	@Autowired
	private SystemConfigMapper systemConfigMapper;

	@Override
	public Integer getProfitRate() {
		QueryWrapper<SystemConfig> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("config_key", "profit_rate");
		SystemConfig config = systemConfigMapper.selectOne(queryWrapper);

		if (config != null) {
			try {
				return Integer.parseInt(config.getConfigValue());
			} catch (NumberFormatException e) {
				log.error("利润率配置值格式错�? {}", config.getConfigValue(), e);
				return 65; // 返回默认�?
			}
		}

		return 65; // 返回默认�?
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateProfitRate(Integer profitRate) {
		if (profitRate == null || profitRate < 0 || profitRate > 100) {
			throw new CustomException(ResultCode.PROFIT_RATE_INVALID);
		}

		QueryWrapper<SystemConfig> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("config_key", "profit_rate");
		SystemConfig config = systemConfigMapper.selectOne(queryWrapper);

		if (config != null) {
			config.setConfigValue(String.valueOf(profitRate));
			config.setUpdateTime(DateTimeUtil.nowUtc());
			systemConfigMapper.updateById(config);
		} else {
			// 如果配置不存在，创建新配�?
			config = new SystemConfig();
			config.setConfigKey("profit_rate");
			config.setConfigValue(String.valueOf(profitRate));
			config.setConfigDesc("利润率（百分比）");
			config.setCreateTime(DateTimeUtil.nowUtc());
			config.setUpdateTime(DateTimeUtil.nowUtc());
			systemConfigMapper.insert(config);
		}

		log.info("更新利润率配置成�? {}", profitRate);
	}

	@Override
	public Map<String, String> getAllConfigs() {
		List<SystemConfig> configs = systemConfigMapper.selectList(null);
		Map<String, String> result = new HashMap<>();

		for (SystemConfig config : configs) {
			result.put(config.getConfigKey(), config.getConfigValue());
		}

		return result;
	}

	@Override
	public String getReceivingAddress() {
		QueryWrapper<SystemConfig> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("config_key", "receiving_address");
		SystemConfig config = systemConfigMapper.selectOne(queryWrapper);
		return config != null ? config.getConfigValue() : "";
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateReceivingAddress(String address) {
		QueryWrapper<SystemConfig> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("config_key", "receiving_address");
		SystemConfig config = systemConfigMapper.selectOne(queryWrapper);

		if (config != null) {
			config.setConfigValue(address);
			config.setUpdateTime(DateTimeUtil.nowUtc());
			systemConfigMapper.updateById(config);
		} else {
			config = new SystemConfig();
			config.setConfigKey("receiving_address");
			config.setConfigValue(address);
			config.setConfigDesc("系统收款地址");
			config.setCreateTime(DateTimeUtil.nowUtc());
			config.setUpdateTime(DateTimeUtil.nowUtc());
			systemConfigMapper.insert(config);
		}

		log.info("更新收款地址成功: {}", address);
	}
}
