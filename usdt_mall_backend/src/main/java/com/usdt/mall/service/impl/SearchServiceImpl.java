package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.entity.Category;
import com.usdt.mall.entity.Product;
import com.usdt.mall.entity.Shop;
import com.usdt.mall.entity.User;
import com.usdt.mall.mapper.CategoryMapper;
import com.usdt.mall.mapper.ProductMapper;
import com.usdt.mall.mapper.ShopMapper;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.service.SearchService;
import com.usdt.mall.util.ProductMainImageResolver;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 搜索服务实现类
 */
@Slf4j
@Service
public class SearchServiceImpl implements SearchService {

	@Autowired
	private ProductMapper productMapper;

	@Autowired
	private ShopMapper shopMapper;

	@Autowired
	private CategoryMapper categoryMapper;

	@Autowired
	private UserMapper userMapper;

	@Autowired
	private ProductMainImageResolver productMainImageResolver;

	@Override
	public Map<String, Object> searchProducts(String keyword, Integer page, Integer pageSize) {
		// 构建查询条件
		QueryWrapper<Product> queryWrapper = new QueryWrapper<>();

		if (keyword != null && !keyword.trim().isEmpty()) {
			queryWrapper.like("name", keyword.trim());
		}

		// 按创建时间倒序排列
		queryWrapper.orderByDesc("create_time");

		// 分页查询
		Page<Product> productPage = new Page<>(page, pageSize);
		IPage<Product> result = productMapper.selectPage(productPage, queryWrapper);

		// 转换为响应数据
		List<Map<String, Object>> productList = result.getRecords().stream()
				.map(this::convertProductToMap)
				.collect(Collectors.toList());

		// 构建返回结果
		Map<String, Object> response = new HashMap<>();
		response.put("list", productList);
		response.put("total", result.getTotal());
		response.put("page", result.getCurrent());
		response.put("pageSize", result.getSize());
		response.put("totalPages", result.getPages());

		return response;
	}

	@Override
	public Map<String, Object> searchShops(String keyword, Integer page, Integer pageSize) {
		// 构建查询条件
		QueryWrapper<Shop> queryWrapper = new QueryWrapper<>();

		// 只查询状态为1（营业中）的店铺
		queryWrapper.eq("status", 1);

		// 关键词搜索
		if (keyword != null && !keyword.trim().isEmpty()) {
			queryWrapper.like("name", keyword.trim());
		}

		// 按创建时间倒序排列
		queryWrapper.orderByDesc("create_time");

		// 分页查询
		Page<Shop> shopPage = new Page<>(page, pageSize);
		IPage<Shop> result = shopMapper.selectPage(shopPage, queryWrapper);

		// 转换为响应数据
		List<Map<String, Object>> shopList = result.getRecords().stream()
				.map(this::convertShopToMap)
				.collect(Collectors.toList());

		// 构建返回结果
		Map<String, Object> response = new HashMap<>();
		response.put("list", shopList);
		response.put("total", result.getTotal());
		response.put("page", result.getCurrent());
		response.put("pageSize", result.getSize());
		response.put("totalPages", result.getPages());

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
		map.put("image", productMainImageResolver.resolve(product));
		map.put("description", product.getDescription());

		// 获取分类名称
		if (product.getCategoryId() != null) {
			Category category = categoryMapper.selectById(product.getCategoryId());
			if (category != null) {
				map.put("categoryName", category.getName());
			}
		}

		return map;
	}

	/**
	 * 转换店铺为Map
	 */
	private Map<String, Object> convertShopToMap(Shop shop) {
		Map<String, Object> map = new HashMap<>();
		map.put("id", shop.getId());
		map.put("name", shop.getName());
		map.put("logo", shop.getLogo());
		map.put("category", shop.getCategory());
		map.put("status", shop.getStatus());

		// 获取店主昵称
		if (shop.getUserId() != null) {
			User user = userMapper.selectById(shop.getUserId());
			if (user != null) {
				map.put("ownerNickname", user.getNickname());
			}
		}

		return map;
	}
}
