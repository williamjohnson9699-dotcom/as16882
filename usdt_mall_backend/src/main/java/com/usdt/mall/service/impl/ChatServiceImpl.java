package com.usdt.mall.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.entity.ChatMessage;
import com.usdt.mall.entity.ChatSession;
import com.usdt.mall.entity.User;
import com.usdt.mall.mapper.ChatMessageMapper;
import com.usdt.mall.mapper.ChatSessionMapper;
import com.usdt.mall.mapper.UserMapper;
import com.usdt.mall.service.ChatService;
import com.usdt.mall.util.DateTimeUtil;
import com.usdt.mall.vo.request.ChatMessageQueryReqVO;
import com.usdt.mall.vo.request.ChatMessageSendReqVO;
import com.usdt.mall.vo.response.ChatMessageRespVO;
import com.usdt.mall.vo.response.ChatSessionRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 聊天服务实现�?
 */
@Slf4j
@Service
public class ChatServiceImpl implements ChatService {

	@Resource
	private ChatSessionMapper chatSessionMapper;

	@Resource
	private ChatMessageMapper chatMessageMapper;

	@Resource
	private UserMapper userMapper;

	@Override
	public ChatSessionRespVO getOrCreateSession(Long userId) {
		// 查询用户是否已有会话
		QueryWrapper<ChatSession> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("user_id", userId);
		queryWrapper.eq("status", 1); // 进行中的会话
		queryWrapper.orderByDesc("create_time");
		queryWrapper.last("LIMIT 1");

		ChatSession session = chatSessionMapper.selectOne(queryWrapper);

		// 如果没有会话，创建新会话
		if (session == null) {
			session = new ChatSession();
			session.setUserId(userId);
			session.setHandlerId(null); // 暂时没有分配客服
			session.setLastMessage("");
			session.setLastMessageTime(DateTimeUtil.nowUtc());
			session.setServiceUnreadCount(0);
			session.setUserUnreadCount(0);
			session.setStatus(1); // 进行�?
			session.setUserHidden(0);
			session.setHandlerHidden(0);
			session.setCreateTime(DateTimeUtil.nowUtc());
			session.setUpdateTime(DateTimeUtil.nowUtc());
			chatSessionMapper.insert(session);
		} else {
			clearHidden(session, false);
		}

		User viewer = userMapper.selectById(userId);
		return convertSessionToRespVO(session, viewer);
	}

	@Override
	public ChatSessionRespVO getOrCreateUserSession(Long userId, Long targetUserId) {
		// 查询当前用户信息，判断是否是管理�?客服
		User currentUser = userMapper.selectById(userId);
		if (currentUser == null) {
			throw new RuntimeException("用户不存在");
		}

		String role = currentUser.getRole();
		boolean isAdminOrService = "ADMIN".equalsIgnoreCase(role) || "SERVICE".equalsIgnoreCase(role);

		ChatSession session = null;

		if (isAdminOrService) {
			// 管理�?客服：查询目标用户的客服会话（userId=targetUserId, handlerId=null�?
			QueryWrapper<ChatSession> queryWrapper = new QueryWrapper<>();
			queryWrapper.eq("user_id", targetUserId);
			queryWrapper.isNull("handler_id");
			queryWrapper.eq("status", 1);
			queryWrapper.orderByDesc("create_time");
			queryWrapper.last("LIMIT 1");

			session = chatSessionMapper.selectOne(queryWrapper);

			if (session == null) {
				// 创建新的客服会话
				session = new ChatSession();
				session.setUserId(targetUserId);  // userId是目标用�?
				session.setHandlerId(null);       // handlerId为null
				session.setLastMessage("");
				session.setLastMessageTime(DateTimeUtil.nowUtc());
				session.setServiceUnreadCount(0);
				session.setUserUnreadCount(0);
				session.setStatus(1);
				session.setUserHidden(0);
				session.setHandlerHidden(0);
				session.setCreateTime(DateTimeUtil.nowUtc());
				session.setUpdateTime(DateTimeUtil.nowUtc());
				chatSessionMapper.insert(session);
			} else {
				clearHidden(session, true);
			}
		} else {
			// 普通用户：查询是否已有会话（双向查询）
			QueryWrapper<ChatSession> queryWrapper = new QueryWrapper<>();
			queryWrapper.nested(wrapper -> wrapper
					.nested(w -> w.eq("user_id", userId).eq("handler_id", targetUserId))
					.or()
					.nested(w -> w.eq("user_id", targetUserId).eq("handler_id", userId))
			);
			queryWrapper.eq("status", 1);
			queryWrapper.orderByDesc("create_time");
			queryWrapper.last("LIMIT 1");

			session = chatSessionMapper.selectOne(queryWrapper);

			if (session == null) {
				session = new ChatSession();
				session.setUserId(userId);
				session.setHandlerId(targetUserId);
				session.setLastMessage("");
				session.setLastMessageTime(DateTimeUtil.nowUtc());
				session.setServiceUnreadCount(0);
				session.setUserUnreadCount(0);
				session.setStatus(1);
				session.setUserHidden(0);
				session.setHandlerHidden(0);
				session.setCreateTime(DateTimeUtil.nowUtc());
				session.setUpdateTime(DateTimeUtil.nowUtc());
				chatSessionMapper.insert(session);
			} else {
				clearHidden(session, !userId.equals(session.getUserId()));
			}
		}

		return convertSessionToRespVO(session, currentUser);
	}

	@Override
	public List<ChatSessionRespVO> getAllSessions(Long userId) {
		// 查询当前用户信息
		User currentUser = userMapper.selectById(userId);
		if (currentUser == null) {
			return new ArrayList<>();
		}

		String role = currentUser.getRole();
		boolean isAdminOrService = "ADMIN".equalsIgnoreCase(role) || "SERVICE".equalsIgnoreCase(role);

		QueryWrapper<ChatSession> queryWrapper = new QueryWrapper<>();

		if (isAdminOrService) {
			// 管理�?客服：只查询handlerId为null的客服会�?
			queryWrapper.isNull("handler_id");
			queryWrapper.and(wrapper -> wrapper.eq("handler_hidden", 0).or().isNull("handler_hidden"));
			queryWrapper.orderByDesc("last_message_time");
			List<ChatSession> sessions = chatSessionMapper.selectList(queryWrapper);

			// 过滤掉客服和管理员的会话，只保留普通用户的会话
			return sessions.stream()
					.filter(session -> {
						User user = userMapper.selectById(session.getUserId());
						if (user == null) {
							return false;
						}
						String userRole = user.getRole();
						return !"ADMIN".equalsIgnoreCase(userRole) && !"SERVICE".equalsIgnoreCase(userRole);
					})
					.map(session -> convertSessionToRespVO(session, currentUser))
					.collect(Collectors.toList());
		} else {
			// 普通用户：查询自己参与的所有会话（作为userId或handlerId�?
			queryWrapper.nested(wrapper -> wrapper
					.eq("user_id", userId)
					.or()
					.eq("handler_id", userId)
			);
			queryWrapper.eq("status", 1);
			queryWrapper.orderByDesc("last_message_time");

			List<ChatSession> sessions = chatSessionMapper.selectList(queryWrapper);
			return sessions.stream()
					.filter(session -> !isHiddenForUser(session, userId))
					.map(session -> convertSessionToRespVO(session, currentUser))
					.collect(Collectors.toList());
		}
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void hideSession(Long sessionId, Long userId) {
		ChatSession session = chatSessionMapper.selectById(sessionId);
		if (session == null) {
			throw new RuntimeException("会话不存在");
		}

		User currentUser = userMapper.selectById(userId);
		if (currentUser == null) {
			throw new RuntimeException("用户不存在");
		}

		int side = resolveViewerSide(session, currentUser);
		if (side < 0) {
			throw new RuntimeException("无权删除该会话");
		}

		if (side == 0) {
			session.setUserHidden(1);
			session.setUserUnreadCount(0);
			session.setUserClearedMessageId(laterCursor(session.getUserClearedMessageId(), findLatestVisibleMessageId(session.getId(), null)));
		} else {
			session.setHandlerHidden(1);
			session.setServiceUnreadCount(0);
			session.setHandlerClearedMessageId(laterCursor(session.getHandlerClearedMessageId(), findLatestVisibleMessageId(session.getId(), null)));
		}

		session.setUpdateTime(DateTimeUtil.nowUtc());
		chatSessionMapper.updateById(session);
	}

	@Override
	public Map<String, Object> getMessageList(ChatMessageQueryReqVO reqVO, Long userId) {
		QueryWrapper<ChatMessage> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("session_id", reqVO.getSessionId());

		Long clearedMessageId = clearedMessageIdForViewer(reqVO.getSessionId(), userId);
		if (clearedMessageId != null) {
			queryWrapper.gt("id", clearedMessageId);
		}

		// 如果提供了lastMessageId，则查询比它更早的消息
		if (reqVO.getLastMessageId() != null) {
			queryWrapper.lt("id", reqVO.getLastMessageId());
		}

		queryWrapper.orderByDesc("id");

		Page<ChatMessage> page = new Page<>(reqVO.getPage(), reqVO.getPageSize());
		Page<ChatMessage> resultPage = chatMessageMapper.selectPage(page, queryWrapper);

		List<ChatMessageRespVO> records = resultPage.getRecords().stream()
				.map(this::convertMessageToRespVO)
				.collect(Collectors.toList());

		Map<String, Object> result = new HashMap<>();
		result.put("records", records);
		result.put("total", resultPage.getTotal());
		result.put("current", resultPage.getCurrent());
		result.put("size", resultPage.getSize());
		result.put("pages", resultPage.getPages());

		return result;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public ChatMessageRespVO sendMessage(Long userId, ChatMessageSendReqVO reqVO) {
		// 获取或创建会�?
		Long sessionId = reqVO.getSessionId();
		if (sessionId == null) {
			ChatSessionRespVO session = getOrCreateSession(userId);
			sessionId = session.getId();
		}

		// 查询用户角色，判�?senderType
		User user = userMapper.selectById(userId);
		int senderType = 1; // 默认为用�?
		if (user != null) {
			String role = user.getRole();
			// 如果是管理员或客服，senderType 设置�?2
			if ("ADMIN".equalsIgnoreCase(role) || "SERVICE".equalsIgnoreCase(role)) {
				senderType = 2;
			}
		}

		// 创建消息
		ChatMessage message = new ChatMessage();
		message.setSessionId(sessionId);
		message.setSenderId(userId);
		message.setSenderType(senderType); // 根据用户角色设置
		message.setMessageType(reqVO.getMessageType());
		message.setContent(reqVO.getContent());
		message.setIsRead(false); // 新消息默认未�?
		message.setCreateTime(DateTimeUtil.nowUtc());
		chatMessageMapper.insert(message);

		// 更新会话的最后消�?
		ChatSession session = chatSessionMapper.selectById(sessionId);
		if (session != null) {
			// 如果是图片消息，显示�?[图片]'
			String lastMessage = reqVO.getMessageType() == 2 ? "[图片]" : reqVO.getContent();
			session.setLastMessage(lastMessage);
			session.setLastMessageTime(DateTimeUtil.nowUtc());
			session.setUpdateTime(DateTimeUtil.nowUtc());

			// 根据发送者在会话中的角色增加对应的未读数
			if (senderType == 1) {
				// 普通用户发送消�?
				if (session.getHandlerId() == null) {
					// 客服会话：增加客服未读数
					session.setServiceUnreadCount(session.getServiceUnreadCount() + 1);
				} else if (session.getUserId().equals(userId)) {
					// 用户间会话，发送者是userId：增加客服未读数（对方的未读�?
					session.setServiceUnreadCount(session.getServiceUnreadCount() + 1);
				} else {
					// 用户间会话，发送者是handlerId：增加用户未读数（对方的未读�?
					session.setUserUnreadCount(session.getUserUnreadCount() + 1);
				}
			} else {
				// 客服/管理员发送消息，增加用户的未读数
				session.setUserUnreadCount(session.getUserUnreadCount() + 1);
			}

			chatSessionMapper.updateById(session);
		}

		return convertMessageToRespVO(message);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void markAsRead(Long sessionId, Long userId) {
		// 查询用户角色
		User user = userMapper.selectById(userId);
		if (user == null) {
			return;
		}

		String role = user.getRole();
		boolean isAdminOrService = "ADMIN".equalsIgnoreCase(role) || "SERVICE".equalsIgnoreCase(role);

		// 标记该会话中的消息为已读
		QueryWrapper<ChatMessage> messageQueryWrapper = new QueryWrapper<>();
		messageQueryWrapper.eq("session_id", sessionId);
		messageQueryWrapper.eq("is_read", false);

		if (isAdminOrService) {
			// 管理�?客服：标记用户发送的消息为已读（senderType = 1�?
			messageQueryWrapper.eq("sender_type", 1);
		} else {
			// 普通用户：标记客服/管理员发送的消息为已读（senderType = 2�?
			messageQueryWrapper.eq("sender_type", 2);
		}

		// 批量更新消息为已�?
		ChatMessage updateMessage = new ChatMessage();
		updateMessage.setIsRead(true);
		chatMessageMapper.update(updateMessage, messageQueryWrapper);

		// 重置会话的未读数
		ChatSession session = chatSessionMapper.selectById(sessionId);
		if (session != null) {
			if (isAdminOrService) {
				// 管理�?客服查看消息，清零客服未读数
				session.setServiceUnreadCount(0);
			} else {
				// 普通用户：判断是userId还是handlerId
				if (session.getUserId().equals(userId)) {
					// 当前用户是userId，清零用户未读数
					session.setUserUnreadCount(0);
				} else if (userId.equals(session.getHandlerId())) {
					// 当前用户是handlerId，清零客服未读数
					session.setServiceUnreadCount(0);
				}
			}
			session.setUpdateTime(DateTimeUtil.nowUtc());
			chatSessionMapper.updateById(session);
		}
	}

	/**
	 * 当前用户这一侧是否已隐藏。对方发来新消息不会取消隐藏。
	 */
	private boolean isHiddenForUser(ChatSession session, Long userId) {
		if (userId.equals(session.getUserId())) {
			return isHidden(session.getUserHidden());
		}
		if (userId.equals(session.getHandlerId())) {
			return isHidden(session.getHandlerHidden());
		}
		return true;
	}

	private boolean isHidden(Integer flag) {
		return flag != null && flag == 1;
	}

	/**
	 * 本人再次打开会话时，只清掉自己这一侧的隐藏标记。
	 *
	 * @param handlerSide true 表示当前用户处在 handler 侧（含客服列表）
	 */
	private void clearHidden(ChatSession session, boolean handlerSide) {
		boolean changed = false;
		if (handlerSide) {
			if (isHidden(session.getHandlerHidden())) {
				session.setHandlerHidden(0);
				changed = true;
			}
		} else if (isHidden(session.getUserHidden())) {
			session.setUserHidden(0);
			changed = true;
		}
		if (changed) {
			session.setUpdateTime(DateTimeUtil.nowUtc());
			chatSessionMapper.updateById(session);
		}
	}

	/**
	 * 判断当前用户看这个会话时站在哪一侧。
	 *
	 * @param session 会话
	 * @param viewer  当前用户
	 * @return 0 用户侧，1 处理人侧，-1 不属于该会话
	 */
	private int resolveViewerSide(ChatSession session, User viewer) {
		if (viewer == null || viewer.getId() == null) {
			return -1;
		}
		Long userId = viewer.getId();
		if (userId.equals(session.getUserId())) {
			return 0;
		}
		if (userId.equals(session.getHandlerId())) {
			return 1;
		}
		String role = viewer.getRole();
		boolean isAdminOrService = role != null
				&& ("ADMIN".equalsIgnoreCase(role) || "SERVICE".equalsIgnoreCase(role));
		if (isAdminOrService && session.getHandlerId() == null) {
			return 1;
		}
		return -1;
	}

	/**
	 * 取两个清空位置中更晚的那个。新位置为空时保留原位置。
	 *
	 * @param current 已经记下的消息ID
	 * @param latest  当前会话里最新的消息ID
	 * @return 应写入的清空位置，两边都为空时返回 null
	 */
	private Long laterCursor(Long current, Long latest) {
		if (latest == null) {
			return current;
		}
		if (current == null || latest > current) {
			return latest;
		}
		return current;
	}

	/**
	 * 查询会话中对当前查看者仍可见的最后一条消息ID。
	 *
	 * @param sessionId         会话ID
	 * @param clearedMessageId  已清空到的消息ID，为空表示不限制
	 * @return 消息ID，没有则返回 null
	 */
	private Long findLatestVisibleMessageId(Long sessionId, Long clearedMessageId) {
		QueryWrapper<ChatMessage> queryWrapper = new QueryWrapper<>();
		queryWrapper.eq("session_id", sessionId);
		if (clearedMessageId != null) {
			queryWrapper.gt("id", clearedMessageId);
		}
		queryWrapper.orderByDesc("id");
		queryWrapper.last("LIMIT 1");
		ChatMessage message = chatMessageMapper.selectOne(queryWrapper);
		return message == null ? null : message.getId();
	}

	/**
	 * 读取当前用户在该会话上的清空位置。
	 *
	 * @param sessionId 会话ID
	 * @param userId    当前用户ID
	 * @return 清空位置，不限制时返回 null
	 */
	private Long clearedMessageIdForViewer(Long sessionId, Long userId) {
		ChatSession session = chatSessionMapper.selectById(sessionId);
		if (session == null || userId == null) {
			return null;
		}
		User viewer = userMapper.selectById(userId);
		int side = resolveViewerSide(session, viewer);
		if (side == 0) {
			return session.getUserClearedMessageId();
		}
		if (side == 1) {
			return session.getHandlerClearedMessageId();
		}
		return null;
	}

	/**
	 * 清空位置之后没有消息时，列表预览不再显示旧的最后一条。
	 *
	 * @param respVO  会话响应
	 * @param session 会话
	 * @param viewer  当前用户
	 */
	private void maskClearedPreview(ChatSessionRespVO respVO, ChatSession session, User viewer) {
		int side = resolveViewerSide(session, viewer);
		Long clearedMessageId = null;
		if (side == 0) {
			clearedMessageId = session.getUserClearedMessageId();
		} else if (side == 1) {
			clearedMessageId = session.getHandlerClearedMessageId();
		}
		if (clearedMessageId == null) {
			return;
		}
		if (findLatestVisibleMessageId(session.getId(), clearedMessageId) == null) {
			respVO.setLastMessage("");
			respVO.setLastMessageTime(null);
		}
	}

	/**
	 * 转换会话实体为响应VO，并按当前用户的清空位置处理最后一条预览。
	 *
	 * @param session 会话
	 * @param viewer  当前用户
	 * @return 会话响应
	 */
	private ChatSessionRespVO convertSessionToRespVO(ChatSession session, User viewer) {
		ChatSessionRespVO respVO = new ChatSessionRespVO();
		BeanUtils.copyProperties(session, respVO);

		User user = userMapper.selectById(session.getUserId());
		if (user != null) {
			respVO.setUserNickname(user.getNickname());
			respVO.setUserAvatar(user.getAvatar());
		}

		if (session.getHandlerId() != null) {
			User handler = userMapper.selectById(session.getHandlerId());
			if (handler != null) {
				respVO.setHandlerNickname(handler.getNickname());
				respVO.setHandlerAvatar(handler.getAvatar());
			}
		}

		maskClearedPreview(respVO, session, viewer);
		return respVO;
	}

	/**
	 * 转换消息实体为响应VO
	 */
	private ChatMessageRespVO convertMessageToRespVO(ChatMessage message) {
		ChatMessageRespVO respVO = new ChatMessageRespVO();
		BeanUtils.copyProperties(message, respVO);

		// 查询发送者信�?
		User sender = userMapper.selectById(message.getSenderId());
		if (sender != null) {
			respVO.setSenderNickname(sender.getNickname());
			respVO.setSenderAvatar(sender.getAvatar());
		}

		// 使用实际的已读状�?
		respVO.setIsRead(message.getIsRead() != null ? message.getIsRead() : false);
		return respVO;
	}
}
