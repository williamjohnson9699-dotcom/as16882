package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 发送聊天消息请求VO
 */
@Data
public class ChatMessageSendReqVO {

	/**
	 * 会话ID（可选，如果没有会话则创建新会话）
	 */
	private Long sessionId;

	/**
	 * 消息类型：1-文本，2-图片
	 */
	private Integer messageType = 1;

	/**
	 * 消息内容
	 */
	private String content;
}
