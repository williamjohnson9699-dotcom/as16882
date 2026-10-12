package com.usdt.mall.vo.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 店铺响应VO
 */
@Data
public class ShopRespVO {

	private Long id;
	private String name;
	private String logo;
	private Integer level;
	private Double rating;
	private Integer followCount;
	private Integer views;
	private Integer creditScore;
	private Long userId;
	private Integer status;
	private Boolean isFollowed;
	private LocalDateTime createTime;
}
