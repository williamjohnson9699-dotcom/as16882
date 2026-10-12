import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/system_config_api.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive_util.dart';

/// 系统配置视图
class SystemConfigView extends StatefulWidget {
  const SystemConfigView({super.key});

  @override
  State<SystemConfigView> createState() => _SystemConfigViewState();
}

class _SystemConfigViewState extends State<SystemConfigView> {
  int _profitRate = 65;
  String _receivingAddress = '';
  bool _isLoading = true;
  bool _isSaving = false;
  final TextEditingController _profitRateController = TextEditingController();
  final TextEditingController _receivingAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  @override
  void dispose() {
    _profitRateController.dispose();
    _receivingAddressController.dispose();
    super.dispose();
  }

  /// 加载配置
  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profitRateResponse = await SystemConfigApi.getProfitRate();
      final addressResponse = await SystemConfigApi.getReceivingAddress();

      if (profitRateResponse.isSuccess && profitRateResponse.data != null) {
        _profitRate = profitRateResponse.data!;
        _profitRateController.text = _profitRate.toString();
      }

      if (addressResponse.isSuccess && addressResponse.data != null) {
        _receivingAddress = addressResponse.data!;
        _receivingAddressController.text = _receivingAddress;
      }

      setState(() {
        _isLoading = false;
      });
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

  /// 加载利润率配置
  Future<void> _loadProfitRate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SystemConfigApi.getProfitRate();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _profitRate = response.data!;
          _profitRateController.text = _profitRate.toString();
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

  /// 保存利润率配置
  Future<void> _saveProfitRate() async {
    final l10n = AppLocalizations.of(context);

    // 验证输入
    final inputValue = _profitRateController.text.trim();
    if (inputValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('profit_rate_required'))),
      );
      return;
    }

    final profitRate = int.tryParse(inputValue);
    if (profitRate == null || profitRate < 0 || profitRate > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('profit_rate_range_error'))),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await SystemConfigApi.updateProfitRate(profitRate);

      setState(() {
        _isSaving = false;
      });

      if (response.isSuccess) {
        setState(() {
          _profitRate = profitRate;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('save_success'))),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.translate('save_failed')}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('save_failed')}: $e')),
        );
      }
    }
  }

  /// 保存收款地址
  Future<void> _saveReceivingAddress() async {
    final l10n = AppLocalizations.of(context);
    final address = _receivingAddressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('receiving_address_required'))),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await SystemConfigApi.updateReceivingAddress(address);
      if (response.isSuccess) {
        setState(() {
          _receivingAddress = address;
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('save_success'))),
          );
        }
      } else {
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.translate('save_failed')}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('save_failed')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(child: _buildConfigForm()),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('system_config'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.translate('system_config_desc'),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// 构建配置表单
  Widget _buildConfigForm() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('profit_rate_config'),
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              if (isMobile)
                // 移动端：垂直布局
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _profitRateController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('profit_rate'),
                        labelStyle: const TextStyle(fontSize: 13),
                        hintText: l10n.translate('profit_rate_hint'),
                        hintStyle: const TextStyle(fontSize: 13),
                        suffixText: '%',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfitRate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                l10n.translate('save'),
                                style: const TextStyle(fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                )
              else
                // 桌面端：水平布局
                Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _profitRateController,
                        decoration: InputDecoration(
                          labelText: l10n.translate('profit_rate'),
                          hintText: l10n.translate('profit_rate_hint'),
                          suffixText: '%',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfitRate,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.translate('save')),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Text(
                l10n.translate('profit_rate_description'),
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: isMobile ? 24 : 32),
              Text(
                l10n.translate('receiving_address_config'),
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _receivingAddressController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('receiving_address'),
                        labelStyle: const TextStyle(fontSize: 13),
                        hintText: l10n.translate('receiving_address_hint'),
                        hintStyle: const TextStyle(fontSize: 13),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveReceivingAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                l10n.translate('save'),
                                style: const TextStyle(fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _receivingAddressController,
                        decoration: InputDecoration(
                          labelText: l10n.translate('receiving_address'),
                          hintText: l10n.translate('receiving_address_hint'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveReceivingAddress,
                      child: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.translate('save')),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Text(
                l10n.translate('receiving_address_description'),
                style: TextStyle(fontSize: isMobile ? 12 : 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
