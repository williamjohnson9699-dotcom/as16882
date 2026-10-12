package com.usdt.mall.vo.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 系统公告信息响应VO
 */
@Data
public class AnnouncementInfoRespVO {
	/**
	 * 公告ID
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

	/**
	 * 创建时间
	 */
	private LocalDateTime createTime;
}
