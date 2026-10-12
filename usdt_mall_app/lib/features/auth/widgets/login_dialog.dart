import 'package:flutter/material.dart';
import 'register_dialog.dart';
import '../../../core/l10n/app_localizations.dart';

/// 登录对话框
class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 执行登录
  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: 实现登录逻辑
      Navigator.of(context).pop();
    }
  }

  /// 跳转到注册
  void _navigateToRegister() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RegisterDialog(),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Text(
                l10n.login,
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
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 登录按钮
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  l10n.login,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // 注册按钮
              TextButton(
                onPressed: _navigateToRegister,
                child: Text(l10n.noAccountRegister),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
