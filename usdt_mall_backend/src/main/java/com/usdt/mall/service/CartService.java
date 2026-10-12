package com.usdt.mall.service;

import com.usdt.mall.vo.request.AddCartReqVO;
import com.usdt.mall.vo.request.UpdateCartReqVO;
import com.usdt.mall.vo.response.CartRespVO;

import java.util.List;

/**
 * 购物车Service接口
 */
public interface CartService {

	/**
	 * 添加商品到购物车
	 */
	void addToCart(AddCartReqVO reqVO, Long userId);

	/**
	 * 获取购物车列表
	 */
	List<CartRespVO> getCartList(Long userId);

	/**
	 * 获取购物车商品数量
	 */
	int getCartCount(Long userId);

	/**
	 * 更新购物车商品数量
	 */
	void updateCartQuantity(Long cartId, UpdateCartReqVO reqVO, Long userId);

	/**
	 * 删除购物车商品
	 */
	void deleteCart(Long cartId, Long userId);
}
