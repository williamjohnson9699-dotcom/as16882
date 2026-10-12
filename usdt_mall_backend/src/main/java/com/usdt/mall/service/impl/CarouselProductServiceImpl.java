package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.CarouselProduct;
import com.usdt.mall.entity.Product;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.CarouselProductMapper;
import com.usdt.mall.mapper.ProductMapper;
import com.usdt.mall.service.CarouselProductService;
import com.usdt.mall.util.DateTimeUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 轮播商品服务实现�?
 */
@Slf4j
@Service
public class CarouselProductServiceImpl implements CarouselProductService {

	@Autowired
	private CarouselProductMapper carouselProductMapper;

	@Autowired
	private ProductMapper productMapper;

	@Override
	public List<Map<String, Object>> getCarouselProducts() {
		// 查询所有轮播商品，按排序顺�?
		QueryWrapper<CarouselProduct> queryWrapper = new QueryWrapper<>();
		queryWrapper.orderByAsc("sort_order");
		List<CarouselProduct> carouselProducts = carouselProductMapper.selectList(queryWrapper);

		List<Map<String, Object>> result = new ArrayList<>();
		for (CarouselProduct carouselProduct : carouselProducts) {
			// 查询商品信息
			Product product = productMapper.selectById(carouselProduct.getProductId());
			if (product != null) {
				Map<String, Object> map = new HashMap<>();
				map.put("id", carouselProduct.getId());
				map.put("productId", product.getId());
				map.put("productName", product.getName());
				map.put("productPrice", product.getPrice());
				map.put("productImage", product.getMainImage());
				map.put("sortOrder", carouselProduct.getSortOrder());
				result.add(map);
			}
		}

		return result;
	}

	@Override
	public List<Map<String, Object>> getAllProducts() {
		// 查询所有商�?
		QueryWrapper<Product> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("status", 1); // 只查询上架的商品
		queryWrapper.orderByDesc("create_time");
		List<Product> products = productMapper.selectList(queryWrapper);

		List<Map<String, Object>> result = new ArrayList<>();
		for (Product product : products) {
			Map<String, Object> map = new HashMap<>();
			map.put("id", product.getId());
			map.put("name", product.getName());
			map.put("price", product.getPrice());
			map.put("mainImage", product.getMainImage());
			result.add(map);
		}

		return result;
	}

	@Override
	public Map<String, Object> searchProducts(String keyword, Integer page, Integer pageSize) {
		// 获取已经在轮播中的商品ID列表
		QueryWrapper<CarouselProduct> carouselWrapper = new QueryWrapper<>();
		List<CarouselProduct> carouselProducts = carouselProductMapper.selectList(carouselWrapper);
		List<Long> carouselProductIds = carouselProducts.stream()
				.map(CarouselProduct::getProductId)
				.collect(java.util.stream.Collectors.toList());

		// 构建查询条件
		QueryWrapper<Product> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("status", 1); // 只查询上架的商品

		// 过滤掉已经在轮播中的商品
		if (!carouselProductIds.isEmpty()) {
			queryWrapper.notIn("id", carouselProductIds);
		}

		// 如果有关键词，添加搜索条�?
		if (keyword != null && !keyword.trim().isEmpty()) {
			queryWrapper.like("name", keyword.trim());
		}

		queryWrapper.orderByDesc("create_time");

		// 计算总数
		Long total = productMapper.selectCount(queryWrapper);

		// 分页查询
		int offset = (page - 1) * pageSize;
		queryWrapper.last("LIMIT " + offset + ", " + pageSize);
		List<Product> products = productMapper.selectList(queryWrapper);

		// 构建返回结果
		List<Map<String, Object>> productList = new ArrayList<>();
		for (Product product : products) {
			Map<String, Object> map = new HashMap<>();
			map.put("id", product.getId());
			map.put("name", product.getName());
			map.put("price", product.getPrice());
			map.put("mainImage", product.getMainImage());
			productList.add(map);
		}

		Map<String, Object> result = new HashMap<>();
		result.put("list", productList);
		result.put("total", total);
		result.put("page", page);
		result.put("pageSize", pageSize);
		result.put("totalPages", (total + pageSize - 1) / pageSize);

		return result;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void addCarouselProduct(Long productId) {
		// 检查商品是否存�?
		Product product = productMapper.selectById(productId);
		if (product == null) {
			throw new CustomException(ResultCode.PRODUCT_NOT_FOUND);
		}

		// 检查是否已经在轮播�?
		QueryWrapper<CarouselProduct> checkWrapper = new QueryWrapper<>();
		checkWrapper.eq("product_id", productId);
		CarouselProduct existing = carouselProductMapper.selectOne(checkWrapper);
		if (existing != null) {
			throw new CustomException(ResultCode.CAROUSEL_PRODUCT_ALREADY_EXISTS);
		}

		// 检查轮播商品数量是否已达到5�?
		QueryWrapper<CarouselProduct> countWrapper = new QueryWrapper<>();
		Long count = carouselProductMapper.selectCount(countWrapper);
		if (count >= 5) {
			throw new CustomException(ResultCode.CAROUSEL_PRODUCT_LIMIT_EXCEEDED);
		}

		// 获取当前最大排序号
		QueryWrapper<CarouselProduct> maxOrderWrapper = new QueryWrapper<>();
		maxOrderWrapper.orderByDesc("sort_order");
		maxOrderWrapper.last("LIMIT 1");
		CarouselProduct maxOrderProduct = carouselProductMapper.selectOne(maxOrderWrapper);
		int nextOrder = maxOrderProduct != null ? maxOrderProduct.getSortOrder() + 1 : 1;

		// 添加轮播商品
		CarouselProduct carouselProduct = new CarouselProduct();
		carouselProduct.setProductId(productId);
		carouselProduct.setSortOrder(nextOrder);
		carouselProduct.setCreateTime(DateTimeUtil.nowUtc());
		carouselProduct.setUpdateTime(DateTimeUtil.nowUtc());
		carouselProductMapper.insert(carouselProduct);

		log.info("添加轮播商品成功: productId={}", productId);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deleteCarouselProduct(Long carouselId) {
		CarouselProduct carouselProduct = carouselProductMapper.selectById(carouselId);
		if (carouselProduct == null) {
			throw new CustomException(ResultCode.CAROUSEL_PRODUCT_NOT_FOUND);
		}

		carouselProductMapper.deleteById(carouselId);
		log.info("删除轮播商品成功: carouselId={}", carouselId);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateCarouselOrder(List<Long> productIds) {
		if (productIds == null || productIds.isEmpty()) {
			throw new CustomException(ResultCode.PRODUCT_ID_LIST_EMPTY);
		}

		// 更新每个商品的排�?
		for (int i = 0; i < productIds.size(); i++) {
			Long productId = productIds.get(i);

			// 查找对应的轮播商�?
			QueryWrapper<CarouselProduct> queryWrapper = new QueryWrapper<>();
			queryWrapper.eq("product_id", productId);
			CarouselProduct carouselProduct = carouselProductMapper.selectOne(queryWrapper);

			if (carouselProduct != null) {
				carouselProduct.setSortOrder(i + 1);
				carouselProduct.setUpdateTime(DateTimeUtil.nowUtc());
				carouselProductMapper.updateById(carouselProduct);
			}
		}

		log.info("更新轮播商品排序成功");
	}
}
