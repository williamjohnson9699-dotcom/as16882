package com.usdt.mall.vo.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 聊天消息响应VO
 */
@Data
public class ChatMessageRespVO {

	/**
	 * 消息ID
	 */
	private Long id;

	/**
	 * 会话ID
	 */
	private Long sessionId;

	/**
	 * 发送者ID
	 */
	private Long senderId;

	/**
	 * 发送者昵称
	 */
	private String senderNickname;

	/**
	 * 发送者头像
	 */
	private String senderAvatar;

	/**
	 * 发送者类型：1-用户，2-客服
	 */
	private Integer senderType;

	/**
	 * 消息类型：1-文本，2-图片
	 */
	private Integer messageType;

	/**
	 * 消息内容
	 */
	private String content;

	/**
	 * 创建时间
	 */
	private LocalDateTime createTime;

	/**
	 * 是否已读
	 */
	private Boolean isRead;
}
