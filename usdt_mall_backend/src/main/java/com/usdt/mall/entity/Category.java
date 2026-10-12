package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 分类实体类
 */
@Data
@TableName("category")
public class Category {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 分类名称
	 */
	private String name;

	/**
	 * 分类图标URL
	 */
	private String icon;

	/**
	 * 排序
	 */
	private Integer sort;

	/**
	 * 状态：0-禁用，1-启用
	 */
	private Integer status;

	/**
	 * 创建时间
	 */
	private LocalDateTime createTime;

	/**
	 * 更新时间
	 */
	private LocalDateTime updateTime;
}
