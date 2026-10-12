import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/unread_message_provider.dart';
import 'core/services/router_service_v2.dart';
import 'core/l10n/app_localizations.dart';

// 全局 ScaffoldMessenger Key，用于在任何地方显示通知
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  late final AppProvider _appProvider;
  late final UnreadMessageProvider _unreadMessageProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // 在 initState 中创建 providers 和 router，只创建一次
    _authProvider = AuthProvider()..init();
    _appProvider = AppProvider();
    _unreadMessageProvider = UnreadMessageProvider();
    _router = RouterServiceV2.createRouter(_authProvider);

    // 初始化未读消息 Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _unreadMessageProvider.init(_authProvider);
    });
  }

  @override
  void dispose() {
    _unreadMessageProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _appProvider),
        ChangeNotifierProvider.value(value: _unreadMessageProvider),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp.router(
            title: 'AS1688 Mall',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: scaffoldMessengerKey,
            locale: appProvider.locale,
            supportedLocales: SupportedLocale.values.map((e) => e.locale).toList(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
              snackBarTheme: const SnackBarThemeData(
                behavior: SnackBarBehavior.fixed,
                showCloseIcon: true,
                closeIconColor: Colors.white,
              ),
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
