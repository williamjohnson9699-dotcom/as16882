package com.usdt.mall.controller;

import com.usdt.mall.common.Result;
import com.usdt.mall.common.ResultCode;
import com.usdt.mall.service.ChatService;
import com.usdt.mall.util.JwtUtil;
import com.usdt.mall.vo.request.ChatMessageQueryReqVO;
import com.usdt.mall.vo.request.ChatMessageSendReqVO;
import com.usdt.mall.vo.response.ChatMessageRespVO;
import com.usdt.mall.vo.response.ChatSessionRespVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;

/**
 * 聊天控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/chat")
@Tag(name = "聊天管理", description = "聊天相关接口")
public class ChatController {

	@Resource
	private ChatService chatService;

	@Resource
	private JwtUtil jwtUtil;

	/**
	 * 获取或创建聊天会话
	 */
	@GetMapping("/session")
	@Operation(summary = "获取或创建聊天会话")
	public Result<ChatSessionRespVO> getOrCreateSession(HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}

		try {
			ChatSessionRespVO session = chatService.getOrCreateSession(userId);
			return Result.successWith(session);
		} catch (Exception e) {
			log.error("获取聊天会话失败", e);
			return Result.<ChatSessionRespVO>error().newCnMsg("获取聊天会话失败: " + e.getMessage());
		}
	}

	/**
	 * 获取或创建与指定用户的聊天会话
	 */
	@GetMapping("/session/{targetUserId}")
	@Operation(summary = "获取或创建与指定用户的聊天会话")
	public Result<ChatSessionRespVO> getOrCreateUserSession(@PathVariable Long targetUserId, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}

		try {
			ChatSessionRespVO session = chatService.getOrCreateUserSession(userId, targetUserId);
			return Result.successWith(session);
		} catch (Exception e) {
			log.error("获取用户会话失败", e);
			return Result.<ChatSessionRespVO>error().newCnMsg("获取用户会话失败: " + e.getMessage());
		}
	}

	/**
	 * 获取所有聊天会话列表（管理员/客服使用）或当前用户的会话（普通用户）
	 */
	@GetMapping("/sessions")
	@Operation(summary = "获取聊天会话列表")
	public Result<List<ChatSessionRespVO>> getAllSessions(HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}

		try {
			List<ChatSessionRespVO> sessions = chatService.getAllSessions(userId);
			return Result.successWith(sessions);
		} catch (Exception e) {
			log.error("获取会话列表失败", e);
			return Result.<List<ChatSessionRespVO>>error().newCnMsg("获取会话列表失败: " + e.getMessage());
		}
	}

	/**
	 * 获取聊天消息列表
	 */
	@GetMapping("/messages")
	@Operation(summary = "获取聊天消息列表")
	public Result<Map<String, Object>> getMessageList(
			@RequestParam Long sessionId,
			@RequestParam(defaultValue = "1") Integer page,
			@RequestParam(defaultValue = "20") Integer pageSize,
			@RequestParam(required = false) Long lastMessageId,
			HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}

		try {
			ChatMessageQueryReqVO reqVO = new ChatMessageQueryReqVO();
			reqVO.setSessionId(sessionId);
			reqVO.setPage(page);
			reqVO.setPageSize(pageSize);
			reqVO.setLastMessageId(lastMessageId);

			Map<String, Object> result = chatService.getMessageList(reqVO, userId);
			return Result.successWith(result);
		} catch (Exception e) {
			log.error("获取聊天消息列表失败", e);
			return Result.<Map<String, Object>>error().newCnMsg("获取聊天消息列表失败: " + e.getMessage());
		}
	}

	/**
	 * 发送消息
	 */
	@PostMapping("/send")
	@Operation(summary = "发送消息")
	public Result<ChatMessageRespVO> sendMessage(
			@RequestBody ChatMessageSendReqVO reqVO,
			HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}

		try {
			ChatMessageRespVO message = chatService.sendMessage(userId, reqVO);
			return Result.successWith(message);
		} catch (Exception e) {
			log.error("发送消息失败", e);
			return Result.<ChatMessageRespVO>error().newCnMsg("发送消息失败: " + e.getMessage());
		}
	}

	/**
	 * 标记消息为已读
	 */
	@PostMapping("/read")
	@Operation(summary = "标记消息为已读")
	public Result<?> markAsRead(
			@RequestParam Long sessionId,
			HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}

		try {
			chatService.markAsRead(sessionId, userId);
			return Result.success();
		} catch (Exception e) {
			log.error("标记消息为已读失败", e);
			return Result.<Void>error().newCnMsg("标记消息为已读失败: " + e.getMessage());
		}
	}

	/**
	 * 从自己的会话列表删除该会话，并记下自己的清空位置。对方仍能看到原记录。
	 */
	@DeleteMapping("/sessions/{sessionId}")
	@Operation(summary = "删除自己的会话入口")
	public Result<?> hideSession(@PathVariable Long sessionId, HttpServletRequest request) {
		Long userId = getUserIdFromToken(request);
		if (userId == null) {
			return Result.of(ResultCode.LOGIN_REQUIRED);
		}

		try {
			chatService.hideSession(sessionId, userId);
			return Result.success();
		} catch (Exception e) {
			log.error("删除会话失败", e);
			return Result.<Void>error().newCnMsg("删除会话失败: " + e.getMessage());
		}
	}

	/**
	 * 从Token中获取用户ID
	 */
	private Long getUserIdFromToken(HttpServletRequest request) {
		String token = request.getHeader("Authorization");
		if (token != null && token.startsWith("Bearer ")) {
			token = token.substring(7);
			try {
				return jwtUtil.getUserIdFromToken(token);
			} catch (Exception e) {
				return null;
			}
		}
		return null;
	}
}
