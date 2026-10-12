package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.entity.Category;
import com.usdt.mall.service.CategoryService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import java.util.List;

/**
 * 分类Controller
 */
@RestController
@RequestMapping("/api/v1/category")
public class CategoryController {

	@Resource
	private CategoryService categoryService;

	/**
	 * 获取所有分类列表
	 */
	@GetMapping("/list")
	public Result<List<Category>> getAllCategories() {
		List<Category> categories = categoryService.getAllCategories();
		return Result.successWith(categories);
	}
}
