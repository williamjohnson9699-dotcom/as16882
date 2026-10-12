package com.usdt.mall.vo.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * APP版本信息响应VO
 */
@Data
public class AppVersionRespVO {
	/**
	 * 版本ID
	 */
	private Long id;

	/**
	 * 平台（ANDROID/IOS）
	 */
	private String platform;

	/**
	 * 版本号
	 */
	private Integer versionCode;

	/**
	 * 版本名称
	 */
	private String versionName;

	/**
	 * 下载地址
	 */
	private String downloadUrl;

	/**
	 * 更新描述
	 */
	private String updateDesc;

	/**
	 * 是否强制更新（0-否，1-是）
	 */
	private Integer isForceUpdate;

	/**
	 * 状态（0-禁用，1-启用）
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
