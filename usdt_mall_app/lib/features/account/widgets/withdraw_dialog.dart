import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive_util.dart';

/// 提现对话框
class WithdrawDialog extends StatefulWidget {
  final Function(String paymentMethod, double amount, String receivingAddress, String paymentPassword) onSubmit;

  const WithdrawDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _receivingAddressController = TextEditingController();
  final _paymentPasswordController = TextEditingController();

  String _selectedPaymentMethod = 'USDT-TRC20';
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  final List<String> _paymentMethods = [
    'USDT-TRC20',
    'USDT-ERC20',
    'BTC',
    'ETH',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _receivingAddressController.dispose();
    _paymentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      title: Text(l10n.withdraw),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 400,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPaymentMethodDropdown(),
                const SizedBox(height: 16),
                _buildAmountField(),
                const SizedBox(height: 16),
                _buildReceivingAddressField(),
                const SizedBox(height: 16),
                _buildPaymentPasswordField(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.submit),
        ),
      ],
    );
  }

  /// 构建提现方式下拉选择
  Widget _buildPaymentMethodDropdown() {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: InputDecoration(
        labelText: l10n.withdrawMethod,
        border: const OutlineInputBorder(),
      ),
      items: _paymentMethods.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Text(method),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        }
      },
    );
  }

  /// 构建金额输入框
  Widget _buildAmountField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: l10n.withdrawAmount,
        border: const OutlineInputBorder(),
        prefixText: '\$ ',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.pleaseEnterWithdrawAmount;
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return l10n.pleaseEnterValidAmount;
        }
        return null;
      },
    );
  }

  /// 构建收款地址输入框
  Widget _buildReceivingAddressField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _receivingAddressController,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: l10n.translate('receiving_address'),
        border: const OutlineInputBorder(),
        hintText: l10n.translate('please_enter_receiving_address'),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.translate('please_enter_receiving_address');
        }
        return null;
      },
    );
  }

  /// 构建支付密码输入框
  Widget _buildPaymentPasswordField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _paymentPasswordController,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        labelText: l10n.paymentPassword,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.pleaseEnterPaymentPassword;
        }
        if (value.length != 6) {
          return l10n.paymentPasswordMustBe6Digits;
        }
        return null;
      },
    );
  }

  /// 处理提交
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final receivingAddress = _receivingAddressController.text.trim();
      final paymentPassword = _paymentPasswordController.text;

      await widget.onSubmit(_selectedPaymentMethod, amount, receivingAddress, paymentPassword);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
