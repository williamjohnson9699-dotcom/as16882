package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 地址实体类
 */
@Data
@TableName("user_address")
public class Address {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 用户ID
	 */
	private Long userId;

	/**
	 * 收货人姓名
	 */
	@TableField("receiver_name")
	private String name;

	/**
	 * 联系电话
	 */
	@TableField("receiver_phone")
	private String phone;

	/**
	 * 详细地址
	 */
	@TableField("detail_address")
	private String address;

	/**
	 * 是否默认地址：0-否，1-是
	 */
	private Integer isDefault;

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
