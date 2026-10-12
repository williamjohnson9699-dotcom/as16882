package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 地址保存请求VO（新增/编辑）
 */
@Data
public class AddressSaveReqVO {
	/**
	 * 地址ID（编辑时需要）
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
	 * 是否设为默认地址
	 */
	private Boolean isDefault;
}
