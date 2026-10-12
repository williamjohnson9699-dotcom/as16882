import 'package:flutter/material.dart';
import 'login_dialog.dart';
import '../../../core/l10n/app_localizations.dart';

/// 注册对话框
class RegisterDialog extends StatefulWidget {
  const RegisterDialog({super.key});

  @override
  State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 执行注册
  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: 实现注册逻辑
      Navigator.of(context).pop();
    }
  }

  /// 跳转到登录
  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginDialog(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Text(
                  l10n.register,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 用户名输入框
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.username,
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterUsername;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 昵称输入框
                TextFormField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: l10n.nickname,
                    prefixIcon: const Icon(Icons.badge),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterNickname;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 密码输入框
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterPassword;
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
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseConfirmPassword;
                    }
                    if (value != _passwordController.text) {
                      return l10n.passwordMismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 注册按钮
                ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    l10n.register,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // 登录按钮
                TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(l10n.hasAccountLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
