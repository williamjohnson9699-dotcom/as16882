package com.usdt.mall.service;

import com.usdt.mall.vo.request.ChatMessageQueryReqVO;
import com.usdt.mall.vo.request.ChatMessageSendReqVO;
import com.usdt.mall.vo.response.ChatMessageRespVO;
import com.usdt.mall.vo.response.ChatSessionRespVO;

import java.util.List;
import java.util.Map;

/**
 * 聊天服务接口
 */
public interface ChatService {

	/**
	 * 获取或创建用户的聊天会话
	 *
	 * @param userId 用户ID
	 * @return 会话信息
	 */
	ChatSessionRespVO getOrCreateSession(Long userId);

	/**
	 * 获取或创建与指定用户的聊天会话
	 *
	 * @param userId       当前用户ID
	 * @param targetUserId 目标用户ID
	 * @return 会话信息
	 */
	ChatSessionRespVO getOrCreateUserSession(Long userId, Long targetUserId);

	/**
	 * 获取聊天会话列表
	 * 管理员/客服：返回所有用户的会话列表
	 * 普通用户：返回自己的会话列表
	 *
	 * @param userId 当前用户ID
	 * @return 会话列表
	 */
	List<ChatSessionRespVO> getAllSessions(Long userId);

	/**
	 * 获取聊天消息列表（分页）。只返回当前用户清空位置之后的消息。
	 *
	 * @param reqVO  查询请求
	 * @param userId 当前用户ID
	 * @return 消息列表（分页数据）
	 */
	Map<String, Object> getMessageList(ChatMessageQueryReqVO reqVO, Long userId);

	/**
	 * 发送消息
	 *
	 * @param userId 用户ID
	 * @param reqVO  发送消息请求
	 * @return 消息信息
	 */
	ChatMessageRespVO sendMessage(Long userId, ChatMessageSendReqVO reqVO);

	/**
	 * 标记消息为已读
	 *
	 * @param sessionId 会话ID
	 * @param userId    用户ID
	 */
	void markAsRead(Long sessionId, Long userId);

	/**
	 * 从当前用户的会话列表隐藏该会话，并记下该用户的清空位置。
	 * 消息仍保留，对方按自己的清空位置查看。
	 *
	 * @param sessionId 会话ID
	 * @param userId    当前用户ID
	 */
	void hideSession(Long sessionId, Long userId);
}
