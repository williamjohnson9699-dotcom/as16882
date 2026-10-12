import 'package:flutter/material.dart';
import '../../../core/api/user_management_api.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/date_util.dart';

/// 用户管理视图
class PermissionManagementView extends StatefulWidget {
  const PermissionManagementView({super.key});

  @override
  State<PermissionManagementView> createState() => _PermissionManagementViewState();
}

class _PermissionManagementViewState extends State<PermissionManagementView> {
  final _searchController = TextEditingController();
  String _selectedRole = 'all';
  int _currentPage = 1; // 当前页码
  int _totalPages = 1; // 总页数
  int _itemsPerPage = 10; // 每页显示数量
  final List<int> _pageSizeOptions = [10, 20, 30, 50]; // 分页大小选项
  final TextEditingController _pageInputController = TextEditingController();

  // 用户数据列表
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  int _totalRecords = 0;

  // 选择状态
  Set<String> _selectedUserIds = {};
  bool _isAllSelected = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            _buildHeader(),
            const SizedBox(height: 24),
          ],
          _buildSearchAndFilter(),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildUserTable()),
                const SizedBox(height: 24),
                _buildPagination(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 加载用户数据
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await UserManagementApi.queryUsers(
        keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        role: _selectedRole == 'all' ? null : _selectedRole,
        page: _currentPage,
        pageSize: _itemsPerPage,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        setState(() {
          _users = List<Map<String, dynamic>>.from(data['list'] ?? []);
          _totalRecords = data['total'] ?? 0;
          _totalPages = data['totalPages'] ?? 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.loadFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.loadFailed}: $e')),
        );
      }
    }
  }

  /// 处理搜索
  void _handleSearch() {
    setState(() {
      _currentPage = 1;
    });
    _loadUsers();
  }

  /// 构建头部
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.translate('permission_management'),
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  /// 构建搜索和筛选
  Widget _buildSearchAndFilter() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          // 角色筛选
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: InputDecoration(
              labelText: l10n.roleFilter,
              labelStyle: TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            items: [
              DropdownMenuItem(value: 'all', child: Text(l10n.allRoles, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'USER', child: Text(l10n.normalUser, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'SHOP', child: Text(l10n.shopUser, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'SERVICE', child: Text(l10n.customerService, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'ADMIN', child: Text(l10n.administrator, style: TextStyle(fontSize: 13))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
                _currentPage = 1;
              });
              _loadUsers();
            },
          ),
          const SizedBox(height: 12),
          // 搜索框
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchUserHint,
                    hintStyle: TextStyle(fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: TextStyle(fontSize: 13),
                  onSubmitted: (value) => _handleSearch(),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _handleSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: Text(l10n.search, style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: InputDecoration(
              labelText: l10n.roleFilter,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: [
              DropdownMenuItem(value: 'all', child: Text(l10n.allRoles)),
              DropdownMenuItem(value: 'USER', child: Text(l10n.normalUser)),
              DropdownMenuItem(value: 'SHOP', child: Text(l10n.shopUser)),
              DropdownMenuItem(value: 'SERVICE', child: Text(l10n.customerService)),
              DropdownMenuItem(value: 'ADMIN', child: Text(l10n.administrator)),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
                _currentPage = 1;
              });
              _loadUsers();
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchUserHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (value) => _handleSearch(),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _handleSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: Text(l10n.search),
        ),
      ],
    );
  }

  /// 构建用户表格
  Widget _buildUserTable() {
    final filteredUsers = _getFilteredUsers();
    final isMobile = ResponsiveUtil.isMobile(context);

    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 32 : 40),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (isMobile) {
      // 移动端：卡片列表
      if (filteredUsers.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) => _buildUserCard(filteredUsers[index]),
      );
    }

    // 桌面端：表格
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          if (filteredUsers.isEmpty)
            Expanded(child: _buildEmptyState())
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) => _buildTableRow(filteredUsers[index]),
              ),
            ),
        ],
      ),
    );
  }

  /// 获取筛选后的用户（后端已处理筛选，直接返回）
  List<Map<String, dynamic>> _getFilteredUsers() {
    return _users;
  }

  /// 构建表格头部
  Widget _buildTableHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          _buildHeaderCell(l10n.id, flex: 1),
          _buildHeaderCell(l10n.username, flex: 3),
          _buildHeaderCell(l10n.nickname, flex: 2),
          _buildHeaderCell(l10n.role, flex: 2),
          const SizedBox(width: 16),
          _buildHeaderCell(l10n.createTime, flex: 2),
          _buildHeaderCell(l10n.actions, flex: 3),
        ],
      ),
    );
  }

  /// 构建表头单元格
  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: isMobile ? 40 : 48, color: Colors.grey[400]),
            SizedBox(height: isMobile ? 10 : 12),
            Text(
              l10n.noUserData,
              style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建用户卡片（移动端）
  Widget _buildUserCard(Map<String, dynamic> user) {
    final l10n = AppLocalizations.of(context);
    final isAdmin = user['username'] == 'admin';
    final roleInfo = _getRoleInfo(user['role'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户名和角色
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['username'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['nickname'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roleInfo['color'],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  roleInfo['label'],
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 邀请码和创建时间
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.id}: ${user['inviteCode'] ?? ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              Text(
                _formatDate(user['createTime']),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isAdmin ? null : () => _showChangeRoleDialog(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isAdmin ? Colors.grey[400] : Colors.orange[600],
                    side: BorderSide(color: isAdmin ? Colors.grey[300]! : Colors.orange[600]!),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(l10n.role, style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isAdmin ? null : () => _handleDeleteUser(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdmin ? Colors.grey[400] : Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(l10n.delete, style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建表格行
  Widget _buildTableRow(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          _buildCell(user['inviteCode'] ?? '', flex: 1),
          _buildCell(user['username'] ?? '', flex: 3),
          _buildCell(user['nickname'] ?? '', flex: 2),
          _buildRoleCell(user['role'] ?? '', flex: 2),
          const SizedBox(width: 16),
          _buildCell(_formatDate(user['createTime']), flex: 2),
          _buildActionCell(user),
        ],
      ),
    );
  }

  /// 构建单元格
  Widget _buildCell(String text, {int flex = 1, Color? backgroundColor}) {
    return Expanded(
      flex: flex,
      child: Container(
        color: backgroundColor,
        child: SelectableText(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[800],
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  /// 构建角色单元格
  Widget _buildRoleCell(String role, {int flex = 1}) {
    final roleInfo = _getRoleInfo(role);
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: roleInfo['color'],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          roleInfo['label'],
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 格式化日期为年月日
  String _formatDate(dynamic date) {
    return DateUtil.formatDate(DateUtil.parseAsLocalDateTime(date));
  }

  /// 获取角色信息
  Map<String, dynamic> _getRoleInfo(String role) {
    final l10n = AppLocalizations.of(context);
    switch (role) {
      case 'ADMIN':
        return {'label': l10n.administrator, 'color': Colors.red[600]};
      case 'SERVICE':
        return {'label': l10n.customerService, 'color': Colors.orange[600]};
      case 'SHOP':
        return {'label': l10n.shopUser, 'color': Colors.blue[600]};
      case 'USER':
      default:
        return {'label': l10n.normalUser, 'color': Colors.grey[600]};
    }
  }

  /// 构建操作单元格
  Widget _buildActionCell(Map<String, dynamic> user) {
    final l10n = AppLocalizations.of(context);
    final isAdmin = user['username'] == 'admin';

    return Expanded(
      flex: 3,
      child: Row(
        children: [
          TextButton(
            onPressed: isAdmin ? null : () => _showChangeRoleDialog(user),
            style: TextButton.styleFrom(
              foregroundColor: isAdmin ? Colors.grey[400] : Colors.orange[600],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.role, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: isAdmin ? null : () => _handleDeleteUser(user),
            style: TextButton.styleFrom(
              foregroundColor: isAdmin ? Colors.grey[400] : Colors.red[600],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.delete, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  /// 显示添加用户对话框
  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.translate('add_user')),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: l10n.translate('name')),
                    validator: (v) => v?.isEmpty ?? true ? l10n.translate('please_enter_name') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: l10n.translate('phone')),
                    validator: (v) => v?.isEmpty ?? true ? l10n.translate('please_enter_phone') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: l10n.translate('email')),
                    validator: (v) => v?.isEmpty ?? true ? l10n.translate('please_enter_email') : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _users.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'email': emailController.text,
                    'role': 'normal_user',
                    'createTime': DateTime.now().toString().substring(0, 10),
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('add_success'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      );
      },
    );
  }

  /// 显示编辑用户对话框
  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final phoneController = TextEditingController(text: user['phone']);
    final emailController = TextEditingController(text: user['email']);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.translate('edit_user')),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.translate('name')),
                  validator: (v) => v?.isEmpty ?? true ? l10n.translate('please_enter_name') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: l10n.translate('phone')),
                  validator: (v) => v?.isEmpty ?? true ? l10n.translate('please_enter_phone') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: l10n.translate('email')),
                  validator: (v) => v?.isEmpty ?? true ? l10n.translate('please_enter_email') : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  user['name'] = nameController.text;
                  user['phone'] = phoneController.text;
                  user['email'] = emailController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('update_success'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      );
      },
    );
  }

  /// 显示修改角色对话框
  void _showChangeRoleDialog(Map<String, dynamic> user) {
    final l10n = AppLocalizations.of(context);
    String selectedRole = user['role'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.editUser),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.nickname}: ${user['nickname']}'),
              const SizedBox(height: 16),
              Text('${l10n.role}:', style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: Text(l10n.normalUser),
                value: 'USER',
                groupValue: selectedRole,
                onChanged: (value) => setDialogState(() => selectedRole = value!),
              ),
              RadioListTile<String>(
                title: Text(l10n.customerService),
                value: 'SERVICE',
                groupValue: selectedRole,
                onChanged: user['role'] != 'SHOP' ? (value) => setDialogState(() => selectedRole = value!) : null,
              ),
              RadioListTile<String>(
                title: Text(l10n.administrator),
                value: 'ADMIN',
                groupValue: selectedRole,
                onChanged: user['role'] != 'SHOP' ? (value) => setDialogState(() => selectedRole = value!) : null,
              ),
              if (user['role'] == 'SHOP')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.shopUserRoleRestriction,
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await UserManagementApi.updateUserRole(
                    userId: user['id'] as int,
                    role: selectedRole,
                  );

                  Navigator.pop(context);

                  if (response.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.userUpdateSuccess)),
                    );
                    _loadUsers();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.updateFailed}: ${response.errorMessage}')),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.updateFailed}: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理删除用户
  void _handleDeleteUser(Map<String, dynamic> user) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteUser.replaceAll('{nickname}', user['nickname'] ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                final response = await UserManagementApi.deleteUser(
                  user['id'] as int,
                );

                Navigator.pop(context);

                if (response.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.userDeleteSuccess)),
                  );
                  _loadUsers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.deleteFailed}: ${response.errorMessage}')),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.deleteFailed}: $e')),
                );
              }
            },
            child: Text(l10n.delete, style: TextStyle(color: Colors.red[600])),
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
                        });
                        _loadUsers();
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
                        });
                        _loadUsers();
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
                  });
                  _loadUsers();
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
                  });
                  _loadUsers();
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
          l10n.perPage,
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
                });
                _loadUsers();
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
        });
        _loadUsers();
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
          child: Text(
            l10n.jump,
            style: const TextStyle(fontSize: 14),
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
    });
    _pageInputController.clear();
    _loadUsers();
  }
}
