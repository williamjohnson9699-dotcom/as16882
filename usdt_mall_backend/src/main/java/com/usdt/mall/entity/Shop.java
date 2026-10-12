package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 店铺实体类
 */
@Data
@TableName("shop")
public class Shop {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 店主用户ID
	 */
	private Long userId;

	/**
	 * 店铺名称
	 */
	private String name;

	/**
	 * 店铺图标URL
	 */
	private String logo;

	/**
	 * 店铺等级
	 */
	private Integer level;

	/**
	 * 店铺评分
	 */
	private Double rating;

	/**
	 * 关注数量
	 */
	private Integer followCount;

	/**
	 * 浏览量
	 */
	private Integer views;

	/**
	 * 信誉分
	 */
	private Integer creditScore;

	/**
	 * 邀请码
	 */
	private String inviteCode;

	/**
	 * 主营业务类别
	 */
	private String category;

	/**
	 * 联系人姓名
	 */
	private String contactName;

	/**
	 * 联系人电话
	 */
	private String contactPhone;

	/**
	 * 店铺地址
	 */
	private String address;

	/**
	 * 店铺状态：0-关闭，1-营业
	 */
	private Integer status;

	/**
	 * 管理员解封时间。此时间及之前创建的超时未支付订单不再关闭商家页面。
	 */
	@TableField("payment_lock_waived_before")
	private LocalDateTime paymentLockWaivedBefore;

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
