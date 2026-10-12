import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:provider/provider.dart';
import '../../home/widgets/mall_app_bar.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/responsive_app_bar.dart';
import '../../../shared/widgets/mobile_bottom_nav_v2.dart';
import '../../../core/api/chat_api.dart';
import '../../../core/api/http_client.dart';
import '../../../core/api/file_api.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/unread_message_provider.dart';
import '../../../core/l10n/app_localizations.dart';

/// 聊天专用 ScrollPhysics，基于 BouncingScrollPhysics
class ChatScrollPhysics extends ScrollPhysics {
  const ChatScrollPhysics({super.parent});

  @override
  ChatScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ChatScrollPhysics(parent: buildParent(ancestor));
  }

  double frictionFactor(double overscrollFraction) =>
      0.32 * math.pow(1 - overscrollFraction, 2);

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);
    if (!position.outOfRange) return offset;

    final double overscrollPastStart =
        math.max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd =
        math.max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast =
        math.max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        ? frictionFactor(
            (overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;
    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(
      double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) return absDelta * gamma;
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    if (value < position.minScrollExtent &&
        position.minScrollExtent < position.pixels) {
      return value - position.minScrollExtent;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity * 0.91,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  double get minFlingVelocity => kMinFlingVelocity * 2.0;

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        math.min(0.000816 * math.pow(existingVelocity.abs(), 1.967).toDouble(),
            40000.0);
  }

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

/// 即时沟通页面
class ChatPage extends StatefulWidget {
  final int? initialSessionId;
  final int? targetUserId;

  const ChatPage({super.key, this.initialSessionId, this.targetUserId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode(); // 输入框焦点节点
  final List<ChatMessage> _displayedMessages = []; // 当前显示的消息
  bool _isLoadingMore = false; // 是否正在加载更多
  bool _hasMoreMessages = true; // 是否还有更多消息
  bool _showEmojiPicker = false; // 是否显示表情选择器
  bool _isInitializing = true; // 是否正在初始化
  int? _sessionId; // 会话ID
  int? _lastMessageId; // 最后一条消息ID
  static const int _messagesPerPage = 20; // 每页消息数量

  // 管理员/客服相关
  bool _isAdminOrService = false; // 是否是管理员或客服
  List<ChatSession> _sessionList = []; // 会话列表
  int? _selectedSessionId; // 当前选中的会话ID
  bool _isLoadingSessions = false; // 是否正在加载会话列表
  bool _isRefreshingSessions = false; // 是否正在刷新会话列表（用于刷新按钮）

  // 保存 AuthProvider 引用
  AuthProvider? _authProvider;

  // 轮询相关
  Timer? _messagePollingTimer; // 消息轮询定时器
  Timer? _sessionPollingTimer; // 会话列表轮询定时器
  static const Duration _pollingInterval = Duration(seconds: 3); // 轮询间隔
  bool _isPageVisible = true; // 页面是否可见（用户是否在当前页面）

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _scrollController.addListener(_onScroll);

    // 添加生命周期观察者
    WidgetsBinding.instance.addObserver(this);

    // 监听认证状态变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _authProvider?.addListener(_onAuthStateChanged);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final wasVisible = _isPageVisible;
    setState(() {
      _isPageVisible = state == AppLifecycleState.resumed;
    });

    // 如果从不可见变为可见，且有会话打开，标记消息为已读
    if (!wasVisible && _isPageVisible && _sessionId != null) {
      _markMessagesAsRead();
    }
  }

  /// 监听滚动事件
  void _onScroll() {
    // reverse 模式下，滚动到 maxScrollExtent 表示滚动到顶部（加载历史消息的位置）
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50 &&
        !_isLoadingMore &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  /// 监听认证状态变化
  void _onAuthStateChanged() {
    // 如果用户已退出登录，跳转到首页
    if (_authProvider != null && !_authProvider!.isAuthenticated && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();

    // 停止轮询
    _stopMessagePolling();
    _stopSessionPolling();

    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(this);

    // 移除认证状态监听
    _authProvider?.removeListener(_onAuthStateChanged);

    super.dispose();
  }

  /// 检查用户角色
  Future<void> _checkUserRole() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userInfo = authProvider.userInfo;

    if (userInfo != null) {
      setState(() {
        _isAdminOrService = authProvider.isAdmin || authProvider.isService;
      });
    }

    // 所有用户都加载会话列表
    await _loadAllSessions();

    // 如果有目标用户ID，创建/获取会话并选择
    if (widget.targetUserId != null) {
      try {
        debugPrint('🔍 开始创建用户会话，targetUserId: ${widget.targetUserId}');
        final response = await ChatApi.getOrCreateUserSession(widget.targetUserId!);
        debugPrint('🔍 创建会话响应: isSuccess=${response.isSuccess}, data=${response.data}, error=${response.errorMessage}');
        if (response.isSuccess && response.data != null && mounted) {
          final sessionId = response.data!['id'] as int;
          debugPrint('🔍 获取到sessionId: $sessionId');
          // 添加短暂延迟，确保后端完全处理完成
          await Future.delayed(const Duration(milliseconds: 300));
          // 重新加载会话列表以显示新创建的会话
          await _loadAllSessions();
          if (mounted) {
            debugPrint('🔍 开始选择会话: $sessionId');
            await _selectSession(sessionId);
          }
        }
      } catch (e) {
        debugPrint('❌ 创建用户会话失败: $e');
      }
    }
    // 如果有初始会话ID，自动选择该会话
    else if (widget.initialSessionId != null && mounted) {
      await _selectSession(widget.initialSessionId!);
    }
  }

  /// 加载所有会话列表（管理员/客服）
  Future<void> _loadAllSessions({bool isManualRefresh = false}) async {
    // 如果是手动刷新，显示刷新状态
    if (isManualRefresh) {
      setState(() {
        _isRefreshingSessions = true;
      });
    } else if (_isInitializing) {
      // 如果是初始化阶段，显示加载状态
      setState(() {
        _isLoadingSessions = true;
      });
    }

    try {
      final response = await ChatApi.getAllSessions();
      debugPrint('🔍 会话列表响应: isSuccess=${response.isSuccess}, data=${response.data}');
      if (response.isSuccess && response.data != null) {
        final sessions = response.data as List<dynamic>;
        debugPrint('🔍 会话数量: ${sessions.length}');
        setState(() {
          _sessionList = sessions.map((e) => ChatSession.fromJson(e as Map<String, dynamic>)).toList();
          debugPrint('🔍 解析后会话列表长度: ${_sessionList.length}');
          _isLoadingSessions = false;
          _isInitializing = false;
          _isRefreshingSessions = false;
        });

        // 启动会话列表轮询
        if (!isManualRefresh) {
          _startSessionPolling();
        }
      } else {
        setState(() {
          _isLoadingSessions = false;
          _isInitializing = false;
          _isRefreshingSessions = false;
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          SnackBarUtil.showError(context, '${l10n.sessionLoadFailed}: ${response.errorMessage}');
        }
      }
    } catch (e) {
      print('加载会话列表失败: $e');
      setState(() {
        _isLoadingSessions = false;
        _isInitializing = false;
        _isRefreshingSessions = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.sessionLoadFailed}: $e');
      }
    }
  }

  /// 选择会话并加载消息
  Future<void> _selectSession(int sessionId) async {
    if (!mounted) return;

    setState(() {
      _selectedSessionId = sessionId;
      _sessionId = sessionId;
      _displayedMessages.clear();
      _lastMessageId = null;
      _hasMoreMessages = true;
    });

    await _loadInitialMessages();

    // 启动消息轮询
    _startMessagePolling();
  }

  /// 初始化聊天
  Future<void> _initializeChat() async {
    try {
      // 获取或创建会话
      final sessionResponse = await ChatApi.getOrCreateSession();
      if (!sessionResponse.isSuccess || sessionResponse.data == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          SnackBarUtil.showError(context, '${l10n.sessionGetFailed}: ${sessionResponse.errorMessage}');
        }
        setState(() {
          _isInitializing = false;
        });
        return;
      }

      final sessionData = sessionResponse.data as Map<String, dynamic>;
      _sessionId = sessionData['id'] as int?;

      // 加载初始消息
      await _loadInitialMessages();

      // 启动消息轮询
      _startMessagePolling();
    } catch (e) {
      print('初始化聊天失败: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.chatInitFailed}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  /// 加载初始消息（最新的20条）
  Future<void> _loadInitialMessages() async {
    if (_sessionId == null) return;

    try {
      final response = await ChatApi.getMessageList(
        sessionId: _sessionId!,
        page: 1,
        pageSize: _messagesPerPage,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final records = data['records'] as List<dynamic>? ?? [];
        final total = data['total'] as int? ?? 0;

        setState(() {
          _displayedMessages.clear();
          // API返回的消息是按ID降序排列的，需要反转后添加
          final messages = records.map((e) => _convertToMessage(e as Map<String, dynamic>)).toList();
          _displayedMessages.addAll(messages);
          _hasMoreMessages = _displayedMessages.length < total;
          if (_displayedMessages.isNotEmpty) {
            _lastMessageId = _displayedMessages.last.id;
          }
        });

        // 标记消息为已读
        _markMessagesAsRead();
      }
    } catch (e) {
      print('加载初始消息失败: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.messageLoadFailed}: $e');
      }
    }
  }

  /// 标记消息为已读
  Future<void> _markMessagesAsRead() async {
    if (_sessionId == null) return;

    try {
      await ChatApi.markAsRead(_sessionId!);

      // 标记已读后，更新会话列表中对应会话的未读数
      if (_isAdminOrService && mounted) {
        // 管理员/客服：重新加载会话列表以更新未读数
        await _loadAllSessions();
      }

      // 同时刷新全局未读消息数量
      if (mounted) {
        final unreadProvider = Provider.of<UnreadMessageProvider>(context, listen: false);
        unreadProvider.refresh();
      }
    } catch (e) {
      print('标记消息为已读失败: $e');
      // 标记已读失败不影响用户体验，只记录日志
    }
  }

  /// 加载更多消息
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _sessionId == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await ChatApi.getMessageList(
        sessionId: _sessionId!,
        page: 1,
        pageSize: _messagesPerPage,
        lastMessageId: _lastMessageId,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final records = data['records'] as List<dynamic>? ?? [];
        final total = data['total'] as int? ?? 0;

        setState(() {
          if (records.isNotEmpty) {
            final messages = records.map((e) => _convertToMessage(e as Map<String, dynamic>)).toList();
            _displayedMessages.addAll(messages);
            _lastMessageId = _displayedMessages.last.id;
            _hasMoreMessages = _displayedMessages.length < total;
          } else {
            _hasMoreMessages = false;
          }
        });
      }
    } catch (e) {
      print('加载更多消息失败: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.loadMoreFailed}: $e');
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// 转换API数据为消息对象
  ChatMessage _convertToMessage(Map<String, dynamic> data) {
    final senderType = data['senderType'] as int?; // 1-用户，2-客服
    final senderId = data['senderId'] as int?; // 发送者ID

    // 实时从 Provider 获取角色信息
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userInfo?.id;

    // 判断是否是自己发送的消息：直接比较发送者ID
    final isSelf = senderId == currentUserId;

    return ChatMessage(
      id: data['id'] as int,
      content: data['content']?.toString() ?? '',
      isSelf: isSelf,
      isRead: data['isRead'] as bool? ?? true,
      timestamp: DateUtil.parseAsLocalDateTime(data['createTime']) ?? DateTime.now(),
      type: (data['messageType'] as int?) == 2 ? MessageType.image : MessageType.text,
      senderNickname: data['senderNickname']?.toString(),
      senderAvatar: data['senderAvatar']?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    final l10n = AppLocalizations.of(context);

    // 获取标题
    String title = l10n.instantChat;
    if (isMobile && _isAdminOrService && _selectedSessionId != null) {
      // 移动端管理员/客服选择会话后，显示用户昵称
      final session = _sessionList.firstWhere(
        (s) => s.id == _selectedSessionId,
        orElse: () => ChatSession(
          id: 0,
          userId: 0,
          userNickname: l10n.instantChat,
          lastMessage: '',
          serviceUnreadCount: 0,
          userUnreadCount: 0,
          status: 0,
        ),
      );
      title = session.userNickname ?? l10n.instantChat;
    }

    return Scaffold(
      appBar: isMobile
          ? ResponsiveAppBar(
              title: title,
              showBackButton: _selectedSessionId != null,
              onBackPressed: () {
                // 返回到会话列表
                setState(() {
                  _selectedSessionId = null;
                  _sessionId = null;
                  _displayedMessages.clear();
                  _lastMessageId = null;
                  _hasMoreMessages = true;
                });
                // 停止消息轮询
                _stopMessagePolling();
              },
            )
          : const MallAppBar(),
      body: SafeArea(
        child: AppBackground(
          child: Center(
            child: Container(
              constraints: ResponsiveUtil.getContentConstraints(context),
              color: Colors.white,
              child: isMobile
                  ? (_selectedSessionId == null
                      ? _buildSessionList()
                      : _buildChatArea())
                  : Row(
                      children: [
                        _buildSessionList(),
                        Expanded(
                          child: _buildChatArea(),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isMobile ? const MobileBottomNavV2() : null,
    );
  }

  /// 构建会话列表
  Widget _buildSessionList() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      width: isMobile ? double.infinity : 280,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: isMobile
            ? null
            : Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
      ),
      child: _isLoadingSessions
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadAllSessions(isManualRefresh: true),
              child: ListView.builder(
                itemCount: _getSessionListCount(),
                itemBuilder: (context, index) {
                  return _buildSessionListItem(index);
                },
              ),
            ),
    );
  }

  /// 获取会话列表数量
  int _getSessionListCount() {
    if (_isAdminOrService) {
      return _sessionList.length;
    } else {
      // 普通用户：检查是否有客服会话
      final hasServiceSession = _sessionList.any((s) => s.handlerId == null);
      return hasServiceSession ? _sessionList.length : _sessionList.length + 1;
    }
  }

  /// 构建会话列表项
  Widget _buildSessionListItem(int index) {
    if (!_isAdminOrService) {
      // 普通用户：检查是否需要显示默认客服会话
      final hasServiceSession = _sessionList.any((s) => s.handlerId == null);
      if (!hasServiceSession && index == 0) {
        return _buildDefaultServiceSession();
      }
    }

    final sessionIndex = (!_isAdminOrService && !_sessionList.any((s) => s.handlerId == null)) ? index - 1 : index;
    final session = _sessionList[sessionIndex];
    final isSelected = _selectedSessionId == session.id;
    return _buildSessionItem(session, isSelected);
  }

  /// 构建默认客服会话项
  Widget _buildDefaultServiceSession() {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: _createServiceSession,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.onlineChatService,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 从自己的列表删除会话。服务端记下清空位置，再次进入不再拉回旧消息。
  Future<void> _deleteSession(ChatSession session) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.translate('confirm_delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final response = await HttpClient().delete<dynamic>('/chat/sessions/${session.id}');
      if (!mounted) return;
      if (!response.isSuccess) {
        SnackBarUtil.showError(context, '${l10n.deleteFailed}: ${response.errorMessage}');
        return;
      }

      if (_selectedSessionId == session.id) {
        setState(() {
          _selectedSessionId = null;
          _sessionId = null;
          _displayedMessages.clear();
          _lastMessageId = null;
          _hasMoreMessages = true;
        });
        _stopMessagePolling();
      }

      await _loadAllSessions();
      if (!mounted) return;
      Provider.of<UnreadMessageProvider>(context, listen: false).refresh();
      SnackBarUtil.showSuccess(context, l10n.deleteSuccess);
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, '${l10n.deleteFailed}: $e');
      }
    }
  }

  /// 创建客服会话
  Future<void> _createServiceSession() async {
    try {
      final response = await ChatApi.getOrCreateSession();
      if (response.isSuccess && response.data != null && mounted) {
        final sessionId = response.data!['id'] as int;
        await _loadAllSessions();
        if (mounted) {
          await _selectSession(sessionId);
        }
      }
    } catch (e) {
      debugPrint('创建客服会话失败: $e');
    }
  }

  /// 构建单个会话项
  Widget _buildSessionItem(ChatSession session, bool isSelected) {
    final l10n = AppLocalizations.of(context);

    // 获取当前用户ID
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userInfo?.id;

    final unreadCount = session.getUnreadCount(_isAdminOrService, currentUserId);

    debugPrint('🔍 会话 ${session.id}: userId=${session.userId}, handlerId=${session.handlerId}, currentUserId=$currentUserId, userUnread=${session.userUnreadCount}, serviceUnread=${session.serviceUnreadCount}, 显示未读=$unreadCount');

    // 确定显示的头像和昵称
    String? displayAvatar;
    String displayNickname;
    bool isServiceSession = false;

    if (_isAdminOrService) {
      // 客服/管理员：显示普通用户的头像和昵称
      displayAvatar = session.userAvatar;
      displayNickname = session.userNickname ?? l10n.user;
    } else {
      // 普通用户：判断是客服会话还是用户会话
      if (session.handlerId == null) {
        // 客服会话
        isServiceSession = true;
        displayAvatar = null;
        displayNickname = l10n.onlineChatService;
      } else {
        // 用户会话：显示对方信息
        if (session.userId == currentUserId) {
          displayAvatar = session.handlerAvatar;
          displayNickname = session.handlerNickname ?? l10n.user;
        } else {
          displayAvatar = session.userAvatar;
          displayNickname = session.userNickname ?? l10n.user;
        }
      }
    }

    return InkWell(
      onTap: () => _selectSession(session.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            // 用户头像（带未读消息徽章）
            unreadCount > 0
                ? Badge(
                    label: Text(unreadCount.toString()),
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: isServiceSession ? Colors.blue[700] : Colors.grey[300],
                      backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty
                          ? NetworkImage(ImageUtil.getImageUrl(displayAvatar))
                          : null,
                      child: displayAvatar == null || displayAvatar.isEmpty
                          ? Icon(
                              isServiceSession ? Icons.support_agent : Icons.person,
                              color: isServiceSession ? Colors.white : Colors.grey[700],
                              size: 20,
                            )
                          : null,
                    ),
                  )
                : CircleAvatar(
                    radius: 20,
                    backgroundColor: isServiceSession ? Colors.blue[700] : Colors.grey[300],
                    backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty
                        ? NetworkImage(ImageUtil.getImageUrl(displayAvatar))
                        : null,
                    child: displayAvatar == null || displayAvatar.isEmpty
                        ? Icon(
                            isServiceSession ? Icons.support_agent : Icons.person,
                            color: isServiceSession ? Colors.white : Colors.grey[700],
                            size: 20,
                          )
                        : null,
                  ),
            const SizedBox(width: 12),
            // 会话信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 昵称
                      Expanded(
                        child: Text(
                          displayNickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.blue[700] : Colors.grey[800],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 时间
                      if (session.lastMessageTime != null)
                        Text(
                          _formatSessionTime(session.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      const SizedBox(width: 8),
                      // 未读消息数
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.lastMessage.isEmpty ? l10n.noMessages : session.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.delete,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _deleteSession(session),
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建聊天区域
  Widget _buildChatArea() {
    final l10n = AppLocalizations.of(context);
    // 未选择会话时，显示提示
    if (_selectedSessionId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.selectSessionPrompt,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: _buildMessageArea(),
            ),
            _buildInputArea(),
          ],
        ),
        // 浮动的表情选择器
        if (_showEmojiPicker)
          Positioned(
            bottom: 80,
            left: 16,
            width: 380,
            child: _buildEmojiPicker(),
          ),
      ],
    );
  }

  /// 构建顶部设置栏
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // 移动端返回按钮
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () {
                setState(() {
                  _selectedSessionId = null;
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 10),
          ],
          // 头像
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.support_agent, color: Colors.blue[700], size: 18),
          ),
          const SizedBox(width: 10),
          // 昵称
          Text(
            l10n.onlineChatService,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // 通知按钮
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20),
            onPressed: _handleNotification,
            tooltip: l10n.notification,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 构建消息区域
  Widget _buildMessageArea() {
    return Container(
      color: Colors.grey[50],
      child: ListView.builder(
        controller: _scrollController,
        physics: const ChatScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        reverse: true, // 关键：从底部向上构建
        padding: const EdgeInsets.all(16),
        itemCount: _displayedMessages.length + 1, // +1 for load more button
        itemBuilder: (context, index) {
          // 在 reverse 模式下，第一项是最底部（最新消息后面的加载按钮位置）
          // 最后一项是最顶部（加载更多按钮）
          if (index == _displayedMessages.length) {
            return _buildLoadMoreWidget();
          }
          // 显示消息（reverse 模式下索引是反的）
          return _buildMessageItem(_displayedMessages[index]);
        },
      ),
    );
  }

  /// 构建加载更多组件
  Widget _buildLoadMoreWidget() {
    final l10n = AppLocalizations.of(context);
    if (_isLoadingMore) {
      // 正在加载
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (!_hasMoreMessages) {
      // 没有更多消息
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(
          l10n.noMoreMessages,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      );
    } else {
      // 显示加载更多按钮
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: TextButton(
          onPressed: _loadMoreMessages,
          child: Text(
            l10n.loadMore,
            style: TextStyle(fontSize: 13, color: Colors.blue[700]),
          ),
        ),
      );
    }
  }

  /// 构建单条消息
  Widget _buildMessageItem(ChatMessage message) {
    // 计算消息最大宽度：内容区宽度(1080) - 左右padding(32) - 两个头像(64) - 间距(16)
    const double maxMessageWidth = 1080 - 32 - 64 - 16;

    // 获取当前用户头像
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserAvatar = authProvider.userInfo?.avatar;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isSelf) ...[
            // 对方头像 - 使用真实头像
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              backgroundImage: message.senderAvatar != null && message.senderAvatar!.isNotEmpty
                  ? NetworkImage(ImageUtil.getImageUrl(message.senderAvatar!))
                  : null,
              child: message.senderAvatar == null || message.senderAvatar!.isEmpty
                  ? Icon(Icons.person, color: Colors.blue[700], size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          // 消息内容
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxMessageWidth),
              child: Column(
                crossAxisAlignment: message.isSelf
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // 对方消息显示昵称
                  if (!message.isSelf && message.senderNickname != null && message.senderNickname!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        message.senderNickname!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  // 根据消息类型显示不同内容
                  message.type == MessageType.image
                      ? _buildImageMessage(message)
                      : _buildTextMessage(message),
                  const SizedBox(height: 4),
                  // 已读/未读状态
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      if (message.isSelf) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead ? Colors.blue[700] : Colors.grey[500],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isSelf) ...[
            const SizedBox(width: 8),
            // 自己的头像 - 使用当前用户头像
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: currentUserAvatar != null && currentUserAvatar.isNotEmpty
                  ? NetworkImage(ImageUtil.getImageUrl(currentUserAvatar))
                  : null,
              child: currentUserAvatar == null || currentUserAvatar.isEmpty
                  ? Icon(Icons.person, color: Colors.grey[700], size: 16)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建文本消息
  Widget _buildTextMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: message.isSelf ? Colors.blue[100] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SelectableText(
        message.content,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  /// 构建图片消息
  Widget _buildImageMessage(ChatMessage message) {
    return GestureDetector(
      onTap: () => _showImagePreview(message.content),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            ImageUtil.getImageUrl(message.content),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 显示图片预览
  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Image.network(ImageUtil.getImageUrl(imageUrl)),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          // 表情按钮
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: _handleEmoji,
            tooltip: l10n.emoji,
            style: IconButton.styleFrom(
              backgroundColor: _showEmojiPicker ? Colors.blue[100] : null,
            ),
          ),
          // 图片按钮
          IconButton(
            icon: const Icon(Icons.image_outlined),
            onPressed: _handleImage,
            tooltip: l10n.image,
          ),
          const SizedBox(width: 8),
          // 输入框
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                // Enter 键发送消息
                const SingleActivator(LogicalKeyboardKey.enter): () {
                  _handleSend();
                },
                // Alt+Enter 换行
                const SingleActivator(LogicalKeyboardKey.enter, alt: true): () {
                  final controller = _messageController;
                  final text = controller.text;
                  final selection = controller.selection;
                  final newText = text.substring(0, selection.start) +
                      '\n' +
                      text.substring(selection.end);
                  controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(
                      offset: selection.start + 1,
                    ),
                  );
                },
              },
              child: TextField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                maxLines: 7,
                minLines: 1,
                style: const TextStyle(fontSize: 15),
                cursorWidth: 1.5,
                decoration: InputDecoration(
                  hintText: l10n.enterMessage,
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 发送按钮
          ElevatedButton(
            onPressed: _handleSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(80, 48),
            ),
            child: Text(l10n.send),
          ),
        ],
      ),
    );
  }

  /// 构建表情选择器
  Widget _buildEmojiPicker() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _emojiList.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              _insertEmoji(_emojiList[index]);
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: AnimatedEmoji(
                _emojiList[index],
                size: 20,
                repeat: true,
                source: AnimatedEmojiSource.asset,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 表情列表
  static final List<AnimatedEmojiData> _emojiList = [
    AnimatedEmojis.smile,
    AnimatedEmojis.laughing,
    AnimatedEmojis.blush,
    AnimatedEmojis.heartEyes,
    AnimatedEmojis.kissing,
    AnimatedEmojis.wink,
    AnimatedEmojis.stuckOutTongue,
    AnimatedEmojis.worried,
    AnimatedEmojis.anguished,
    AnimatedEmojis.grimacing,
    AnimatedEmojis.expressionless,
    AnimatedEmojis.unamused,
    AnimatedEmojis.sweat,
    AnimatedEmojis.weary,
    AnimatedEmojis.pensive,
    AnimatedEmojis.cry,
    AnimatedEmojis.joy,
    AnimatedEmojis.astonished,
    AnimatedEmojis.angry,
    AnimatedEmojis.rage,
    AnimatedEmojis.triumph,
    AnimatedEmojis.sleepy,
    AnimatedEmojis.yum,
    AnimatedEmojis.mask,
    AnimatedEmojis.dizzyFace,
    AnimatedEmojis.neutralFace,
    AnimatedEmojis.alien,
    AnimatedEmojis.yellowHeart,
    AnimatedEmojis.blueHeart,
    AnimatedEmojis.purpleHeart,
    AnimatedEmojis.greenHeart,
    AnimatedEmojis.brokenHeart,
    AnimatedEmojis.twoHearts,
    AnimatedEmojis.sparklingHeart,
    AnimatedEmojis.collision,
    AnimatedEmojis.fire,
    AnimatedEmojis.rocket,
    AnimatedEmojis.clap,
    AnimatedEmojis.wave,
    AnimatedEmojis.eyes,
    AnimatedEmojis.sunWithFace,
    AnimatedEmojis.grin,
    AnimatedEmojis.flushed,
    AnimatedEmojis.relieved,
    AnimatedEmojis.grinning,
    AnimatedEmojis.smirk,
    AnimatedEmojis.cupid,
    AnimatedEmojis.balloon,
    // 重复一些常用表情
    AnimatedEmojis.smile,
    AnimatedEmojis.laughing,
    AnimatedEmojis.heartEyes,
    AnimatedEmojis.wink,
    AnimatedEmojis.joy,
    AnimatedEmojis.rocket,
    AnimatedEmojis.fire,
    AnimatedEmojis.clap,
    AnimatedEmojis.wave,
    AnimatedEmojis.yellowHeart,
    AnimatedEmojis.blueHeart,
    AnimatedEmojis.purpleHeart,
    AnimatedEmojis.greenHeart,
    AnimatedEmojis.brokenHeart,
    AnimatedEmojis.twoHearts,
    // 重复表情以达到200个 - 第1组
    AnimatedEmojis.smile,
    AnimatedEmojis.laughing,
    AnimatedEmojis.blush,
    AnimatedEmojis.heartEyes,
    AnimatedEmojis.kissing,
    AnimatedEmojis.wink,
    AnimatedEmojis.stuckOutTongue,
    AnimatedEmojis.worried,
    AnimatedEmojis.anguished,
    AnimatedEmojis.grimacing,
    AnimatedEmojis.expressionless,
    AnimatedEmojis.unamused,
    AnimatedEmojis.sweat,
    AnimatedEmojis.weary,
    AnimatedEmojis.pensive,
    AnimatedEmojis.cry,
    AnimatedEmojis.joy,
    AnimatedEmojis.astonished,
    AnimatedEmojis.angry,
    AnimatedEmojis.rage,
    // 第2组
    AnimatedEmojis.triumph,
    AnimatedEmojis.sleepy,
    AnimatedEmojis.yum,
    AnimatedEmojis.mask,
    AnimatedEmojis.dizzyFace,
    AnimatedEmojis.neutralFace,
    AnimatedEmojis.alien,
    AnimatedEmojis.yellowHeart,
    AnimatedEmojis.blueHeart,
    AnimatedEmojis.purpleHeart,
    AnimatedEmojis.greenHeart,
    AnimatedEmojis.brokenHeart,
    AnimatedEmojis.twoHearts,
    AnimatedEmojis.sparklingHeart,
    AnimatedEmojis.collision,
    AnimatedEmojis.fire,
    AnimatedEmojis.rocket,
    AnimatedEmojis.clap,
    AnimatedEmojis.wave,
    AnimatedEmojis.eyes,
    // 第3组
    AnimatedEmojis.sunWithFace,
    AnimatedEmojis.grin,
    AnimatedEmojis.flushed,
    AnimatedEmojis.relieved,
    AnimatedEmojis.grinning,
    AnimatedEmojis.smirk,
    AnimatedEmojis.cupid,
    AnimatedEmojis.balloon,
    AnimatedEmojis.smile,
    AnimatedEmojis.laughing,
    AnimatedEmojis.blush,
    AnimatedEmojis.heartEyes,
    AnimatedEmojis.kissing,
    AnimatedEmojis.wink,
    AnimatedEmojis.stuckOutTongue,
    AnimatedEmojis.worried,
    AnimatedEmojis.anguished,
    AnimatedEmojis.grimacing,
    // 第4组
    AnimatedEmojis.expressionless,
    AnimatedEmojis.unamused,
    AnimatedEmojis.sweat,
    AnimatedEmojis.weary,
    AnimatedEmojis.pensive,
    AnimatedEmojis.cry,
    AnimatedEmojis.joy,
    AnimatedEmojis.astonished,
    AnimatedEmojis.angry,
    AnimatedEmojis.rage,
    AnimatedEmojis.triumph,
    AnimatedEmojis.sleepy,
    AnimatedEmojis.yum,
    AnimatedEmojis.mask,
    AnimatedEmojis.dizzyFace,
    AnimatedEmojis.neutralFace,
    AnimatedEmojis.alien,
    AnimatedEmojis.yellowHeart,
    // 第5组
    AnimatedEmojis.blueHeart,
    AnimatedEmojis.purpleHeart,
    AnimatedEmojis.greenHeart,
    AnimatedEmojis.brokenHeart,
    AnimatedEmojis.twoHearts,
    AnimatedEmojis.sparklingHeart,
    AnimatedEmojis.collision,
    AnimatedEmojis.fire,
    AnimatedEmojis.rocket,
    AnimatedEmojis.clap,
    // 第6组
    AnimatedEmojis.wave,
    AnimatedEmojis.eyes,
    AnimatedEmojis.sunWithFace,
    AnimatedEmojis.grin,
    AnimatedEmojis.flushed,
    AnimatedEmojis.relieved,
    AnimatedEmojis.grinning,
    AnimatedEmojis.smirk,
    AnimatedEmojis.cupid,
    AnimatedEmojis.balloon,
    // 第7组
    AnimatedEmojis.smile,
    AnimatedEmojis.laughing,
    AnimatedEmojis.blush,
    AnimatedEmojis.heartEyes,
    AnimatedEmojis.kissing,
    AnimatedEmojis.wink,
    AnimatedEmojis.stuckOutTongue,
    AnimatedEmojis.worried,
    AnimatedEmojis.anguished,
    AnimatedEmojis.grimacing,
    // 第8组
    AnimatedEmojis.expressionless,
    AnimatedEmojis.unamused,
    AnimatedEmojis.sweat,
    AnimatedEmojis.weary,
    AnimatedEmojis.pensive,
    AnimatedEmojis.cry,
    AnimatedEmojis.joy,
    AnimatedEmojis.astonished,
    AnimatedEmojis.angry,
    AnimatedEmojis.rage,
    // 第9组
    AnimatedEmojis.triumph,
    AnimatedEmojis.sleepy,
    AnimatedEmojis.yum,
    AnimatedEmojis.mask,
    AnimatedEmojis.dizzyFace,
    AnimatedEmojis.neutralFace,
    AnimatedEmojis.alien,
    AnimatedEmojis.yellowHeart,
    AnimatedEmojis.blueHeart,
    AnimatedEmojis.purpleHeart,
    // 第10组 - 最后一组
    AnimatedEmojis.greenHeart,
    AnimatedEmojis.brokenHeart,
    AnimatedEmojis.twoHearts,
    AnimatedEmojis.sparklingHeart,
    AnimatedEmojis.collision,
    AnimatedEmojis.fire,
    AnimatedEmojis.rocket,
    AnimatedEmojis.clap,
    AnimatedEmojis.wave,
    AnimatedEmojis.eyes,
  ];

  /// 插入表情到输入框
  void _insertEmoji(AnimatedEmojiData emojiData) {
    final controller = _messageController;
    final text = controller.text;
    final selection = controller.selection;
    final emoji = emojiData.toUnicodeEmoji(); // 获取实际的 Unicode emoji 字符

    // 确保 selection 有效，并且 start 和 end 在有效范围内
    int start = text.length;
    int end = text.length;

    if (selection.isValid && selection.start >= 0 && selection.start <= text.length) {
      start = selection.start;
    }
    if (selection.isValid && selection.end >= 0 && selection.end <= text.length) {
      end = selection.end;
    }

    final newText = text.substring(0, start) +
        emoji +
        text.substring(end);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + emoji.length,
      ),
    );
    // 关闭表情选择器
    setState(() {
      _showEmojiPicker = false;
    });
    _inputFocusNode.requestFocus();
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final localTime = time.toLocal();
    final diff = now.difference(localTime);

    if (diff.inMinutes < 1) {
      return l10n.justNow;
    } else if (diff.inMinutes < 60) {
      return l10n.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 365) {
      return '${localTime.month}/${localTime.day} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
    } else {
      return '${localTime.year}/${localTime.month}/${localTime.day} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化会话列表时间
  String _formatSessionTime(DateTime time) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(time);

    // 5分钟内显示"刚刚"
    if (diff.inMinutes < 5) {
      return l10n.justNow;
    }
    // 1小时内显示"几分钟前"
    else if (diff.inMinutes < 60) {
      return l10n.minutesAgo(diff.inMinutes);
    }
    // 24小时内显示"几小时前"
    else if (diff.inHours < 24) {
      return l10n.hoursAgo(diff.inHours);
    }
    // 昨天
    else if (diff.inDays == 1) {
      return l10n.yesterday;
    }
    // 前天
    else if (diff.inDays == 2) {
      return l10n.dayBeforeYesterday;
    }
    // 7天内显示星期几
    else if (diff.inDays < 7) {
      final weekdays = [l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday, l10n.friday, l10n.saturday, l10n.sunday];
      return weekdays[time.weekday - 1];
    }
    // 超过7天显示年月日
    else {
      final isSameYear = now.year == time.year;
      if (isSameYear) {
        return '${time.month}/${time.day}';
      } else {
        return '${time.year}/${time.month}/${time.day}';
      }
    }
  }

  /// 处理通知
  void _handleNotification() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.notificationFeaturePending)),
    );
  }

  /// 处理表情
  void _handleEmoji() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  /// 处理图片
  Future<void> _handleImage() async {
    final l10n = AppLocalizations.of(context);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // 显示上传中的临时消息
        final tempMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          content: l10n.imageUploading,
          isSelf: true,
          isRead: false,
          timestamp: DateTime.now(),
          type: MessageType.text,
        );

        setState(() {
          _displayedMessages.insert(0, tempMessage);
        });

        try {
          // 1. 先上传图片到服务器
          final imageBytes = await image.readAsBytes();
          final fileName = image.name;

          final uploadResponse = await FileApi.uploadFile(
            filePath: image.path,
            fileName: fileName,
            fileBytes: imageBytes,
            pathPrefix: 'chat',
          );

        if (!uploadResponse.isSuccess || uploadResponse.data == null) {
          setState(() {
            _displayedMessages.removeWhere((m) => m.id == tempMessage.id);
          });
          if (mounted) {
            SnackBarUtil.showError(context, '${l10n.imageUploadFailed}: ${uploadResponse.errorMessage}');
          }
          return;
        }

        final filename = uploadResponse.data!;
        print('图片上传成功，文件名: $filename');

        // 使用文件名发送图片消息
        final response = await ChatApi.sendMessage(
          sessionId: _sessionId,
          messageType: 2, // 图片消息
          content: filename,
        );

        if (response.isSuccess && response.data != null) {
          final messageData = response.data as Map<String, dynamic>;
          final newMessage = _convertToMessage(messageData);

          setState(() {
            _displayedMessages.removeWhere((m) => m.id == tempMessage.id);
            _displayedMessages.insert(0, newMessage);
          });
        } else {
          setState(() {
            _displayedMessages.removeWhere((m) => m.id == tempMessage.id);
          });
          if (mounted) {
            SnackBarUtil.showError(context, '${l10n.imageSendFailed}: ${response.errorMessage}');
          }
        }
      } catch (e) {
        print('发送图片失败: $e');
        setState(() {
          _displayedMessages.removeWhere((m) => m.id == tempMessage.id);
        });
        if (mounted) {
          SnackBarUtil.showError(context, '${l10n.imageSendFailed}: $e');
        }
      }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, '${l10n.selectImageFailed}: $e');
      }
    }
  }

  /// 启动消息轮询
  void _startMessagePolling() {
    _stopMessagePolling();
    _messagePollingTimer = Timer.periodic(_pollingInterval, (timer) {
      _pollMessages();
    });
  }

  /// 停止消息轮询
  void _stopMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = null;
  }

  /// 轮询消息
  Future<void> _pollMessages() async {
    if (_sessionId == null || !mounted) return;

    try {
      // 获取最新的消息列表（只获取第一页）
      final response = await ChatApi.getMessageList(
        sessionId: _sessionId!,
        page: 1,
        pageSize: _messagesPerPage,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final records = data['records'] as List<dynamic>? ?? [];

        if (records.isEmpty) return;

        // 转换消息
        final latestMessages = records.map((e) => _convertToMessage(e as Map<String, dynamic>)).toList();

        // 检查是否有新消息或消息状态更新
        bool hasUpdates = false;
        bool hasNewMessages = false;

        // 如果当前没有消息，直接添加
        if (_displayedMessages.isEmpty) {
          setState(() {
            _displayedMessages.addAll(latestMessages);
          });
          return;
        }

        // 检查新消息（ID比当前最小的ID还要大的消息）
        final currentMinId = _displayedMessages.isEmpty ? 0 : _displayedMessages.first.id;
        final newMessages = latestMessages.where((msg) => msg.id > currentMinId).toList();

        if (newMessages.isNotEmpty) {
          hasUpdates = true;
          hasNewMessages = true;
          setState(() {
            // 新消息插入到列表开头（因为是reverse模式）
            for (var msg in newMessages.reversed) {
              _displayedMessages.insert(0, msg);
            }
          });
        }

        // 检查已读状态更新
        for (var latestMsg in latestMessages) {
          final index = _displayedMessages.indexWhere((m) => m.id == latestMsg.id);
          if (index != -1) {
            final currentMsg = _displayedMessages[index];
            // 如果已读状态发生变化
            if (currentMsg.isRead != latestMsg.isRead) {
              hasUpdates = true;
              setState(() {
                _displayedMessages[index] = latestMsg;
              });
            }
          }
        }

        // 只有在页面可见且有新消息时，才自动标记为已读
        if (hasNewMessages && _isPageVisible) {
          _markMessagesAsRead();
          // 刷新会话列表以更新最新消息
          _pollSessions();
        }
      }
    } catch (e) {
      print('轮询消息失败: $e');
      // 轮询失败不影响用户体验，只记录日志
    }
  }

  /// 启动会话列表轮询（管理员/客服）
  void _startSessionPolling() {
    _stopSessionPolling();
    _sessionPollingTimer = Timer.periodic(_pollingInterval, (timer) {
      _pollSessions();
    });
  }

  /// 停止会话列表轮询
  void _stopSessionPolling() {
    _sessionPollingTimer?.cancel();
    _sessionPollingTimer = null;
  }

  /// 轮询会话列表
  Future<void> _pollSessions() async {
    if (!mounted) return;

    try {
      debugPrint('🔄 开始轮询会话列表');
      final response = await ChatApi.getAllSessions();
      if (response.isSuccess && response.data != null) {
        final sessions = response.data as List<dynamic>;
        final newSessionList = sessions.map((e) => ChatSession.fromJson(e as Map<String, dynamic>)).toList();

        debugPrint('🔄 轮询到 ${newSessionList.length} 个会话');

        // 检查是否有变化
        bool hasChanges = false;
        if (_sessionList.length != newSessionList.length) {
          hasChanges = true;
          debugPrint('🔄 会话数量变化: ${_sessionList.length} -> ${newSessionList.length}');
        } else {
          // 创建旧会话的ID映射，用于快速查找
          final oldSessionMap = {for (var s in _sessionList) s.id: s};

          for (final newSession in newSessionList) {
            final oldSession = oldSessionMap[newSession.id];
            if (oldSession == null) {
              // 新会话
              hasChanges = true;
              debugPrint('🔄 发现新会话: ${newSession.id}');
              break;
            }
            if (oldSession.lastMessage != newSession.lastMessage ||
                oldSession.serviceUnreadCount != newSession.serviceUnreadCount ||
                oldSession.userUnreadCount != newSession.userUnreadCount) {
              hasChanges = true;
              debugPrint('🔄 会话 ${oldSession.id} 有变化: lastMsg="${oldSession.lastMessage}"->"${newSession.lastMessage}", serviceUnread=${oldSession.serviceUnreadCount}->${newSession.serviceUnreadCount}, userUnread=${oldSession.userUnreadCount}->${newSession.userUnreadCount}');
              break;
            }
          }

          // 检查是否有会话被删除
          if (!hasChanges) {
            final newSessionIds = newSessionList.map((s) => s.id).toSet();
            for (final oldSession in _sessionList) {
              if (!newSessionIds.contains(oldSession.id)) {
                hasChanges = true;
                debugPrint('🔄 会话 ${oldSession.id} 被删除');
                break;
              }
            }
          }
        }

        if (hasChanges) {
          debugPrint('✅ 更新会话列表');
          setState(() {
            _sessionList = newSessionList;
          });
        } else {
          debugPrint('⏭️ 会话列表无变化');
        }
      }
    } catch (e) {
      debugPrint('❌ 轮询会话列表失败: $e');
    }
  }


  /// 处理发送
  Future<void> _handleSend() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // 先清空输入框并添加临时消息到界面
    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      content: content,
      isSelf: true,
      isRead: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _displayedMessages.insert(0, tempMessage);
      _messageController.clear();
    });

    // 发送后重新获取焦点
    _inputFocusNode.requestFocus();

    try {
      // 调用API发送消息
      final response = await ChatApi.sendMessage(
        sessionId: _sessionId,
        messageType: 1, // 文本消息
        content: content,
      );

      if (response.isSuccess && response.data != null) {
        final messageData = response.data as Map<String, dynamic>;
        final newMessage = _convertToMessage(messageData);

        setState(() {
          // 移除临时消息，添加真实消息
          _displayedMessages.removeWhere((m) => m.id == tempMessage.id);
          _displayedMessages.insert(0, newMessage);
        });
      } else {
        // 发送失败，移除临时消息
        setState(() {
          _displayedMessages.removeWhere((m) => m.id == tempMessage.id);
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          SnackBarUtil.showError(context, '${l10n.sendFailed}: ${response.errorMessage}');
        }
      }
    } catch (e) {
      print('发送消息失败: $e');
      // 发送失败，移除临时消息
      setState(() {
        _displayedMessages.removeWhere((m) => m.id == tempMessage.id);
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.sendFailed}: $e');
      }
    }
  }
}

/// 消息类型枚举
enum MessageType {
  text,
  image,
}

/// 聊天消息模型
class ChatMessage {
  final int id;
  final String content;
  final bool isSelf;
  final bool isRead;
  final DateTime timestamp;
  final MessageType type;
  final String? senderNickname;
  final String? senderAvatar;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isSelf,
    required this.isRead,
    required this.timestamp,
    this.type = MessageType.text,
    this.senderNickname,
    this.senderAvatar,
  });
}

/// 聊天会话模型
class ChatSession {
  final int id;
  final int userId;
  final int? handlerId;
  final String? userNickname;
  final String? userAvatar;
  final String? handlerNickname;
  final String? handlerAvatar;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int serviceUnreadCount;
  final int userUnreadCount;
  final int status;

  ChatSession({
    required this.id,
    required this.userId,
    this.handlerId,
    this.userNickname,
    this.userAvatar,
    this.handlerNickname,
    this.handlerAvatar,
    required this.lastMessage,
    this.lastMessageTime,
    required this.serviceUnreadCount,
    required this.userUnreadCount,
    required this.status,
  });

  /// 获取当前用户应该看到的未读数
  int getUnreadCount(bool isAdminOrService, int? currentUserId) {
    if (isAdminOrService) {
      return serviceUnreadCount;
    } else {
      // 普通用户：判断是userId还是handlerId
      if (userId == currentUserId) {
        // 当前用户是userId，返回userUnreadCount
        return userUnreadCount;
      } else if (handlerId == currentUserId) {
        // 当前用户是handlerId，返回serviceUnreadCount
        return serviceUnreadCount;
      } else {
        // 默认返回userUnreadCount
        return userUnreadCount;
      }
    }
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as int,
      userId: json['userId'] as int,
      handlerId: json['handlerId'] as int?,
      userNickname: json['userNickname']?.toString(),
      userAvatar: json['userAvatar']?.toString(),
      handlerNickname: json['handlerNickname']?.toString(),
      handlerAvatar: json['handlerAvatar']?.toString(),
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateUtil.parseAsLocalDateTime(json['lastMessageTime'].toString())
          : null,
      serviceUnreadCount: json['serviceUnreadCount'] as int? ?? 0,
      userUnreadCount: json['userUnreadCount'] as int? ?? 0,
      status: json['status'] as int? ?? 1,
    );
  }
}
