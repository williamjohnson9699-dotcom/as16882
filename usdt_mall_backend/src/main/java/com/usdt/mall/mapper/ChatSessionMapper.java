package com.usdt.mall.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.usdt.mall.entity.ChatSession;
import org.apache.ibatis.annotations.Mapper;

/**
 * 聊天会话Mapper
 */
@Mapper
public interface ChatSessionMapper extends BaseMapper<ChatSession> {
}
