import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/api/user_api.dart';
import '../../../core/api/file_api.dart';
import '../../../core/api/recharge_api.dart';
import '../../../core/api/withdraw_api.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/router_service.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/responsive_util.dart';
import 'recharge_dialog.dart';
import 'withdraw_dialog.dart';

/// 我的账户信息视图
class AccountInfoView extends StatefulWidget {
  const AccountInfoView({super.key});

  @override
  State<AccountInfoView> createState() => _AccountInfoViewState();
}

class _AccountInfoViewState extends State<AccountInfoView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userInfo = authProvider.userInfo;
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: ListView(
        children: [
          // 桌面端显示标题
          if (!isMobile) ...[
            Text(
              l10n.myAccount,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
          ],
          // 账户信息列表
          _buildInfoItem(
            context: context,
            label: l10n.id,
            value: userInfo?.inviteCode ?? '--',
            icon: Icons.qr_code,
          ),
          _buildInfoItem(
            context: context,
            label: l10n.username,
            value: userInfo?.email ?? '--',
            icon: Icons.person_outline,
          ),
          _buildInfoItem(
            context: context,
            label: l10n.nickname,
            value: userInfo?.nickname ?? '--',
            icon: Icons.badge_outlined,
            showEdit: true,
            onEditPressed: () => _showEditNicknameDialog(userInfo?.nickname ?? ''),
          ),
          _buildInfoItem(
            context: context,
            label: l10n.avatar,
            value: userInfo?.avatar ?? '',
            icon: Icons.account_circle_outlined,
            showEdit: true,
            isAvatar: true,
            onEditPressed: () => _showEditAvatarDialog(userInfo?.avatar ?? ''),
          ),
          _buildInfoItem(
            context: context,
            label: l10n.loginPassword,
            value: '********',
            icon: Icons.lock_outline,
            showEdit: true,
            onEditPressed: _showEditPasswordDialog,
          ),
          _buildInfoItem(
            context: context,
            label: l10n.paymentPassword,
            value: userInfo?.hasPaymentPassword == true ? '********' : '--',
            icon: Icons.security_outlined,
            showEdit: true,
            onEditPressed: () => _showEditPaymentPasswordDialog(userInfo?.hasPaymentPassword ?? false),
          ),
          _buildInfoItem(
            context: context,
            label: l10n.accountBalance,
            value: userInfo != null ? '\$ ${userInfo.balance.toStringAsFixed(2)}' : '\$ 0.00',
            icon: Icons.account_balance_wallet_outlined,
            showRefresh: true,
            onRefreshPressed: _handleRefreshBalance,
          ),
          const SizedBox(height: 24),
          // 操作按钮
          _buildActionButtons(context),
        ],
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    bool showEdit = false,
    bool showRefresh = false,
    bool isAvatar = false,
    VoidCallback? onEditPressed,
    VoidCallback? onRefreshPressed,
  }) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                if (isAvatar)
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: value.isNotEmpty
                        ? NetworkImage(ImageUtil.getImageUrl(value))
                        : null,
                    child: value.isEmpty
                        ? Icon(Icons.person, color: Colors.grey[700])
                        : null,
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (showEdit)
            TextButton(
              onPressed: onEditPressed,
              child: Text(l10n.edit),
            ),
          if (showRefresh)
            IconButton(
              onPressed: onRefreshPressed,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.refresh,
              color: Colors.blue[700],
            ),
        ],
      ),
    );
  }

  /// 显示编辑昵称对话框
  void _showEditNicknameDialog(String currentNickname) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentNickname);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editNickname),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.newNickname,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => _handleUpdateNickname(controller.text),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// 显示编辑头像对话框
  void _showEditAvatarDialog(String currentAvatar) {
    showDialog(
      context: context,
      builder: (context) => _AvatarUploadDialog(
        currentAvatar: currentAvatar,
        onAvatarSelected: (String avatarUrl) => _handleUpdateAvatar(avatarUrl),
      ),
    );
  }

  /// 显示修改密码对话框
  void _showEditPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => _PasswordUpdateDialog(
        onPasswordUpdated: () async {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.passwordChangedSuccessRelogin)),
            );

            // 延迟1秒后退出登录
            await Future.delayed(const Duration(seconds: 1));

            if (mounted) {
              await _handleLogout();
            }
          }
        },
      ),
    );
  }

  /// 显示设置/修改支付密码对话框
  void _showEditPaymentPasswordDialog(bool hasPaymentPassword) {
    showDialog(
      context: context,
      builder: (context) => _PaymentPasswordDialog(
        hasPaymentPassword: hasPaymentPassword,
        onPasswordUpdated: () {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(hasPaymentPassword ? l10n.paymentPasswordChangedSuccess : l10n.paymentPasswordSetSuccess),
              ),
            );
            // 刷新用户信息以更新hasPaymentPassword状态
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            authProvider.refreshUserInfo();
          }
        },
      ),
    );
  }

  /// 显示充值对话框
  void _showRechargeDialog() {
    showDialog(
      context: context,
      builder: (context) => RechargeDialog(
        onSubmit: (paymentMethod, amount, remark, proofImage, receivingAddress) async {
          await _handleRecharge(paymentMethod, amount, remark, proofImage, receivingAddress);
        },
      ),
    );
  }

  /// 处理充值
  Future<void> _handleRecharge(String paymentMethod, double amount, String remark, String? proofImage, String receivingAddress) async {
    final l10n = AppLocalizations.of(context);
    try {
      final response = await RechargeApi.submitRecharge(
        paymentMethod: paymentMethod,
        amount: amount,
        remark: remark,
        proofImage: proofImage,
        receivingAddress: receivingAddress,
      );

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.rechargeSubmitted)),
          );
          context.read<AppProvider>().loadPendingRecordCount();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.rechargeFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.rechargeFailed}: $e')),
        );
      }
      rethrow;
    }
  }

  /// 显示提现对话框
  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => WithdrawDialog(
        onSubmit: (paymentMethod, amount, receivingAddress, paymentPassword) async {
          await _handleWithdraw(paymentMethod, amount, receivingAddress, paymentPassword);
        },
      ),
    );
  }

  /// 处理提现
  Future<void> _handleWithdraw(String paymentMethod, double amount, String receivingAddress, String paymentPassword) async {
    final l10n = AppLocalizations.of(context);
    try {
      final response = await WithdrawApi.submitWithdraw(
        paymentMethod: paymentMethod,
        amount: amount,
        receivingAddress: receivingAddress,
        paymentPassword: paymentPassword,
      );

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.withdrawSubmitted)),
          );
          context.read<AppProvider>().loadPendingRecordCount();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.withdrawFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.withdrawFailed}: $e')),
        );
      }
      rethrow;
    }
  }

  /// 处理刷新余额
  Future<void> _handleRefreshBalance() async {
    final l10n = AppLocalizations.of(context);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.refreshSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.refreshFailed}: $e')),
        );
      }
    }
  }

  /// 处理退出登录
  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();
    final appProvider = context.read<AppProvider>();

    try {
      // 调用退出接口（会自动设置离线状态并清除token和用户信息）
      await authProvider.logout();

      // 清空统计数据
      appProvider.clear();

      if (mounted) {
        context.go('/');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context.go('/home');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.logoutFailed}: $e')),
        );
      }
    }
  }

  /// 处理更新昵称
  Future<void> _handleUpdateNickname(String newNickname) async {
    final l10n = AppLocalizations.of(context);
    if (newNickname.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nicknameCannotBeEmpty)),
      );
      return;
    }

    try {
      final response = await UserApi.updateNickname(nickname: newNickname);

      if (response.isSuccess) {
        // 更新前端缓存的昵称
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.userInfo != null) {
          final updatedUserInfo = authProvider.userInfo!.copyWith(
            nickname: newNickname,
          );
          await authProvider.updateUserInfo(updatedUserInfo);
        }

        // 关闭对话框
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.nicknameUpdatedSuccess)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.updateFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.updateFailed}: $e')),
        );
      }
    }
  }

  /// 处理更新头像
  Future<void> _handleUpdateAvatar(String newAvatar) async {
    final l10n = AppLocalizations.of(context);
    if (newAvatar.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.avatarUrlCannotBeEmpty)),
      );
      return;
    }

    try {
      final response = await UserApi.updateAvatar(avatar: newAvatar);

      if (response.isSuccess) {
        // 更新前端缓存的头像
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.userInfo != null) {
          final updatedUserInfo = authProvider.userInfo!.copyWith(
            avatar: newAvatar,
          );
          await authProvider.updateUserInfo(updatedUserInfo);
        }

        // 关闭对话框
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.avatarUpdatedSuccess)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.updateFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.updateFailed}: $e')),
        );
      }
    }
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showRechargeDialog,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.recharge),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showWithdrawDialog,
            icon: const Icon(Icons.remove_circle_outline),
            label: Text(l10n.withdraw),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// 头像上传对话框
class _AvatarUploadDialog extends StatefulWidget {
  final String currentAvatar;
  final Function(String) onAvatarSelected;

  const _AvatarUploadDialog({
    required this.currentAvatar,
    required this.onAvatarSelected,
  });

  @override
  State<_AvatarUploadDialog> createState() => _AvatarUploadDialogState();
}

class _AvatarUploadDialogState extends State<_AvatarUploadDialog> {
  XFile? _selectedImage;
  bool _isUploading = false;
  String? _uploadedAvatarUrl;
  String _uploadStatus = ''; // 上传状态信息

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editAvatar),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 显示当前头像或选中的图片
            _buildAvatarPreview(),
            const SizedBox(height: 16),
            // 选择图片按钮
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: Text(l10n.selectImage),
            ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
            // 显示上传状态信息
            if (_uploadStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _uploadedAvatarUrl != null
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _uploadedAvatarUrl != null
                          ? Colors.green[300]!
                          : Colors.orange[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _uploadedAvatarUrl != null
                            ? Icons.check_circle
                            : Icons.info,
                        color: _uploadedAvatarUrl != null
                            ? Colors.green[700]
                            : Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploadStatus,
                          style: TextStyle(
                            fontSize: 13,
                            color: _uploadedAvatarUrl != null
                                ? Colors.green[900]
                                : Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: (_isUploading || _uploadedAvatarUrl == null) ? null : _confirmUpdate,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  Widget _buildAvatarPreview() {
    if (_selectedImage != null) {
      return ClipOval(
        child: FutureBuilder<Uint8List>(
          future: _selectedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              );
            }
            return const CircularProgressIndicator();
          },
        ),
      );
    } else if (widget.currentAvatar.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          ImageUtil.getImageUrl(widget.currentAvatar),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 100,
              height: 100,
              color: Colors.grey[300],
              child: Icon(Icons.person, size: 50, color: Colors.grey[700]),
            );
          },
        ),
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
        child: Icon(Icons.person, size: 50, color: Colors.grey[700]),
      );
    }
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });

        // 立即上传图片
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.selectImageFailed}: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = l10n.uploadingImageText;
    });

    try {
      // 读取图片字节
      final fileBytes = await _selectedImage!.readAsBytes();
      final fileName = _selectedImage!.name;

      // 上传图片
      final response = await FileApi.uploadFile(
        filePath: _selectedImage!.path,
        fileName: fileName,
        fileBytes: fileBytes,
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          _uploadedAvatarUrl = response.data!;
          _uploadStatus = '${l10n.uploadSuccessFile}: ${response.data!}';
        });
      } else {
        setState(() {
          _uploadStatus = '${l10n.uploadFailedText}: ${response.errorMessage}';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = '${l10n.uploadErrorText}: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _confirmUpdate() {
    if (_uploadedAvatarUrl != null) {
      // 调用回调函数更新头像
      widget.onAvatarSelected(_uploadedAvatarUrl!);
    }
  }
}

/// 修改密码对话框
class _PasswordUpdateDialog extends StatefulWidget {
  final VoidCallback onPasswordUpdated;

  const _PasswordUpdateDialog({
    required this.onPasswordUpdated,
  });

  @override
  State<_PasswordUpdateDialog> createState() => _PasswordUpdateDialogState();
}

class _PasswordUpdateDialogState extends State<_PasswordUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isUpdating = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.changeLoginPassword),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 旧密码输入框
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOldPassword,
                decoration: InputDecoration(
                  labelText: l10n.oldPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOldPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureOldPassword = !_obscureOldPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterOldPassword;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 新密码输入框
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: l10n.newPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterNewPassword;
                  }
                  if (value.length < 6) {
                    return l10n.passwordMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 确认密码输入框
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: l10n.confirmNewPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseConfirmNewPassword;
                  }
                  if (value != _newPasswordController.text) {
                    return l10n.passwordMismatch;
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
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _handleUpdatePassword,
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.confirm),
        ),
      ],
    );
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await UserApi.updatePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (response.isSuccess) {
        if (mounted) {
          Navigator.pop(context);
          widget.onPasswordUpdated();
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.updateFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.updateFailed}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}

/// 支付密码对话框（设置或修改）
class _PaymentPasswordDialog extends StatefulWidget {
  final bool hasPaymentPassword;
  final VoidCallback onPasswordUpdated;

  const _PaymentPasswordDialog({
    required this.hasPaymentPassword,
    required this.onPasswordUpdated,
  });

  @override
  State<_PaymentPasswordDialog> createState() => _PaymentPasswordDialogState();
}

class _PaymentPasswordDialogState extends State<_PaymentPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isUpdating = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.hasPaymentPassword ? l10n.changePaymentPassword : l10n.setPaymentPassword),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildFormFields(context),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _handleUpdatePaymentPassword,
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.confirm),
        ),
      ],
    );
  }

  List<Widget> _buildFormFields(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    List<Widget> fields = [];

    // 如果已有支付密码,显示旧密码输入框
    if (widget.hasPaymentPassword) {
      fields.add(
        TextFormField(
          controller: _oldPasswordController,
          obscureText: _obscureOldPassword,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: l10n.oldPaymentPassword,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscureOldPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _obscureOldPassword = !_obscureOldPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.pleaseEnterOldPaymentPassword;
            }
            return null;
          },
        ),
      );
      fields.add(const SizedBox(height: 16));
    }

    // 新密码输入框
    fields.add(
      TextFormField(
        controller: _newPasswordController,
        obscureText: _obscureNewPassword,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: InputDecoration(
          labelText: widget.hasPaymentPassword ? l10n.newPaymentPassword : l10n.paymentPassword,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscureNewPassword = !_obscureNewPassword;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.pleaseEnterPaymentPassword;
          }
          if (value.length != 6) {
            return l10n.paymentPasswordMust6Digits;
          }
          if (!RegExp(r'^\d+$').hasMatch(value)) {
            return l10n.paymentPasswordOnlyDigits;
          }
          return null;
        },
      ),
    );
    fields.add(const SizedBox(height: 16));

    // 确认密码输入框
    fields.add(
      TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: InputDecoration(
          labelText: l10n.confirmPaymentPassword,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.pleaseConfirmPaymentPassword;
          }
          if (value != _newPasswordController.text) {
            return l10n.passwordMismatch;
          }
          return null;
        },
      ),
    );

    return fields;
  }

  Future<void> _handleUpdatePaymentPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final response = widget.hasPaymentPassword
          ? await UserApi.updatePaymentPassword(
              oldPaymentPassword: _oldPasswordController.text,
              newPaymentPassword: _newPasswordController.text,
            )
          : await UserApi.setPaymentPassword(
              paymentPassword: _newPasswordController.text,
            );

      if (response.isSuccess) {
        if (mounted) {
          Navigator.pop(context);
          widget.onPasswordUpdated();
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.operationFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.operationFailed}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}
