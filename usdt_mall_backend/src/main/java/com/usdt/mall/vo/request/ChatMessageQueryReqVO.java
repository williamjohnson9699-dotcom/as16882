package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 聊天消息查询请求VO
 */
@Data
public class ChatMessageQueryReqVO {

	/**
	 * 会话ID
	 */
	private Long sessionId;

	/**
	 * 页码
	 */
	private Integer page = 1;

	/**
	 * 每页数量
	 */
	private Integer pageSize = 20;

	/**
	 * 最后一条消息ID（用于分页加载）
	 */
	private Long lastMessageId;
}
