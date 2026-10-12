package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.entity.Category;
import com.usdt.mall.entity.Product;
import com.usdt.mall.mapper.CategoryMapper;
import com.usdt.mall.mapper.ProductMapper;
import com.usdt.mall.service.HomeService;
import com.usdt.mall.util.ProductMainImageResolver;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 首页服务实现类
 */
@Slf4j
@Service
public class HomeServiceImpl implements HomeService {

	@Autowired
	private ProductMapper productMapper;

	@Autowired
	private CategoryMapper categoryMapper;

	@Autowired
	private ProductMainImageResolver productMainImageResolver;

	@Override
	public Map<String, Object> getHotProducts(Integer limit) {
		// 构建查询条件：按销量倒序
		QueryWrapper<Product> queryWrapper = new QueryWrapper<>();
		queryWrapper.orderByDesc("sales");
		queryWrapper.last("LIMIT " + limit);

		List<Product> products = productMapper.selectList(queryWrapper);

		// 转换为响应数据
		List<Map<String, Object>> productList = products.stream()
				.map(this::convertProductToMap)
				.collect(Collectors.toList());

		Map<String, Object> response = new HashMap<>();
		response.put("list", productList);
		response.put("total", productList.size());

		return response;
	}

	@Override
	public Map<String, Object> getHotProductsWithPagination(Integer page, Integer pageSize) {
		// 构建分页对象
		Page<Product> pageObj = new Page<>(page, pageSize);

		// 构建查询条件：按销量倒序
		QueryWrapper<Product> queryWrapper = new QueryWrapper<>();
		queryWrapper.orderByDesc("sales");

		// 执行分页查询
		IPage<Product> productPage = productMapper.selectPage(pageObj, queryWrapper);

		// 转换为响应数据
		List<Map<String, Object>> productList = productPage.getRecords().stream()
				.map(this::convertProductToMap)
				.collect(Collectors.toList());

		// 构建分页响应
		Map<String, Object> response = new HashMap<>();
		response.put("records", productList);
		response.put("total", productPage.getTotal());
		response.put("size", productPage.getSize());
		response.put("current", productPage.getCurrent());
		response.put("pages", productPage.getPages());

		return response;
	}

	@Override
	public Map<String, Object> getDailyDiscover(Integer limit) {
		// 构建查询条件：按创建时间倒序
		QueryWrapper<Product> queryWrapper = new QueryWrapper<>();
		queryWrapper.orderByDesc("create_time");
		queryWrapper.last("LIMIT " + limit);

		List<Product> products = productMapper.selectList(queryWrapper);

		// 转换为响应数据
		List<Map<String, Object>> productList = products.stream()
				.map(this::convertProductToMap)
				.collect(Collectors.toList());

		Map<String, Object> response = new HashMap<>();
		response.put("list", productList);
		response.put("total", productList.size());

		return response;
	}

	/**
	 * 转换商品为Map
	 */
	private Map<String, Object> convertProductToMap(Product product) {
		Map<String, Object> map = new HashMap<>();
		map.put("id", product.getId());
		map.put("name", product.getName());
		map.put("price", product.getPrice());
		map.put("mainImage", productMainImageResolver.resolve(product));
		map.put("description", product.getDescription());
		map.put("sales", product.getSales());

		// 获取分类名称
		if (product.getCategoryId() != null) {
			Category category = categoryMapper.selectById(product.getCategoryId());
			if (category != null) {
				map.put("categoryName", category.getName());
			}
		}

		return map;
	}
}
