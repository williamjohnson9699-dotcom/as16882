package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.entity.Cart;
import com.usdt.mall.entity.Product;
import com.usdt.mall.entity.Shop;
import com.usdt.mall.exception.CustomException;
import com.usdt.mall.mapper.CartMapper;
import com.usdt.mall.mapper.ProductMapper;
import com.usdt.mall.mapper.ShopMapper;
import com.usdt.mall.mapper.ShopProductMapper;
import com.usdt.mall.service.CartService;
import com.usdt.mall.vo.request.AddCartReqVO;
import com.usdt.mall.vo.request.UpdateCartReqVO;
import com.usdt.mall.vo.response.CartRespVO;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 购物车Service实现类
 */
@Service
public class CartServiceImpl implements CartService {

	@Resource
	private CartMapper cartMapper;

	@Resource
	private ProductMapper productMapper;

	@Resource
	private ShopProductMapper shopProductMapper;

	@Resource
	private ShopMapper shopMapper;

	@Override
	public void addToCart(AddCartReqVO reqVO, Long userId) {
		// 检查商品是否存在
		Product product = productMapper.selectById(reqVO.getProductId());
		if (product == null) {
			throw new CustomException(ResultCode.PRODUCT_NOT_FOUND);
		}

		// 检查库存
		if (product.getStock() < reqVO.getQuantity()) {
			throw new CustomException(ResultCode.PRODUCT_OUT_OF_STOCK);
		}

		// 检查是否已在购物车中（需要同时匹配商品ID和店铺ID）
		LambdaQueryWrapper<Cart> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Cart::getUserId, userId);
		wrapper.eq(Cart::getProductId, reqVO.getProductId());
		wrapper.eq(Cart::getShopId, reqVO.getShopId());
		Cart existCart = cartMapper.selectOne(wrapper);

		if (existCart != null) {
			// 更新数量
			existCart.setQuantity(existCart.getQuantity() + reqVO.getQuantity());
			cartMapper.updateById(existCart);
		} else {
			// 新增购物车记录
			Cart cart = new Cart();
			cart.setUserId(userId);
			cart.setProductId(reqVO.getProductId());
			cart.setShopId(reqVO.getShopId());
			cart.setQuantity(reqVO.getQuantity());
			cartMapper.insert(cart);
		}
	}

	@Override
	public List<CartRespVO> getCartList(Long userId) {
		LambdaQueryWrapper<Cart> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Cart::getUserId, userId);
		wrapper.orderByDesc(Cart::getCreateTime);
		List<Cart> cartList = cartMapper.selectList(wrapper);

		return cartList.stream()
				.map(this::convertToRespVO)
				.collect(Collectors.toList());
	}

	@Override
	public int getCartCount(Long userId) {
		LambdaQueryWrapper<Cart> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(Cart::getUserId, userId);
		return cartMapper.selectCount(wrapper).intValue();
	}

	@Override
	public void updateCartQuantity(Long cartId, UpdateCartReqVO reqVO, Long userId) {
		Cart cart = cartMapper.selectById(cartId);
		if (cart == null || !cart.getUserId().equals(userId)) {
			throw new CustomException(ResultCode.CART_ITEM_NOT_FOUND);
		}

		// 检查库存
		Product product = productMapper.selectById(cart.getProductId());
		if (product != null && product.getStock() < reqVO.getQuantity()) {
			throw new CustomException(ResultCode.PRODUCT_OUT_OF_STOCK);
		}

		cart.setQuantity(reqVO.getQuantity());
		cartMapper.updateById(cart);
	}

	@Override
	public void deleteCart(Long cartId, Long userId) {
		Cart cart = cartMapper.selectById(cartId);
		if (cart == null || !cart.getUserId().equals(userId)) {
			throw new CustomException(ResultCode.CART_ITEM_NOT_FOUND);
		}
		cartMapper.deleteById(cartId);
	}

	private CartRespVO convertToRespVO(Cart cart) {
		CartRespVO respVO = new CartRespVO();
		BeanUtils.copyProperties(cart, respVO);

		// 查询商品信息
		Product product = productMapper.selectById(cart.getProductId());
		if (product != null) {
			respVO.setProductName(product.getName());
			respVO.setProductPrice(product.getPrice());
			respVO.setProductImage(product.getMainImage());
			respVO.setStock(product.getStock());
		}

		// 查询店铺信息
		if (cart.getShopId() != null) {
			Shop shop = shopMapper.selectById(cart.getShopId());
			if (shop != null) {
				respVO.setShopName(shop.getName());
				respVO.setShopLogo(shop.getLogo());
			}
		}

		return respVO;
	}
}
