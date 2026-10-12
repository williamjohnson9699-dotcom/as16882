package com.usdt.mall.vo.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 聊天会话响应VO
 */
@Data
public class ChatSessionRespVO {

	/**
	 * 会话ID
	 */
	private Long id;

	/**
	 * 用户ID
	 */
	private Long userId;

	/**
	 * 用户昵称
	 */
	private String userNickname;

	/**
	 * 用户头像
	 */
	private String userAvatar;

	/**
	 * 处理者ID（客服ID）
	 */
	private Long handlerId;

	/**
	 * 处理者昵称
	 */
	private String handlerNickname;

	/**
	 * 处理者头像
	 */
	private String handlerAvatar;

	/**
	 * 最后一条消息
	 */
	private String lastMessage;

	/**
	 * 最后消息时间
	 */
	private LocalDateTime lastMessageTime;

	/**
	 * 客服/管理员未读消息数（用户发送的消息）
	 */
	private Integer serviceUnreadCount;

	/**
	 * 用户未读消息数（客服/管理员发送的消息）
	 */
	private Integer userUnreadCount;

	/**
	 * 会话状态：1-进行中，2-已结束
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
