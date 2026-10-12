package com.usdt.mall.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.vo.request.ProductSearchReqVO;
import com.usdt.mall.vo.response.ProductRespVO;

/**
 * 商品Service接口
 */
public interface ProductService {

	/**
	 * 搜索商品（分页）
	 */
	Page<ProductRespVO> searchProducts(ProductSearchReqVO reqVO);

	/**
	 * 获取商品详情
	 */
	ProductRespVO getProductDetail(Long id);

	/**
	 * 根据分类ID获取商品列表（分页）
	 */
	Page<ProductRespVO> getProductsByCategory(Long categoryId, Integer page, Integer pageSize);

	/**
	 * 获取热卖商品列表
	 */
	Page<ProductRespVO> getHotProducts(Integer page, Integer pageSize);

	/**
	 * 获取推荐商品列表（猜你喜欢）
	 */
	Page<ProductRespVO> getRecommendProducts(Long productId, Integer page, Integer pageSize);

	/**
	 * 增加商品浏览量
	 */
	void increaseViews(Long id);

	/**
	 * 获取商品关联的店铺列表
	 */
	java.util.List<java.util.Map<String, Object>> getProductShops(Long productId);
}
