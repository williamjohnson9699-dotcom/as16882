import 'package:flutter/material.dart';
import 'package:usdt_mall_app/core/api/announcement_management_api.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/date_util.dart';

/// 系统公告视图
class SystemAnnouncementView extends StatefulWidget {
  const SystemAnnouncementView({super.key});

  @override
  State<SystemAnnouncementView> createState() => _SystemAnnouncementViewState();
}

class _SystemAnnouncementViewState extends State<SystemAnnouncementView> {
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemsPerPage = 10;
  final List<int> _pageSizeOptions = [10, 20, 30, 50];
  final TextEditingController _pageInputController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _allAnnouncements = [];
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  /// 加载公告列表
  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AnnouncementManagementApi.getAnnouncementList();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _allAnnouncements = List<Map<String, dynamic>>.from(response.data!);
          _totalRecords = _allAnnouncements.length;
          _totalPages = (_totalRecords / _itemsPerPage).ceil();
          _updatePageData();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? AppLocalizations.of(context).deleteFailed)),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).deleteFailed}: $e')),
        );
      }
    }
  }

  /// 更新当前页数据
  void _updatePageData() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _allAnnouncements.length);
    _announcements = _allAnnouncements.sublist(startIndex, endIndex);
  }

  /// 删除公告
  Future<void> _deleteAnnouncement(int id) async {
    try {
      final response = await AnnouncementManagementApi.deleteAnnouncement(id);
      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).deleteSuccess)),
          );
        }
        _loadAnnouncements();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? AppLocalizations.of(context).deleteFailed)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).deleteFailed}: $e')),
        );
      }
    }
  }

  /// 批量删除公告
  Future<void> _batchDeleteAnnouncements() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pleaseSelectAnnouncementsToDelete)),
      );
      return;
    }

    try {
      final response = await AnnouncementManagementApi.batchDeleteAnnouncements(
        _selectedIds.toList(),
      );
      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).batchDeleteSuccess)),
          );
        }
        setState(() {
          _selectedIds.clear();
          _isSelectionMode = false;
        });
        _loadAnnouncements();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? AppLocalizations.of(context).batchDeleteFailed)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).batchDeleteFailed}: $e')),
        );
      }
    }
  }

  /// 保存公告
  Future<void> _saveAnnouncement(Map<String, dynamic> data) async {
    try {
      final response = await AnnouncementManagementApi.saveAnnouncement(data);
      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).saveSuccess)),
          );
        }
        _loadAnnouncements();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? AppLocalizations.of(context).saveFailed)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).saveFailed}: $e')),
        );
      }
    }
  }

  /// 显示公告编辑对话框
  void _showAnnouncementDialog([Map<String, dynamic>? announcement]) {
    final titleController = TextEditingController(text: announcement?['title'] ?? '');
    final contentController = TextEditingController(text: announcement?['content'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement == null ? AppLocalizations.of(context).newAnnouncement : AppLocalizations.of(context).editAnnouncement),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).announcementTitle,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context).pleaseEnterAnnouncementTitle;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).announcementContent,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context).pleaseEnterAnnouncementContent;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final data = <String, dynamic>{
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                };
                if (announcement != null && announcement['id'] != null) {
                  data['id'] = announcement['id'];
                }
                Navigator.pop(context);
                _saveAnnouncement(data);
              }
            },
            child: Text(AppLocalizations.of(context).submit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isMobile)
                Text(
                  AppLocalizations.of(context).systemAnnouncement,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              Row(
                children: [
                  if (_isSelectionMode) ...[
                    ElevatedButton.icon(
                      onPressed: _batchDeleteAnnouncements,
                      icon: const Icon(Icons.delete, size: 18),
                      label: Text(AppLocalizations.of(context).batchDelete),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedIds.clear();
                        });
                      },
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () => _showAnnouncementDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(AppLocalizations.of(context).newAnnouncement),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                        });
                      },
                      icon: const Icon(Icons.checklist, size: 18),
                      label: Text(AppLocalizations.of(context).batchManagement),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildAnnouncementList()),
        ],
      ),
    );
  }

  Widget _buildAnnouncementList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).noAnnouncements, style: const TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _announcements.length,
            itemBuilder: (context, index) => _buildAnnouncementItem(_announcements[index]),
          ),
        ),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  Widget _buildAnnouncementItem(Map<String, dynamic> announcement) {
    final l10n = AppLocalizations.of(context);
    final id = announcement['id'] as int;
    final isSelected = _selectedIds.contains(id);
    final displayDate = DateUtil.formatDate(DateUtil.parseAsLocalDateTime(announcement['createTime']));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          if (_isSelectionMode) ...[
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(id);
                  } else {
                    _selectedIds.remove(id);
                  }
                });
              },
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        announcement['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      displayDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  announcement['content'] ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          if (!_isSelectionMode) ...[
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _showAnnouncementDialog(announcement),
              tooltip: l10n.edit,
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 18, color: Colors.red[700]),
              onPressed: () => _showDeleteConfirmDialog(id),
              tooltip: l10n.delete,
            ),
          ],
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirm),
        content: Text(AppLocalizations.of(context).confirmDeleteAnnouncement),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnnouncement(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
  }

  /// 构建分页栏
  Widget _buildPagination() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      // 移动端：单行紧凑布局
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 总条数
          Text(
            '${l10n.total} $_totalRecords ${l10n.items}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          // 翻页按钮
          Row(
            children: [
              _buildPageButton(
                icon: Icons.chevron_left,
                onPressed: _currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                          _updatePageData();
                        });
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              _buildPageButton(
                icon: Icons.chevron_right,
                onPressed: _currentPage < _totalPages
                    ? () {
                        setState(() {
                          _currentPage++;
                          _updatePageData();
                        });
                      }
                    : null,
              ),
            ],
          ),
        ],
      );
    }

    // 桌面端：原有布局
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 分页大小选择器
        _buildPageSizeSelector(),
        const SizedBox(width: 24),

        // 上一页按钮
        _buildPageButton(
          icon: Icons.chevron_left,
          onPressed: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage--;
                    _updatePageData();
                  });
                }
              : null,
        ),
        const SizedBox(width: 8),

        // 页码按钮
        ..._buildPageNumbers(),

        const SizedBox(width: 8),
        // 下一页按钮
        _buildPageButton(
          icon: Icons.chevron_right,
          onPressed: _currentPage < _totalPages
              ? () {
                  setState(() {
                    _currentPage++;
                    _updatePageData();
                  });
                }
              : null,
        ),

        const SizedBox(width: 16),
        // 页码输入区域
        _buildPageInput(),
      ],
    );
  }

  /// 构建分页大小选择器
  Widget _buildPageSizeSelector() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          l10n.itemsPerPage,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<int>(
            value: _itemsPerPage,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() {
                  _itemsPerPage = newValue;
                  _currentPage = 1;
                  _totalPages = (_totalRecords / _itemsPerPage).ceil();
                  _updatePageData();
                });
              }
            },
            items: _pageSizeOptions.map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value'),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.items,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  /// 构建页码按钮
  Widget _buildPageButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey[200] : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onPressed == null ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
    );
  }

  /// 构建页码数字列表
  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];
    if (_totalPages < 1) return pageNumbers;

    int startPage = (_currentPage - 2).clamp(1, _totalPages);
    int endPage = (_currentPage + 2).clamp(1, _totalPages);

    if (startPage > 1) {
      pageNumbers.add(_buildPageNumberButton(1));
      if (startPage > 2) {
        pageNumbers.add(const SizedBox(width: 8));
        pageNumbers.add(_buildEllipsis());
      }
      pageNumbers.add(const SizedBox(width: 8));
    }

    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(_buildPageNumberButton(i));
      if (i < endPage) {
        pageNumbers.add(const SizedBox(width: 8));
      }
    }

    if (endPage < _totalPages) {
      pageNumbers.add(const SizedBox(width: 8));
      if (endPage < _totalPages - 1) {
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 8));
      }
      pageNumbers.add(_buildPageNumberButton(_totalPages));
    }

    return pageNumbers;
  }

  /// 构建页码数字按钮
  Widget _buildPageNumberButton(int pageNumber) {
    final isActive = pageNumber == _currentPage;
    return InkWell(
      onTap: () {
        setState(() {
          _currentPage = pageNumber;
          _updatePageData();
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[700] : Colors.white,
          border: Border.all(
            color: isActive ? Colors.blue[700]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '$pageNumber',
            style: TextStyle(
              fontSize: 14,
              color: isActive ? Colors.white : Colors.grey[800],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建省略号
  Widget _buildEllipsis() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: Text(
        '...',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// 构建页码输入区域
  Widget _buildPageInput() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          l10n.jumpTo,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 60,
          height: 36,
          child: TextField(
            controller: _pageInputController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue[700]!),
              ),
            ),
            onSubmitted: (value) => _jumpToPage(),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.page,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _jumpToPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(60, 36),
          ),
          child: const Text(
            '跳转',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// 跳转到指定页码
  void _jumpToPage() {
    final l10n = AppLocalizations.of(context);
    final inputText = _pageInputController.text.trim();
    if (inputText.isEmpty) return;

    final pageNumber = int.tryParse(inputText);
    if (pageNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterValidPage)),
      );
      return;
    }

    if (pageNumber < 1 || pageNumber > _totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.pageRangeLabel}: 1-$_totalPages')),
      );
      return;
    }

    setState(() {
      _currentPage = pageNumber;
      _updatePageData();
    });
    _pageInputController.clear();
  }
}
