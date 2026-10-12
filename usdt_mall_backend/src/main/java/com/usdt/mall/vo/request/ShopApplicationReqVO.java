package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 店铺申请请求VO
 */
@Data
public class ShopApplicationReqVO {
	/**
	 * 店铺名称
	 */
	private String shopName;

	/**
	 * 店铺Logo
	 */
	private String shopLogo;

	/**
	 * 联系人姓名
	 */
	private String contactName;

	/**
	 * 联系人电话
	 */
	private String contactPhone;

	/**
	 * 证件号码
	 */
	private String idNumber;

	/**
	 * 证件正面照片
	 */
	private String idFrontImage;

	/**
	 * 证件反面照片
	 */
	private String idBackImage;

	/**
	 * 主营业务
	 */
	private String category;

	/**
	 * 详细地址
	 */
	private String address;

	/**
	 * 邀请码
	 */
	private String inviteCode;
}
