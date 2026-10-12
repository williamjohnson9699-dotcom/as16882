package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 店铺关注关系实体类
 */
@Data
@TableName("shop_follow")
public class ShopFollow {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 用户ID
	 */
	private Long userId;

	/**
	 * 店铺ID
	 */
	private Long shopId;

	/**
	 * 创建时间
	 */
	@TableField("create_time")
	private LocalDateTime createTime;
}
