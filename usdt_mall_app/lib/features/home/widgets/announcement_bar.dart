import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/api/announcement_management_api.dart';

/// 系统公告滚动组件
class AnnouncementBar extends StatefulWidget {
  final ValueChanged<bool>? onAnnouncementStatusChanged;

  const AnnouncementBar({
    super.key,
    this.onAnnouncementStatusChanged,
  });

  @override
  State<AnnouncementBar> createState() => _AnnouncementBarState();
}

class _AnnouncementBarState extends State<AnnouncementBar> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  List<String> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  /// 加载公告数据
  Future<void> _loadAnnouncements() async {
    try {
      final response = await AnnouncementManagementApi.getAnnouncementList();

      if (response.isSuccess && response.data != null) {
        final announcements = response.data as List<dynamic>;
        final announcementList = announcements
            .map((item) => item['content']?.toString() ?? '')
            .where((content) => content.isNotEmpty)
            .toList();

        setState(() {
          _announcements = announcementList;
          _isLoading = false;
        });

        // 通知父组件是否有公告
        widget.onAnnouncementStatusChanged?.call(_announcements.isNotEmpty);

        // 加载完成后启动自动滚动
        if (_announcements.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAutoScroll();
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        // 通知父组件没有公告
        widget.onAnnouncementStatusChanged?.call(false);
      }
    } catch (e) {
      print('加载公告失败: $e');
      setState(() {
        _isLoading = false;
      });
      // 通知父组件没有公告
      widget.onAnnouncementStatusChanged?.call(false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// 启动自动滚动
  void _startAutoScroll() {
    if (!_scrollController.hasClients) return;

    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_scrollController.hasClients) {
        timer.cancel();
        return;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (currentScroll >= maxScroll) {
        // 滚动到末尾后，跳回开头
        _scrollController.jumpTo(0);
      } else {
        // 继续滚动
        _scrollController.animateTo(
          currentScroll + 1,
          duration: const Duration(milliseconds: 30),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    // 将所有公告连接成一个字符串，用分隔符隔开
    final allAnnouncements = _announcements.join('    •    ');

    return Container(
      height: 36,
      decoration: BoxDecoration(color: Colors.blue[100]),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.campaign, size: 20, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    allAnnouncements,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 100),
                  Text(
                    allAnnouncements,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
