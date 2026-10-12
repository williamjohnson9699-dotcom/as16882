package com.usdt.mall.vo.request;

import lombok.Data;

@Data
public class ShopUpdateReqVO {
	private String shopName;
	private String logo;
	private String contactName;
	private String contactPhone;
	private String category;
	private String address;
	private Integer orderCount;
	private Double salesAmount;
	private Integer followCount;
	private Integer views;
	private Integer level;
	private Double rating;
	private Integer creditScore;
}
