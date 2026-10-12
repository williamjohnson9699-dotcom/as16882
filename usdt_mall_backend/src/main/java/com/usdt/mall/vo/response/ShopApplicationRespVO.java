package com.usdt.mall.vo.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 店铺申请响应VO
 */
@Data
public class ShopApplicationRespVO {
	/**
	 * 申请ID
	 */
	private Long id;

	/**
	 * 用户名
	 */
	private String username;

	/**
	 * 昵称
	 */
	private String nickname;

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
	 * 主营业务
	 */
	private String category;

	/**
	 * 证件号码
	 */
	private String idNumber;

	/**
	 * 身份证正面
	 */
	private String idFrontImage;

	/**
	 * 身份证反面
	 */
	private String idBackImage;

	/**
	 * 申请状态
	 */
	private String status;

	/**
	 * 邀请码
	 */
	private String inviteCode;

	/**
	 * 地址
	 */
	private String address;

	/**
	 * 审核备注
	 */
	private String reviewNote;

	/**
	 * 创建时间
	 */
	private LocalDateTime createTime;
}
