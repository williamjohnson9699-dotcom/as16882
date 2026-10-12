import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/unread_message_provider.dart';
import '../../core/services/router_service.dart';

/// 通用的聊天浮动按钮
/// 仅在用户登录后显示，并显示未读消息数量
class ChatFloatingButton extends StatelessWidget {
  const ChatFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    // 未登录时不显示按钮
    if (!isAuthenticated) {
      return const SizedBox.shrink();
    }

    return Consumer<UnreadMessageProvider>(
      builder: (context, unreadProvider, _) {
        final unreadCount = unreadProvider.unreadCount;

        return unreadCount > 0
            ? Badge(
                label: Text(
                  unreadCount.toString(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.red,
                textColor: Colors.white,
                child: FloatingActionButton(
                  onPressed: () {
                    context.go(RoutePaths.chat);
                  },
                  backgroundColor: Colors.blue[700],
                  child: const Icon(Icons.chat, color: Colors.white),
                ),
              )
            : FloatingActionButton(
                onPressed: () {
                  context.go(RoutePaths.chat);
                },
                backgroundColor: Colors.blue[700],
                child: const Icon(Icons.chat, color: Colors.white),
              );
      },
    );
  }
}
