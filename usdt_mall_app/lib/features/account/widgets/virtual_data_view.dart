import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/virtual_data_api.dart';
import '../../../core/models/api_response.dart';
import '../../../core/utils/responsive_util.dart';

/// 管理员虚拟数据。生成商户号、生成商品、生成订单和任务进度在同一页。
class VirtualDataView extends StatefulWidget {
  const VirtualDataView({super.key});

  @override
  State<VirtualDataView> createState() => _VirtualDataViewState();
}

class _VirtualDataViewState extends State<VirtualDataView> {
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(text: 'Virtual@2026');

  String? _prefixError;
  String? _countError;
  String? _passwordError;
  String? _formError;
  String? _previewSentence;
  String? _previewedPrefix;
  int? _previewedCount;

  bool _previewing = false;
  bool _submitting = false;
  bool _productSubmitting = false;
  bool _orderSubmitting = false;
  bool _loadingTasks = true;
  String? _tasksError;

  Map<String, dynamic>? _activeTask;
  List<Map<String, dynamic>> _tasks = [];
  Timer? _pollTimer;
  int? _pollingTaskId;
  String? _pollingType;
  bool _pollInFlight = false;

  final TextEditingController _shopSearchController = TextEditingController();
  final TextEditingController _productCountController = TextEditingController();
  String? _productCountError;
  String? _productFormError;
  final Map<String, TextEditingController> _orderControllers = {
    'pendingShipment': TextEditingController(text: '0'),
    'pendingReceipt': TextEditingController(text: '0'),
    'completed': TextEditingController(text: '0'),
    'cancelled': TextEditingController(text: '0'),
    'rechargeCount': TextEditingController(text: '0'),
    'withdrawCount': TextEditingController(text: '0'),
  };
  final Map<String, String> _orderLabels = {
    'pendingShipment': '待发货',
    'pendingReceipt': '待收货',
    'completed': '已完成',
    'cancelled': '已取消',
    'rechargeCount': '充值条数',
    'withdrawCount': '提现条数',
  };
  final Set<int> _selectedShopIds = {};
  final Map<String, String> _orderFieldErrors = {};
  String? _orderFormError;
  String _shopKeyword = '';
  int _shopPage = 1;
  int _shopTotal = 0;
  int _shopPageSize = 20;
  bool _loadingShops = true;
  String? _shopsError;
  List<Map<String, dynamic>> _shops = [];

  @override
  void initState() {
    super.initState();
    _loadTasks(resumeRunning: true);
    _loadShops();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _prefixController.dispose();
    _countController.dispose();
    _passwordController.dispose();
    _shopSearchController.dispose();
    _productCountController.dispose();
    for (final controller in _orderControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _tryCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return int.tryParse(trimmed);
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }

  String _apiError(ApiResponse<dynamic> response) {
    final cn = response.cnMsg?.trim();
    if (cn != null && cn.isNotEmpty) {
      return cn;
    }
    final message = response.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return '请求失败';
  }

  void _clearFieldErrors() {
    _prefixError = null;
    _countError = null;
    _passwordError = null;
    _formError = null;
  }

  void _showFieldError(String message) {
    _prefixError = null;
    _countError = null;
    _passwordError = null;
    _formError = null;
    if (message.contains('前缀')) {
      _prefixError = message;
    } else if (message.contains('密码')) {
      _passwordError = message;
    } else if (message.contains('数量')) {
      _countError = message;
    } else {
      _formError = message;
    }
  }

  void _invalidatePreview() {
    _previewSentence = null;
    _previewedPrefix = null;
    _previewedCount = null;
  }

  bool get _canConfirm {
    if (_previewing || _submitting || _previewSentence == null) {
      return false;
    }
    return _prefixController.text.trim() == _previewedPrefix &&
        _tryCount(_countController.text) == _previewedCount;
  }

  String _padSerial(int no) {
    return no.toString().padLeft(2, '0');
  }

  String _sentenceFor(Map<String, dynamic> preview) {
    final prefix = preview['prefix']?.toString() ?? '';
    final rawNames = preview['usernames'];
    final names = <String>[];
    if (rawNames is List) {
      for (final name in rawNames) {
        final text = name?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          names.add(text);
        }
      }
    }
    final startName = names.isNotEmpty
        ? names.first
        : '$prefix${_padSerial(_asInt(preview['startNo']))}';
    final endName = names.isNotEmpty
        ? names.last
        : '$prefix${_padSerial(_asInt(preview['endNo']))}';
    final currentMax = preview['currentMax'];
    if (currentMax == null) {
      if (startName == endName) {
        return '将从 $startName 开始。';
      }
      return '将从 $startName 开始，本次生成 $startName–$endName。';
    }
    final maxName = '$prefix${_padSerial(_asInt(currentMax))}';
    if (startName == endName) {
      return '当前最大 $maxName，本次生成 $startName。';
    }
    return '当前最大 $maxName，本次生成 $startName–$endName。';
  }

  Future<void> _preview() async {
    final prefix = _prefixController.text.trim();
    final count = _tryCount(_countController.text);
    setState(() {
      _previewing = true;
      _clearFieldErrors();
      _invalidatePreview();
    });
    try {
      final response = await VirtualDataApi.previewShops(
        prefix: prefix,
        count: count,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _previewing = false;
        if (response.isSuccess && response.data != null) {
          _previewedPrefix = prefix;
          _previewedCount = count;
          _previewSentence = _sentenceFor(response.data!);
        } else {
          _showFieldError(_apiError(response));
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _previewing = false;
        _formError = '预览失败：$e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_canConfirm) {
      return;
    }
    final prefix = _previewedPrefix ?? '';
    final count = _previewedCount;
    final password = _passwordController.text;
    if (password.length < 6 || password.length > 32) {
      setState(() {
        _passwordError = '登录密码长度必须是 6 到 32';
      });
      return;
    }
    setState(() {
      _submitting = true;
      _clearFieldErrors();
    });
    try {
      final response = await VirtualDataApi.submitShops(
        prefix: prefix,
        count: count,
        password: password,
      );
      if (!mounted) {
        return;
      }
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _submitting = false;
          _showFieldError(_apiError(response));
        });
        return;
      }
      final taskId = _asInt(response.data!['taskId']);
      if (taskId <= 0) {
        setState(() {
          _submitting = false;
          _formError = '没有拿到任务编号';
        });
        return;
      }
      _startPolling(taskId, type: 'SHOP');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _formError = '提交失败：$e';
      });
    }
  }

  void _startPolling(int taskId, {String? type}) {
    _pollTimer?.cancel();
    _pollingTaskId = taskId;
    _pollingType = type;
    _pollOnce();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollOnce();
    });
  }

  Future<void> _pollOnce() async {
    final taskId = _pollingTaskId;
    if (taskId == null || _pollInFlight) {
      return;
    }
    _pollInFlight = true;
    try {
      final response = await VirtualDataApi.getTask(taskId);
      if (!mounted || _pollingTaskId != taskId) {
        return;
      }
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _formError = _apiError(response);
        });
        if (response.cnMsg == '任务不存在') {
          _stopPolling(clearSubmitting: true);
        }
        return;
      }
      final task = Map<String, dynamic>.from(response.data!);
      final status = task['status']?.toString();
      setState(() {
        _activeTask = task;
      });
      if (status != 'PENDING' && status != 'RUNNING') {
        final finishedType = _pollingType;
        _stopPolling(clearSubmitting: true);
        _loadTasks();
        if (finishedType == 'PRODUCT') {
          _loadShops();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _formError = '进度读取失败：$e';
        });
      }
    } finally {
      _pollInFlight = false;
    }
  }

  void _stopPolling({required bool clearSubmitting}) {
    final type = _pollingType;
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollingTaskId = null;
    _pollingType = null;
    if (clearSubmitting && mounted) {
      setState(() {
        if (type == 'ORDER_LEDGER') {
          _orderSubmitting = false;
        } else if (type == 'PRODUCT') {
          _productSubmitting = false;
        } else if (type == 'SHOP') {
          _submitting = false;
        }
      });
    }
  }

  Future<void> _loadTasks({bool resumeRunning = false}) async {
    try {
      final response = await VirtualDataApi.listTasks(page: 1, pageSize: 10);
      if (!mounted) {
        return;
      }
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _loadingTasks = false;
          _tasksError = _apiError(response);
        });
        return;
      }
      final raw = response.data!['records'];
      final records = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            records.add(Map<String, dynamic>.from(item));
          }
        }
      }
      setState(() {
        _tasks = records;
        _loadingTasks = false;
        _tasksError = null;
      });
      if (resumeRunning && _pollingTaskId == null) {
        Map<String, dynamic>? newest;
        var shopRunning = false;
        var productRunning = false;
        var orderRunning = false;
        for (final task in records) {
          final status = task['status']?.toString();
          if (status != 'PENDING' && status != 'RUNNING') {
            continue;
          }
          newest ??= task;
          final type = task['type']?.toString();
          if (type == 'SHOP') {
            shopRunning = true;
          } else if (type == 'PRODUCT') {
            productRunning = true;
          } else if (type == 'ORDER_LEDGER') {
            orderRunning = true;
          }
        }
        if (shopRunning || productRunning || orderRunning || newest != null) {
          setState(() {
            if (shopRunning) {
              _submitting = true;
            }
            if (productRunning) {
              _productSubmitting = true;
            }
            if (orderRunning) {
              _orderSubmitting = true;
            }
            if (newest != null) {
              _activeTask = newest;
            }
          });
        }
        if (newest != null) {
          _startPolling(
            _asInt(newest['id']),
            type: newest['type']?.toString(),
          );
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingTasks = false;
        _tasksError = '任务列表加载失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '虚拟数据',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          _buildShopSection(),
          const SizedBox(height: 24),
          _buildProgressSection(),
          const SizedBox(height: 24),
          _buildShopPickerSection(),
          const SizedBox(height: 24),
          _buildProductSection(),
          const SizedBox(height: 24),
          _buildOrderSection(),
        ],
      ),
    );
  }

  Widget _buildShopSection() {
    return _section(
      title: '生成商户号',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledField(
            label: '前缀',
            controller: _prefixController,
            hint: '字母和数字，2 到 20 位',
            errorText: _prefixError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _labeledField(
            label: '数量',
            controller: _countController,
            hint: '1 到 200 的整数',
            errorText: _countError,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _labeledField(
            label: '登录密码',
            controller: _passwordController,
            hint: '6 到 32 位',
            errorText: _passwordError,
            textInputAction: TextInputAction.done,
            clearsPreview: false,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _actionButton(
                label: _previewing ? '预览中' : '预览',
                busy: _previewing,
                onPressed: _previewing || _submitting ? null : _preview,
                filled: false,
              ),
              _actionButton(
                label: _submitting ? '生成中' : '确认生成',
                busy: _submitting,
                onPressed: _canConfirm ? _submit : null,
                filled: true,
              ),
            ],
          ),
          if (_formError != null) ...[
            const SizedBox(height: 8),
            Text(
              _formError!,
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (_previewSentence != null) ...[
            const SizedBox(height: 16),
            Text(
              _previewSentence!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF212121),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? errorText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    bool clearsPreview = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onChanged: (_) {
            setState(() {
              if (clearsPreview) {
                _invalidatePreview();
              }
              if (label == '前缀') {
                _prefixError = null;
              } else if (label == '登录密码') {
                _passwordError = null;
              } else {
                _countError = null;
              }
            });
          },
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required bool busy,
    required VoidCallback? onPressed,
    required bool filled,
  }) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );
    const style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(44, 44)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: style.merge(ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.blue[200],
          disabledForegroundColor: Colors.white,
        )),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }

  Widget _buildProgressSection() {
    final latest = _tasks.isEmpty ? null : _tasks.first;
    final card = _activeTask ?? latest;
    final status = card?['status']?.toString();
    final highlighted = status == 'PENDING' || status == 'RUNNING';

    return _section(
      title: '任务进度',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近任务',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingTasks && card == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_tasksError != null && card == null)
            Text(
              _tasksError!,
              style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 14),
            )
          else if (card == null)
            Text(
              '还没有任务',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            )
          else
            _buildTaskCard(card, highlighted: highlighted),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task,
      {required bool highlighted}) {
    final status = task['status']?.toString();
    final success = _asInt(task['successCount']);
    final fail = _asInt(task['failCount']);
    final message = task['message']?.toString() ?? '';
    final summary =
        '${_typeText(task['type']?.toString())}，${_statusText(status)}。成功 $success 条，失败 $fail 条。';
    final details = _groupedFailLines(task['failDetails']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFE3F2FD) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? Colors.blue[200]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: highlighted,
            child: Text(
              summary,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF212121),
              ),
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              message,
              style:
                  TextStyle(fontSize: 14, height: 1.4, color: Colors.grey[800]),
            ),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '失败原因',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: details.length > 4 ? 180 : null,
              child: ListView.separated(
                shrinkWrap: details.length <= 4,
                primary: false,
                physics: details.length > 4
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: details.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  return Text(
                    details[index],
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFFB71C1C),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _groupedFailLines(dynamic raw) {
    if (raw is! List) {
      return [];
    }
    final counts = <String, int>{};
    final order = <String>[];
    for (final item in raw) {
      if (item is! Map) {
        continue;
      }
      final target = item['target']?.toString() ?? '';
      final reason = item['reason']?.toString() ?? '';
      final line = target.isEmpty ? reason : '$target：$reason';
      if (line.isEmpty) {
        continue;
      }
      if (!counts.containsKey(line)) {
        order.add(line);
      }
      counts[line] = (counts[line] ?? 0) + 1;
    }
    return [
      for (final line in order)
        (counts[line] ?? 0) > 1 ? '$line（${counts[line]} 条）' : line,
    ];
  }

  String _statusText(String? status) {
    switch (status) {
      case 'PENDING':
        return '等待';
      case 'RUNNING':
        return '进行中';
      case 'SUCCESS':
        return '成功';
      case 'PARTIAL':
        return '部分成功';
      case 'FAILED':
        return '失败';
      default:
        return '未知';
    }
  }

  String _typeText(String? type) {
    switch (type) {
      case 'SHOP':
        return '生成商户号';
      case 'PRODUCT':
        return '生成商品';
      case 'ORDER_LEDGER':
        return '生成订单';
      default:
        return '任务';
    }
  }

  Future<void> _loadShops() async {
    setState(() {
      _loadingShops = true;
      _shopsError = null;
    });
    try {
      final response = await VirtualDataApi.listShops(
        keyword: _shopKeyword.isEmpty ? null : _shopKeyword,
        page: _shopPage,
        pageSize: _shopPageSize,
      );
      if (!mounted) {
        return;
      }
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _loadingShops = false;
          _shopsError = _apiError(response);
          _shops = [];
        });
        return;
      }
      final data = response.data!;
      final raw = data['records'];
      final shops = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map && item['shopId'] != null) {
            shops.add(Map<String, dynamic>.from(item));
          }
        }
      }
      setState(() {
        _shops = shops;
        _shopTotal = _asInt(data['total']);
        _shopPage =
            _asInt(data['page']) == 0 ? _shopPage : _asInt(data['page']);
        final size = _asInt(data['pageSize']);
        if (size > 0) {
          _shopPageSize = size;
        }
        _loadingShops = false;
        _shopsError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingShops = false;
        _shopsError = '店铺列表加载失败：$e';
        _shops = [];
      });
    }
  }

  void _searchShops() {
    setState(() {
      _shopKeyword = _shopSearchController.text.trim();
      _shopPage = 1;
    });
    _loadShops();
  }

  void _toggleShop(int shopId) {
    setState(() {
      if (_selectedShopIds.contains(shopId)) {
        _selectedShopIds.remove(shopId);
      } else {
        _selectedShopIds.add(shopId);
      }
      _orderFormError = null;
      _productFormError = null;
      _productCountError = null;
    });
  }

  int? _orderCount(String key) {
    final text = _orderControllers[key]?.text.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return int.tryParse(text);
  }

  void _showOrderError(String message) {
    _orderFieldErrors.clear();
    _orderFormError = null;
    const fieldKeys = {
      '待发货': 'pendingShipment',
      '待收货': 'pendingReceipt',
      '已完成': 'completed',
      '已取消': 'cancelled',
      '充值': 'rechargeCount',
      '提现': 'withdrawCount',
    };
    for (final entry in fieldKeys.entries) {
      if (message.contains(entry.key)) {
        _orderFieldErrors[entry.value] = message;
        return;
      }
    }
    _orderFormError = message;
  }

  Future<void> _submitOrders() async {
    if (_orderSubmitting) {
      return;
    }
    setState(() {
      _orderSubmitting = true;
      _orderFieldErrors.clear();
      _orderFormError = null;
    });
    try {
      final response = await VirtualDataApi.submitOrders(
        shopIds: _selectedShopIds.toList(),
        pendingShipment: _orderCount('pendingShipment'),
        pendingReceipt: _orderCount('pendingReceipt'),
        completed: _orderCount('completed'),
        cancelled: _orderCount('cancelled'),
        rechargeCount: _orderCount('rechargeCount'),
        withdrawCount: _orderCount('withdrawCount'),
      );
      if (!mounted) {
        return;
      }
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _orderSubmitting = false;
          _showOrderError(_apiError(response));
        });
        return;
      }
      final taskId = _asInt(response.data!['taskId']);
      if (taskId <= 0) {
        setState(() {
          _orderSubmitting = false;
          _orderFormError = '没有拿到任务编号';
        });
        return;
      }
      _startPolling(taskId, type: 'ORDER_LEDGER');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _orderSubmitting = false;
        _orderFormError = '提交失败：$e';
      });
    }
  }

  Widget _buildShopPickerSection() {
    final pageCount = _shopPageSize <= 0
        ? 1
        : ((_shopTotal + _shopPageSize - 1) / _shopPageSize).ceil();
    return _section(
      title: '选择店铺',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '搜索店铺',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shopSearchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchShops(),
                  decoration: const InputDecoration(
                    hintText: '用户名或店名',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _actionButton(
                label: '搜索',
                busy: false,
                onPressed: _loadingShops ? null : _searchShops,
                filled: false,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '已选 ${_selectedShopIds.length} 家。生成商品和生成订单都只用这些店。',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingShops)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_shopsError != null)
            Text(
              _shopsError!,
              style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 14),
            )
          else if (_shops.isEmpty)
            Text(
              '没有店铺',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            )
          else
            ..._shops.map(_buildShopOption),
          if (!_loadingShops && _shopsError == null && pageCount > 1) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _actionButton(
                  label: '上一页',
                  busy: false,
                  filled: false,
                  onPressed: _shopPage <= 1
                      ? null
                      : () {
                          setState(() {
                            _shopPage -= 1;
                          });
                          _loadShops();
                        },
                ),
                Text(
                  '第 $_shopPage / $pageCount 页，共 $_shopTotal 家',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF424242)),
                ),
                _actionButton(
                  label: '下一页',
                  busy: false,
                  filled: false,
                  onPressed: _shopPage >= pageCount
                      ? null
                      : () {
                          setState(() {
                            _shopPage += 1;
                          });
                          _loadShops();
                        },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitProducts() async {
    if (_productSubmitting) {
      return;
    }
    final text = _productCountController.text.trim();
    final count = text.isEmpty ? null : int.tryParse(text);
    setState(() {
      _productSubmitting = true;
      _productCountError = null;
      _productFormError = null;
    });
    try {
      final response = await VirtualDataApi.submitProducts(
        shopIds: _selectedShopIds.toList(),
        count: count,
      );
      if (!mounted) {
        return;
      }
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _productSubmitting = false;
          _showProductError(_apiError(response));
        });
        return;
      }
      final taskId = _asInt(response.data!['taskId']);
      if (taskId <= 0) {
        setState(() {
          _productSubmitting = false;
          _productFormError = '没有拿到任务编号';
        });
        return;
      }
      _startPolling(taskId, type: 'PRODUCT');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _productSubmitting = false;
        _productFormError = '提交失败：$e';
      });
    }
  }

  void _showProductError(String message) {
    _productCountError = null;
    _productFormError = null;
    if (message.contains('商品数量')) {
      _productCountError = message;
      return;
    }
    _productFormError = message;
  }

  Widget _buildProductSection() {
    return _section(
      title: '生成商品',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '商品数量',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _productCountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              setState(() {
                _productCountError = null;
              });
            },
            decoration: InputDecoration(
              hintText: '1 到 500',
              errorText: _productCountError,
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
          if (_productFormError != null) ...[
            const SizedBox(height: 8),
            Text(
              _productFormError!,
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            '每家选中的店都会各添加这些商品。名称、图片和价格从现有商品复制。',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: _productSubmitting ? '生成中' : '生成商品',
            busy: _productSubmitting,
            filled: true,
            onPressed: _productSubmitting ? null : _submitProducts,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSection() {
    return _section(
      title: '生成订单',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已选 ${_selectedShopIds.length} 家',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          for (final entry in _orderLabels.entries) ...[
            _orderCountField(entry.key, entry.value),
            const SizedBox(height: 16),
          ],
          if (_orderFormError != null) ...[
            Text(
              _orderFormError!,
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            '每家选中的店都会各生成这些数量',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: _orderSubmitting ? '生成中' : '生成订单',
            busy: _orderSubmitting,
            filled: true,
            onPressed: _orderSubmitting ? null : _submitOrders,
          ),
        ],
      ),
    );
  }

  Widget _buildShopOption(Map<String, dynamic> shop) {
    final shopId = _asInt(shop['shopId']);
    final selected = _selectedShopIds.contains(shopId);
    final shopName = shop['shopName']?.toString() ?? '';
    final username = shop['username']?.toString() ?? '';
    final onSaleCount = _asInt(shop['onSaleCount']);
    final noSale = onSaleCount == 0;
    final label = noSale
        ? '$shopName（$username），无在售商品，订单会失败'
        : '$shopName（$username），在售 $onSaleCount';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFE3F2FD) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _toggleShop(shopId),
          child: Semantics(
            checked: selected,
            label: label,
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IgnorePointer(
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Checkbox(
                          value: selected,
                          onChanged: (_) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            shopName.isEmpty
                                ? username
                                : '$shopName（$username）',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Color(0xFF212121),
                            ),
                          ),
                          Text(
                            '在售 $onSaleCount',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Color(0xFF424242),
                            ),
                          ),
                          if (noSale)
                            const Text(
                              '无在售商品，订单会失败',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Color(0xFFB71C1C),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orderCountField(String key, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _orderControllers[key],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            setState(() {
              _orderFieldErrors.remove(key);
            });
          },
          decoration: InputDecoration(
            hintText: '0 到 500',
            errorText: _orderFieldErrors[key],
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
