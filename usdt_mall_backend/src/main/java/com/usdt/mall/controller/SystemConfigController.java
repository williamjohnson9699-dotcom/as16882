package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.SystemConfigService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Tag(name = "系统配置管理", description = "系统配置管理相关接口")
@RestController
@RequestMapping("/api/v1/system-config")
public class SystemConfigController {

	@Autowired
	private SystemConfigService systemConfigService;

	@Operation(summary = "获取利润率配置", description = "获取当前系统利润率配置")
	@GetMapping("/profit-rate")
	public Result<Integer> getProfitRate() {
		Integer profitRate = systemConfigService.getProfitRate();
		return Result.successWith(profitRate);
	}

	@Operation(summary = "更新利润率配置", description = "更新系统利润率配置")
	@PutMapping("/profit-rate")
	public Result<?> updateProfitRate(@RequestBody Map<String, Object> params) {
		Integer profitRate = (Integer) params.get("profitRate");
		systemConfigService.updateProfitRate(profitRate);
		return Result.success();
	}

	@Operation(summary = "获取所有系统配置", description = "获取所有系统配置")
	@GetMapping("/all")
	public Result<Map<String, String>> getAllConfigs() {
		Map<String, String> configs = systemConfigService.getAllConfigs();
		return Result.successWith(configs);
	}

	@Operation(summary = "获取收款地址", description = "获取系统收款地址配置")
	@GetMapping("/receiving-address")
	public Result<String> getReceivingAddress() {
		String address = systemConfigService.getReceivingAddress();
		return Result.successWith(address);
	}

	@Operation(summary = "更新收款地址", description = "更新系统收款地址配置")
	@PutMapping("/receiving-address")
	public Result<?> updateReceivingAddress(@RequestBody Map<String, Object> params) {
		String address = (String) params.get("receivingAddress");
		systemConfigService.updateReceivingAddress(address);
		return Result.success();
	}
}
