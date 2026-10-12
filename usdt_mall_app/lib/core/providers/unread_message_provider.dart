import 'package:flutter/foundation.dart';
import 'dart:async';
import '../api/chat_api.dart';
import 'auth_provider.dart';

/// 未读消息管理 Provider
class UnreadMessageProvider extends ChangeNotifier {
  int _unreadCount = 0;
  Timer? _pollingTimer;
  AuthProvider? _authProvider;
  bool _wasAuthenticated = false;

  int get unreadCount => _unreadCount;

  /// 初始化
  void init(AuthProvider authProvider) {
    _authProvider = authProvider;
    _authProvider?.addListener(_onAuthStateChanged);

    // 检查初始认证状态
    _checkAuthAndStartPolling();
  }

  /// 检查认证状态并启动轮询
  Future<void> _checkAuthAndStartPolling() async {
    if (_authProvider == null) return;

    // 如果正在加载，等待加载完成
    while (_authProvider!.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _wasAuthenticated = _authProvider!.isAuthenticated;

    // 如果已登录，启动轮询
    if (_wasAuthenticated) {
      await _loadUnreadCount();
      _startPolling();
    }
  }

  /// 监听认证状态变化
  void _onAuthStateChanged() {
    final isAuthenticated = _authProvider?.isAuthenticated ?? false;

    // 从未登录变为已登录
    if (!_wasAuthenticated && isAuthenticated) {
      _loadUnreadCount();
      _startPolling();
    }
    // 从已登录变为未登录
    else if (_wasAuthenticated && !isAuthenticated) {
      _stopPolling();
      _unreadCount = 0;
      notifyListeners();
    }

    _wasAuthenticated = isAuthenticated;
  }

  /// 启动轮询
  void _startPolling() {
    // 先取消已有的定时器
    _pollingTimer?.cancel();
    // 创建新的定时器，每5秒刷新一次
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadUnreadCount();
    });
  }

  /// 停止轮询
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// 加载未读消息数量
  Future<void> _loadUnreadCount() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) {
      return;
    }

    try {
      final isAdminOrService = _authProvider!.isAdmin || _authProvider!.isService;
      final currentUserId = _authProvider!.userInfo?.id;
      final response = await ChatApi.getTotalUnreadCount(
        isAdminOrService: isAdminOrService,
        currentUserId: currentUserId,
      );

      if (response.isSuccess && response.data != null) {
        _unreadCount = response.data as int;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载未读消息数量失败: $e');
    }
  }

  /// 手动刷新未读数量（用于发送消息后立即刷新）
  Future<void> refresh() async {
    await _loadUnreadCount();
  }

  @override
  void dispose() {
    _stopPolling();
    _authProvider?.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
