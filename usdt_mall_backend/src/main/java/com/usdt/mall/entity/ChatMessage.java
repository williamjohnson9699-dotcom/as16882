package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 聊天消息实体类
 */
@Data
@TableName("chat_message")
public class ChatMessage {

	@TableId(type = IdType.AUTO)
	private Long id;

	private Long sessionId;

	private Long senderId;

	private Integer senderType;

	private Integer messageType;

	private String content;

	@TableField("is_read")
	private Boolean isRead;

	@TableField("create_time")
	private LocalDateTime createTime;
}
