import 'http_client.dart';
import '../models/api_response.dart';

/// 聊天API接口
class ChatApi {
  static final HttpClient _client = HttpClient();

  /// 获取或创建聊天会话
  static Future<ApiResponse<Map<String, dynamic>>> getOrCreateSession() async {
    return await _client.get('/chat/session');
  }

  /// 获取或创建与指定用户的聊天会话
  static Future<ApiResponse<Map<String, dynamic>>> getOrCreateUserSession(int targetUserId) async {
    return await _client.get('/chat/session/$targetUserId');
  }

  /// 获取所有聊天会话列表（管理员/客服使用）
  static Future<ApiResponse<List<dynamic>>> getAllSessions() async {
    return await _client.get('/chat/sessions');
  }

  /// 获取聊天消息列表
  /// [sessionId] 会话ID
  /// [page] 页码
  /// [pageSize] 每页数量
  /// [lastMessageId] 最后一条消息ID（用于分页加载）
  static Future<ApiResponse<Map<String, dynamic>>> getMessageList({
    required int sessionId,
    int page = 1,
    int pageSize = 20,
    int? lastMessageId,
  }) async {
    final Map<String, dynamic> params = {
      'sessionId': sessionId,
      'page': page,
      'pageSize': pageSize,
    };
    if (lastMessageId != null) {
      params['lastMessageId'] = lastMessageId;
    }
    return await _client.get(
      '/chat/messages',
      queryParameters: params,
    );
  }

  /// 发送消息
  /// [sessionId] 会话ID（可选）
  /// [messageType] 消息类型：1-文本，2-图片
  /// [content] 消息内容
  static Future<ApiResponse<Map<String, dynamic>>> sendMessage({
    int? sessionId,
    required int messageType,
    required String content,
  }) async {
    return await _client.post(
      '/chat/send',
      data: {
        'sessionId': sessionId,
        'messageType': messageType,
        'content': content,
      },
    );
  }

  /// 标记消息为已读
  /// [sessionId] 会话ID
  static Future<ApiResponse<void>> markAsRead(int sessionId) async {
    return await _client.post(
      '/chat/read',
      queryParameters: {'sessionId': sessionId},
    );
  }

  /// 获取总未读消息数
  static Future<ApiResponse<int>> getTotalUnreadCount({required bool isAdminOrService, int? currentUserId}) async {
    final response = await _client.get('/chat/sessions');
    if (response.isSuccess && response.data != null) {
      final sessions = response.data as List<dynamic>;
      int totalUnread = 0;
      for (var session in sessions) {
        final userId = session['userId'] as int?;
        final handlerId = session['handlerId'] as int?;

        if (isAdminOrService) {
          totalUnread += (session['serviceUnreadCount'] as int? ?? 0);
        } else {
          // 普通用户：根据在会话中的角色累加未读数
          if (userId == currentUserId) {
            totalUnread += (session['userUnreadCount'] as int? ?? 0);
          } else if (handlerId == currentUserId) {
            totalUnread += (session['serviceUnreadCount'] as int? ?? 0);
          }
        }
      }
      return ApiResponse<int>(
        code: 101100,
        data: totalUnread,
      );
    }
    return ApiResponse<int>(
      code: response.code,
      message: response.message,
      cnMsg: response.cnMsg ?? '获取未读数失败',
    );
  }
}
