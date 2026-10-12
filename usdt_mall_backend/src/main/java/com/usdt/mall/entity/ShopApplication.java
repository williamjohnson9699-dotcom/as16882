package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 店铺申请实体类
 */
@Data
@TableName("shop_application")
public class ShopApplication {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 用户ID
	 */
	private Long userId;

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

	/**
	 * 申请状态：pending-待审核，approved-已通过，rejected-已拒绝
	 */
	private String status;

	/**
	 * 审核备注
	 */
	private String reviewNote;

	/**
	 * 创建时间
	 */
	@TableField("create_time")
	private LocalDateTime createTime;

	/**
	 * 更新时间
	 */
	@TableField("update_time")
	private LocalDateTime updateTime;
}
