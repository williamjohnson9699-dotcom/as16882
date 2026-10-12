package com.usdt.mall.service;

import com.usdt.mall.entity.Category;

import java.util.List;

/**
 * 分类Service接口
 */
public interface CategoryService {

	/**
	 * 获取所有分类列表
	 */
	List<Category> getAllCategories();
}
