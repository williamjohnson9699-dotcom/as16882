import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../main.dart';

/// 注销/删除账户指南内容
const String _accountDeletionContent = '''
Cross-border seller terms of service

August 2022 version

Effective date of the latest version: August 18, 2022

IMPORTANT NOTICE

These Terms of Service are the revised version of AS1688's "Cross-Border Seller Terms of Service". Please read carefully before using the AS1688 platform or opening a AS1688 account or store.

【Read carefully】Before you click to agree to this agreement in the registration application process, you should read these terms of service carefully. Please be sure to read carefully and fully understand the contents of each clause, especially the clauses that exempt or limit liability, applicable laws and dispute resolution clauses.

1. ACCOUNT TERMINATION

1.1 You have the right to terminate the terms of service between AS1688 and you at any time in the manner agreed by both parties. If users want to terminate their account and store, they can notify AS1688 in writing (email to: AS1688svipshop@gmail.com or contact your account manager).

1.2 Even if the account and store are terminated, you are still responsible for any outstanding transactions (whether initiated before or after termination), product shipments, payment for products, etc. related to transactions, and you must promptly notify AS1688 when all outstanding transactions have been effectively fulfilled and completed.

1.3 AS1688 shall not be liable for any damages arising from actions taken under these Terms.

2. ACCOUNT CLOSURE CONDITIONS

2.1 AS1688 may immediately terminate your account and your user ID in the following circumstances:
- Not logging in and operating your account or not operating your store for a long time (more than 30 days or more)
- Suspension of business for more than one year, including unpaid bills for one year
- Violation of the terms of service
- Fraud, harassment, defamation, threats, insults or other illegal acts
- Multiple user accounts and duplicate stores based on improper or illegal intentions
- Payments seized by judicial or administrative authorities
- Submission of false or forged identification information
- Acts harmful to other users, third parties or AS1688's commercial interests

2.2 Your shop order in AS1688 is not processed within the specified time (24 hours). AS1688 has the right to immediately stop the service and close the seller account.

2.3 Your account in AS1688 is closed due to serious violations, and you are not allowed to re-register the account; if it is found that the account has been re-registered, AS1688 has the right to immediately stop the service and close the seller's account.

3. ACCOUNT SECURITY

3.1 You agree to keep your password confidential and use your user ID and password only when logging in.

3.2 You must ensure that you are logged out of your account at the end of each session.

3.3 Immediately notify AS1688 of unauthorized use of user IDs and/or passwords.

3.4 Ensure that your account information is correct and up-to-date.

3.5 You are solely responsible for all activity that occurs under your user ID, store and account.

4. DATA AND PRIVACY

4.1 Upon termination of your account, you must immediately delete, destroy or otherwise cease to retain any information or data obtained from the Service, including charts, graphs, statistics, images, reports, spreadsheets, files of documents obtained through your use of the Service.

4.2 AS1688 collects and uses personal information in accordance with the Privacy Policy. Please read the Privacy Policy carefully to understand how AS1688 handles your data.

5. OUTSTANDING OBLIGATIONS

5.1 After account termination, you remain responsible for:
- Completing all outstanding transactions
- Shipping products for orders placed before termination
- Handling any disputes or refunds
- Paying any outstanding fees or charges

5.2 AS1688 has the right to withhold payments until all obligations are fulfilled.

6. CONTACT INFORMATION

For account termination requests or questions, please contact:
- Email: AS1688svipshop@gmail.com
- Or contact your account manager
- 24-hour online customer service

Please allow reasonable time for AS1688 to process your account termination request and ensure all outstanding matters are resolved.
''';

/// 隐私政策内容（第1部分）
const String _privacyPolicyContent = '''
IMPORTANT INFORMATION - PLEASE READ CAREFULLY

BEFORE USING OR ACCESSING SELLER CENTRE

This end-user licence agreement ("EULA") is a legal agreement between you (hereinafter referred to as "You" or variants thereof) and AS1688

AS1688 Joint Stock Company
52 Ut Tich Street, Ward 4, Tan Binh District, Ho Chi Minh City, Vietnam

(hereinafter referred to as "we" or "us" or variants thereof)

which governs Your access to and/or use of:

(A) AS1688 Seller Center, a software application and platform provided by us for the purpose of facilitating your listing and fulfilment of goods for sale on the AS1688 Platform ("Service"); and

(B) any updates and any upgrades to the software that we may make available to You in respect of the Service ("Software"), and which shall form part of the "Service" above.

By assenting electronically, accessing and/or using the Service, You acknowledge and agree that You are an user who is (and remains) authorised by an entity ("Licensee"), which has (i) entered into the Software through a Marketplace Agreement ("Agreement") with one or more of our affiliate entities.

A reference to "Clause" in this EULA shall refer to a clause in this EULA.

BY ACCESSING AND/OR USING THE SERVICE, INCLUDING ANY UPDATES OR UPGRADES TO THE SAME, YOU ARE AGREEING TO BE LEGALLY BOUND BY THE TERMS OF THIS EULA

AGREED TERMS

1. ACKNOWLEDGEMENTS

1.1 The terms of this EULA govern Your use of and/or access to the Service, including any updates or upgrades to the same. We reserve the right to change any of the terms in the EULA from time to time by posting the amended EULA on this page.

1.2 By accessing and/or using the Service, You represent and warrant that You are an Authorised User under a valid Agreement duly executed by the Licensee.

1.3 By accessing and/or using the Service, You acknowledge and agree that internet transmissions are never completely private or secure.

1.4 By accessing and/or using the Service, You consent to us, collecting and using personal data and technical information about Your usage of the Service to improve the Service.

2. GRANT AND SCOPE OF LICENCE

2.1 We hereby grant you a non-transferable, non-exclusive licence to use and access the Service, subject to the terms of this EULA.

3. TERMINATION

3.1 This EULA shall automatically terminate in the event that the Agreement is terminated in accordance with the terms hereof.

4. LICENCE RESTRICTIONS

You agree that You shall not, and may not cause or permit others to copy, modify, duplicate, create derivative works from the Service.

5. ACCEPTABLE USE RESTRICTIONS

You must not use the Service in any unlawful manner, for any unlawful purpose, or in any manner inconsistent with this EULA.

6. INTELLECTUAL PROPERTY RIGHTS

You acknowledge that all intellectual property rights in the Service anywhere in the world belong to us, and/or our licensors.

7. WARRANTY

The Service is provided on an "as is" basis with no warranty of any kind.

8. LIMITATION OF LIABILITY

We shall not be liable to You for any indirect damages, special damages, consequential damages, loss of profits, loss of goodwill, loss of reputation, loss of data, or loss of business opportunity.

9. COMMUNICATION BETWEEN US

If we have to contact You or give you notice in writing, we will do so by e-mail. Please contact 24-hour online customer service.

10. FORCE MAJEURE

We will not be liable or responsible for any failure to perform caused by any act or event beyond our reasonable control.

11. MISCELLANEOUS

We may transfer our rights and obligations under this EULA to another organisation.

12. GOVERNING LAW, JURISDICTION AND DISPUTE RESOLUTION

This EULA shall be governed by and construed in accordance with the laws of Singapore.

13. UPDATES AND SUPPORT

We reserve the right to deploy any update of the Service at any time without notice.
''';

/// 认证对话框包装器（管理登录和注册的切换）
class AuthDialog extends StatefulWidget {
  final bool isLogin; // true: 登录, false: 注册

  const AuthDialog({
    super.key,
    this.isLogin = true,
  });

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  late bool _isLogin;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  /// 切换登录/注册
  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.only(
        top: isMobile ? 50 : 100,
        left: isMobile ? 16 : 0,
        right: isMobile ? 16 : 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 650,
          maxWidth: isMobile ? double.infinity : 700,
        ),
        child: IntrinsicHeight(
          child: isMobile
              ? SingleChildScrollView(
                  child: _isLogin
                      ? _LoginForm(onSwitchToRegister: _toggleMode, isMobile: true)
                      : _RegisterForm(onSwitchToLogin: _toggleMode, isMobile: true),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 左侧：登录/注册表单
                    _isLogin
                        ? _LoginForm(onSwitchToRegister: _toggleMode, isMobile: false)
                        : _RegisterForm(onSwitchToLogin: _toggleMode, isMobile: false),
                    // 右侧：图片和文本
                    _buildRightSide(),
                  ],
                ),
        ),
      ),
    );
  }

  /// 构建右侧内容（图片和文本）
  Widget _buildRightSide() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图片
          Image.asset(
            'assets/pic/login-icon.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          // 第一行文本
          Text(
            l10n.shoppingOnAS1688,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // 第二行文本
          Text(
            l10n.dailySuperDeals,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 登录表单
class _LoginForm extends StatefulWidget {
  final VoidCallback onSwitchToRegister;
  final bool isMobile;

  const _LoginForm({
    required this.onSwitchToRegister,
    required this.isMobile,
  });

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 执行登录
  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _authService.login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (response.isSuccess) {
          // 登录成功后，先获取用户详细信息
          debugPrint('🔐 登录成功，开始获取用户信息...');
          final userInfoResponse = await _authService.getUserInfo();
          debugPrint('📦 用户信息响应: ${userInfoResponse.isSuccess}');

          if (userInfoResponse.isSuccess && userInfoResponse.data != null) {
            final userInfo = userInfoResponse.data!;
            debugPrint('👤 用户信息: nickname=${userInfo.nickname}, role=${userInfo.role}');
            if (mounted) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.setUserInfo(UserInfo(
                id: userInfo.id,
                email: userInfo.username,
                nickname: userInfo.nickname,
                role: UserRole.fromString(userInfo.role),
                hasPaymentPassword: userInfo.hasPaymentPassword ?? false,
                balance: userInfo.balance,
                avatar: userInfo.avatar,
                inviteCode: userInfo.inviteCode,
              ));
              debugPrint('✅ AuthProvider状态已更新');
              debugPrint('🔍 isAuthenticated: ${authProvider.isAuthenticated}');
              debugPrint('🔍 userInfo: ${authProvider.userInfo?.nickname}');

              // 设置用户为在线状态
              await _authService.setOnlineStatus(1);
            }
          } else {
            debugPrint('❌ 获取用户信息失败: ${userInfoResponse.message}');
          }

          // 最后关闭对话框
          if (mounted) {
            Navigator.of(context).pop();

            // 延迟显示通知并加载统计数据，确保对话框完全关闭
            Future.delayed(const Duration(milliseconds: 100), () {
              final context = scaffoldMessengerKey.currentContext!;
              final l10n = AppLocalizations.of(context);
              scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(content: Text(l10n.loginSuccess)),
              );

              // 加载统计数据
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              appProvider.loadCartCount();
              appProvider.loadUserOrderStats();
              appProvider.loadPendingRecordCount();
              if (authProvider.isAdmin) {
                appProvider.loadPendingShopApplicationCount();
              }
              if (authProvider.isShop || authProvider.isAdmin || authProvider.isService) {
                appProvider.loadShopOrderStats(null);
              }
            });
          }
        } else {
          // 错误通知立即显示
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text(response.errorMessage)),
          );
        }
      } catch (e) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('${l10n.loginFailed}: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// 显示使用条款对话框
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _PolicyDialog(
        title: '使用条款',
        content: 'AS1688 and Merchant Terms\n\n'
            'If any unfair terms are found in the platform agreement, immediately stop signing and retain evidence. '
            'According to the E-Commerce Law, platforms must establish service agreements fairly. '
            'In cases of forced transactions or unreasonable security deposits, you have the right to request amendment of the terms or file a complaint with the regulatory authorities.\n\n'
            'Agreement Terms\n\n'
            'Security Deposit Ratio: The platform cannot require merchants to deposit more than 10 times the average transaction amount as a security deposit.\n\n'
            'Exit Clause: If there are no violations before exiting, no pending shipments, and all complaints have been resolved, the merchant should be allowed to withdraw all store funds. '
            'The security deposit must be returned within 7 days. However, according to Clause 16, the platform must announce exit rules at least 30 days in advance and must not create arbitrary obstacles.\n\n'
            'Data Rights Dispute: Merchants may not contact each other or customers proactively. Customers, however, may contact any merchant for purchase inquiries. Privacy and confidentiality must be observed.\n\n'
            'Store Requirement: Stores must deposit startup funds within 48 hours of opening.\n\n'
            'Store Registration Notice: Due to a large number of members, registration must be completed using an invitation code, otherwise the application will be rejected.\n\n'
            'Key Monitoring Points:\n\n'
            '○ Method of calculating the security deposit (Is it more than 20% of the average monthly transaction amount?)\n\n'
            '○ Dispute resolution process (Does it require mandatory acceptance of platform arbitration?)\n\n'
            '○ Account suspension conditions (Are there clear violation standards?)\n\n'
            'When handling disputes: (e.g., paying out of pocket or unpaid orders)\n\n'
            'Immediately back up data: Export the past 6 months of transaction records, customer service communications, and security deposit receipts.\n\n'
            'Three-Step Rights Protection Path:\n\n'
            '○ First, submit a written objection through the platform\'s internal complaint channel (keep screenshots of successful submission).\n\n'
            '○ If unresolved within 7 working days, file an "E-commerce Operator Illegal Business Complaint" with the Market Regulation Bureau at the platform\'s registered location.\n\n'
            '○ If the amount involved is substantial, you may file a lawsuit directly. Reference case: The Hangzhou Internet Court has established the legal principle that "the platform must prove the reasonableness of its terms."\n\n'
            'All terms and content in this agreement constitute the full agreement for joining the AS1688 platform. All three parties involved must abide by and uphold its legal validity. '
            'All parties shall follow the principles of strict compliance and mutual benefit. This agreement takes effect upon signing. The final interpretation right belongs to the AS1688 platform.',
      ),
    );
  }

  /// 显示个人信息隐私政策对话框
  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _PolicyDialog(
        title: '个人信息隐私政策',
        content: _privacyPolicyContent,
      ),
    );
  }

  /// 显示注销/删除账户指南对话框
  void _showAccountDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _PolicyDialog(
        title: '注销/删除账户指南',
        content: _accountDeletionContent,
      ),
    );
  }

  /// 显示忘记密码对话框
  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ForgotPasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: widget.isMobile ? double.infinity : 400,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // 标题
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hello,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.enterEmailToContinue,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 用户名输入框
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: l10n.emailPhone,
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterEmailPhone;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 密码输入框
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isLoading) {
                  _handleLogin();
                }
              },
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
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.login,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),

            // 注册按钮
            TextButton(
              onPressed: widget.onSwitchToRegister,
              child: Text(l10n.noAccountRegister),
            ),

            // 忘记密码按钮
            TextButton(
              onPressed: () => _showForgotPasswordDialog(context),
              child: Text(l10n.forgotPassword),
            ),
            const SizedBox(height: 16),

            // 底部文字信息
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.continueAgree,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                InkWell(
                  onTap: () => _showTermsDialog(context),
                  child: Text(
                    l10n.termsOfService,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ', ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                InkWell(
                  onTap: () => _showPrivacyDialog(context),
                  child: Text(
                    l10n.privacyPolicy,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' ${l10n.and} ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                InkWell(
                  onTap: () => _showAccountDeletionDialog(context),
                  child: Text(
                    l10n.accountDeletionGuide,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Text(
                  ' AS1688',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// 注册表单
class _RegisterForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  final bool isMobile;

  const _RegisterForm({
    required this.onSwitchToLogin,
    required this.isMobile,
  });

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 执行注册
  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _authService.register(
          username: _usernameController.text.trim(),
          nickname: _nicknameController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (response.isSuccess) {
          // 先关闭对话框
          Navigator.of(context).pop();

          // 延迟显示通知，确保对话框完全关闭
          Future.delayed(const Duration(milliseconds: 100), () {
            final l10n = AppLocalizations.of(scaffoldMessengerKey.currentContext!);
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text(l10n.registerSuccess)),
            );
          });
        } else {
          // 错误通知立即显示
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text(response.errorMessage)),
          );
        }
      } catch (e) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('${l10n.registerFailed}: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// 显示忘记密码对话框
  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ForgotPasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: widget.isMobile ? double.infinity : 400,
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
                  labelText: l10n.emailPhone,
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterEmailPhone;
                  }
                  if (value.length < 3) {
                    return l10n.usernameMinLength;
                  }
                  if (value.length > 100) {
                    return l10n.usernameMaxLength;
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
                  if (value.length > 50) {
                    return l10n.nicknameMaxLength;
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
                  if (value.length > 20) {
                    return l10n.passwordMaxLength;
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
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.register,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              // 登录按钮
              TextButton(
                onPressed: widget.onSwitchToLogin,
                child: Text(l10n.alreadyHaveAccount),
              ),

              // 忘记密码按钮
              TextButton(
                onPressed: () => _showForgotPasswordDialog(context),
                child: Text(l10n.forgotPassword),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 政策对话框（用于显示使用条款、隐私政策等）
class _PolicyDialog extends StatelessWidget {
  final String title;
  final String content;

  const _PolicyDialog({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        width: isMobile ? double.infinity : 600,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // 内容
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 关闭按钮
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(l10n.iUnderstand),
            ),
          ],
        ),
      ),
    );
  }
}

/// 忘记密码对话框
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _accountController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  /// 执行找回密码
  void _handleRecover() {
    final l10n = AppLocalizations.of(context);
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: 实现找回密码逻辑
      Navigator.of(context).pop();
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordResetSent)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        width: isMobile ? double.infinity : 400,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Text(
                l10n.recoverPassword,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 邮箱/手机号输入框
              TextFormField(
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: l10n.emailPhone,
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterEmailPhone;
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
              const SizedBox(height: 24),

              // 找回按钮
              ElevatedButton(
                onPressed: _handleRecover,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  l10n.recoverPassword,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
