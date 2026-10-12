package com.usdt.mall.mapper;

import lombok.Data;

/**
 * 店铺在售商品数量
 */
@Data
public class ShopOnSaleCount {

	private Long shopId;

	private Long onSaleCount;
}
