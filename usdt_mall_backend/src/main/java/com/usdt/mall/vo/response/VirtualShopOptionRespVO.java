package com.usdt.mall.vo.response;

import lombok.Data;

/**
 * 生成订单前可勾选的店铺
 */
@Data
public class VirtualShopOptionRespVO {

	private Long shopId;

	private Long userId;

	private String username;

	private String shopName;

	private Integer onSaleCount;
}
