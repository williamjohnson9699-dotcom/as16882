import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/router_service.dart';

/// 网站首页AppBar组件
class LandingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LandingAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      toolbarHeight: 70,
      title: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLogo(context),
        _buildActions(context),
      ],
    );
  }

  /// 构建Logo
  Widget _buildLogo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Image.asset(
      'assets/pic/logo1.jpg',
      width: 96,
    );
  }

  /// 构建右侧操作按钮
  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        _buildLanguageSelector(context),
        const SizedBox(width: 16),
        _buildJoinButton(context),
      ],
    );
  }

  /// 构建语言选择器
  Widget _buildLanguageSelector(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currentLocale = appProvider.locale;
    final currentLang = SupportedLocale.fromLocale(currentLocale);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopupMenuButton<SupportedLocale>(
      position: PopupMenuPosition.under,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: isMobile ? 14 : 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.language, size: 20),
            const SizedBox(width: 4),
            Text(
              currentLang.label,
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
      onSelected: (locale) {
        context.read<AppProvider>().changeLocale(locale.locale);
      },
      itemBuilder: (context) {
        return SupportedLocale.values.map((locale) {
          return PopupMenuItem<SupportedLocale>(
            value: locale,
            child: Text(locale.label),
          );
        }).toList();
      },
    );
  }

  /// 构建"立即入驻"按钮
  Widget _buildJoinButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ElevatedButton(
      onPressed: () {
        context.go(RoutePaths.home);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.store, size: 20),
          const SizedBox(width: 8),
          Text(
            l10n.joinNow,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
