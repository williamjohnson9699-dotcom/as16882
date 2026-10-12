package com.usdt.mall.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.usdt.mall.entity.ChatMessage;
import org.apache.ibatis.annotations.Mapper;

/**
 * 聊天消息Mapper
 */
@Mapper
public interface ChatMessageMapper extends BaseMapper<ChatMessage> {
}
