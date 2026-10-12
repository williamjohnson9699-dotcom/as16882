package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * APP版本保存请求VO
 */
@Data
public class AppVersionSaveReqVO {
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
}
