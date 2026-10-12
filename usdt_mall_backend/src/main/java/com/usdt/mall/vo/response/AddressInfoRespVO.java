package com.usdt.mall.vo.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 地址信息响应VO
 */
@Data
public class AddressInfoRespVO {
	/**
	 * 地址ID
	 */
	private Long id;

	/**
	 * 收货人姓名
	 */
	private String name;

	/**
	 * 联系电话
	 */
	private String phone;

	/**
	 * 详细地址
	 */
	private String address;

	/**
	 * 是否默认地址
	 */
	private Boolean isDefault;

	/**
	 * 创建时间
	 */
	private LocalDateTime createTime;
}
