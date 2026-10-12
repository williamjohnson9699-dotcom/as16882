package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.service.SearchService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Tag(name = "搜索", description = "商品和店铺搜索相关接口")
@RestController
@RequestMapping("/api/v1/search")
public class SearchController {

	@Autowired
	private SearchService searchService;

	@Operation(summary = "搜索商品", description = "根据关键词搜索商品")
	@PostMapping("/products")
	public Result<Map<String, Object>> searchProducts(@RequestBody Map<String, Object> params) {
		String keyword = (String) params.get("keyword");
		Integer page = params.get("page") != null ? (Integer) params.get("page") : 1;
		Integer pageSize = params.get("pageSize") != null ? (Integer) params.get("pageSize") : 12;

		Map<String, Object> result = searchService.searchProducts(keyword, page, pageSize);
		return Result.successWith(result);
	}

	@Operation(summary = "搜索店铺", description = "根据关键词搜索店铺")
	@PostMapping("/shops")
	public Result<Map<String, Object>> searchShops(@RequestBody Map<String, Object> params) {
		String keyword = (String) params.get("keyword");
		Integer page = params.get("page") != null ? (Integer) params.get("page") : 1;
		Integer pageSize = params.get("pageSize") != null ? (Integer) params.get("pageSize") : 12;

		Map<String, Object> result = searchService.searchShops(keyword, page, pageSize);
		return Result.successWith(result);
	}
}
