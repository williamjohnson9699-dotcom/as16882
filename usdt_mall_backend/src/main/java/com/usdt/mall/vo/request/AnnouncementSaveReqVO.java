package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 系统公告保存请求VO
 */
@Data
public class AnnouncementSaveReqVO {
	/**
	 * 公告ID（编辑时需要）
	 */
	private Long id;

	/**
	 * 公告标题
	 */
	private String title;

	/**
	 * 公告内容
	 */
	private String content;
}
