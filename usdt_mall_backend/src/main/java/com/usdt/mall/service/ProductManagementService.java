package com.usdt.mall.service;

import com.usdt.mall.vo.request.ProductQueryReqVO;
import com.usdt.mall.vo.response.ProductInfoRespVO;

import java.util.List;
import java.util.Map;

/**
 * 商品管理服务接口
 */
public interface ProductManagementService {
	/**
	 * 查询商品列表
	 *
	 * @param reqVO 查询请求参数
	 * @return 商品列表数据
	 */
	Map<String, Object> queryProducts(ProductQueryReqVO reqVO);

	/**
	 * 获取商品详情
	 *
	 * @param productId 商品ID
	 * @return 商品详情
	 */
	ProductInfoRespVO getProductDetail(Long productId);

	/**
	 * 添加商品
	 *
	 * @param userId      用户ID
	 * @param name        商品名称
	 * @param category    商品分类
	 * @param price       商品价格
	 * @param stock       库存数量
	 * @param description 商品说明
	 * @param images      商品图片列表（最多5张）
	 */
	void addProduct(Long userId, String name, String category, String price, Integer stock, String description, List<String> images);

	/**
	 * 更新商品
	 *
	 * @param productId   商品ID
	 * @param name        商品名称
	 * @param category    商品分类
	 * @param price       商品价格
	 * @param stock       库存数量
	 * @param sales       销量
	 * @param views       浏览量
	 * @param status      状态
	 * @param description 商品说明
	 * @param images      商品图片列表（最多5张）
	 */
	void updateProduct(Long productId, String name, String category, String price, Integer stock, Integer sales, Integer views, String status, String description, List<String> images);

	/**
	 * 删除商品
	 *
	 * @param productId 商品ID
	 */
	void deleteProduct(Long productId);
}
