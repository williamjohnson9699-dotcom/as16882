package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.HomeService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 首页控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/home")
public class HomeController {

	@Autowired
	private HomeService homeService;

	/**
	 * 获取热卖商品
	 */
	@GetMapping("/hot-products")
	public Result<Map<String, Object>> getHotProducts(
			@RequestParam(required = false) Integer limit,
			@RequestParam(required = false) Integer page,
			@RequestParam(required = false) Integer pageSize
	) {
		try {
			// 如果提供了分页参数，使用分页查询
			if (page != null && pageSize != null) {
				Map<String, Object> result = homeService.getHotProductsWithPagination(page, pageSize);
				return Result.successWith(result);
			}
			// 否则使用原有的limit查询
			if (limit == null) {
				limit = 30;
			}
			Map<String, Object> result = homeService.getHotProducts(limit);
			return Result.successWith(result);
		} catch (Exception e) {
			log.error("获取热卖商品失败", e);
			return Result.<Map<String, Object>>error().newCnMsg("获取热卖商品失败: " + e.getMessage());
		}
	}

	/**
	 * 获取每日新发现商品
	 */
	@GetMapping("/daily-discover")
	public Result<Map<String, Object>> getDailyDiscover(
			@RequestParam(defaultValue = "8") Integer limit
	) {
		try {
			Map<String, Object> result = homeService.getDailyDiscover(limit);
			return Result.successWith(result);
		} catch (Exception e) {
			log.error("获取每日新发现失败", e);
			return Result.<Map<String, Object>>error().newCnMsg("获取每日新发现失败: " + e.getMessage());
		}
	}
}
