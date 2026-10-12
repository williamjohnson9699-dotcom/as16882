package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 聊天会话实体类
 */
@Data
@TableName("chat_session")
public class ChatSession {

	@TableId(type = IdType.AUTO)
	private Long id;

	private Long userId;

	private Long handlerId;

	private String lastMessage;

	private LocalDateTime lastMessageTime;

	private Integer serviceUnreadCount;

	private Integer userUnreadCount;

	private Integer status;

	/** 用户侧是否隐藏: 0-显示, 1-隐藏 */
	private Integer userHidden;

	/** 处理人侧是否隐藏: 0-显示, 1-隐藏。客服会话 handlerId 为空时，表示客服/管理员列表是否隐藏 */
	private Integer handlerHidden;

	/** 用户侧已清空到的消息ID，小于等于该ID的消息对该用户不可见 */
	private Long userClearedMessageId;

	/** 处理人侧已清空到的消息ID，小于等于该ID的消息对客服不可见 */
	private Long handlerClearedMessageId;

	@TableField("create_time")
	private LocalDateTime createTime;

	@TableField("update_time")
	private LocalDateTime updateTime;
}
