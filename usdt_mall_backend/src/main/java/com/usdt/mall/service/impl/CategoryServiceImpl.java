package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.usdt.mall.entity.Category;
import com.usdt.mall.mapper.CategoryMapper;
import com.usdt.mall.service.CategoryService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 分类Service实现类
 */
@Service
public class CategoryServiceImpl implements CategoryService {

	@Resource
	private CategoryMapper categoryMapper;

	@Override
	public List<Category> getAllCategories() {
		LambdaQueryWrapper<Category> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Category::getStatus, 1);
		wrapper.orderByAsc(Category::getSort);
		return categoryMapper.selectList(wrapper);
	}
}
