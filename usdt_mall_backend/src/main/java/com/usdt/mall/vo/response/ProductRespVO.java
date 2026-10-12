package com.usdt.mall.vo.response;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 商品响应VO
 */
@Data
public class ProductRespVO {

	private Long id;
	private String name;
	private String description;
	private BigDecimal price;
	private Integer stock;
	private Integer sales;
	private Integer views;
	private String mainImage;
	private List<String> images;
	private Long shopId;
	private String shopName;
	private Long categoryId;
	private String categoryName;
	private Integer status;
	private Integer isHot;
	private LocalDateTime createTime;
}
