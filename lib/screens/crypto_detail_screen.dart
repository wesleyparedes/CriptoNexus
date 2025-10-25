import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/crypto.dart';
import 'package:flutter/services.dart';

class CryptoDetailScreen extends StatefulWidget {
  final Crypto crypto;
  final bool isFavorite;
  final Function(Crypto, bool) onToggleFavorite;

  const CryptoDetailScreen({
    super.key,
    required this.crypto,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  late bool _isFavorite;
  List<FlSpot> _chartData = [];
  bool _isChartLoading = true;
  int _selectedDays = 1;
  final TextEditingController _cryptoController = TextEditingController();
  final TextEditingController _realController = TextEditingController();
  late FocusNode _realFocusNode;
  late FocusNode _cryptoFocusNode;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _fetchChartData();
    _realFocusNode = FocusNode();
    _cryptoFocusNode = FocusNode();
    _realFocusNode.addListener(_handleRealFocusChange);
    _cryptoFocusNode.addListener(_handleCryptoFocusChange);
  }

  void _handleRealFocusChange() {
    if (!_realFocusNode.hasFocus) {
      _formatTextField(_realController, isBRL: true);
    }
  }

  void _handleCryptoFocusChange() {
    if (!_cryptoFocusNode.hasFocus) {
      _formatTextField(_cryptoController, isBRL: false);
    }
  }

  @override
  void dispose() {
    _cryptoController.dispose();
    _realController.dispose();
    _realFocusNode.dispose();
    _cryptoFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_realController.text.isEmpty && _cryptoController.text.isEmpty) {
      _realController.text = NumberFormat.currency(locale: 'pt_BR', symbol: '').format(0.00).trim();
      _cryptoController.text = NumberFormat('#,##0.0', 'pt_BR').format(0.0);
    }
  }

  Future<void> _fetchChartData() async {
    if (!mounted) return;
    setState(() => _isChartLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'chart_cache_${widget.crypto.id}_$_selectedDays';
    final cacheTimeKey = '${cacheKey}_time';
    final cachedData = prefs.getString(cacheKey);
    final cachedTime = prefs.getInt(cacheTimeKey);
    final now = DateTime.now().millisecondsSinceEpoch;
    final bool cacheValido = cachedData != null && cachedTime != null && (now - cachedTime) < 300000;
    if (cacheValido) {
      final data = jsonDecode(cachedData) as List<dynamic>;
      final chartData = data.map((p) => FlSpot((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList();
      setState(() {
        _chartData = chartData;
        _isChartLoading = false;
      });
      return;
    }
    final uri = Uri.parse("https://api.coingecko.com/api/v3/coins/${widget.crypto.id}/market_chart?vs_currency=brl&days=$_selectedDays");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200 && mounted) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> prices = data['prices'];
        await prefs.setString(cacheKey, jsonEncode(prices));
        await prefs.setInt(cacheTimeKey, now);
        final chartData = prices.map((price) => FlSpot((price[0] as num).toDouble(), (price[1] as num).toDouble())).toList();
        setState(() {
          _chartData = chartData;
          _isChartLoading = false;
        });
      } else {
        if (cachedData != null) {
          final data = jsonDecode(cachedData) as List<dynamic>;
          final chartData = data.map((p) => FlSpot((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList();
          setState(() {
            _chartData = chartData;
            _isChartLoading = false;
          });
        }
      }
    } catch (e) {
      if (cachedData != null) {
        final data = jsonDecode(cachedData) as List<dynamic>;
        final chartData = data.map((p) => FlSpot((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList();
        setState(() {
          _chartData = chartData;
          _isChartLoading = false;
        });
      } else {
        setState(() => _isChartLoading = false);
      }
    }
  }

  void _onToggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onToggleFavorite(widget.crypto, _isFavorite);
    final fcm = FirebaseMessaging.instance;
    final topicId = widget.crypto.id;
    if (_isFavorite) {
      fcm.subscribeToTopic(topicId);
    } else {
      fcm.unsubscribeFromTopic(topicId);
    }
  }

  String _formatPriceFull(double price) {
    if (price < 1.0) {
      return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 6).format(price);
    }
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2).format(price);
  }

  void _formatTextField(TextEditingController controller, {required bool isBRL}) {
    String cleanValue = controller.text.replaceAll(RegExp(r'[R$]'), '').replaceAll('.', '').replaceAll(',', '.').trim();
    double amount = double.tryParse(cleanValue) ?? 0.0;
    String formattedText;
    if (isBRL) {
      formattedText = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(amount);
    } else {
      formattedText = NumberFormat('#,##0.000000', 'pt_BR').format(amount);
    }
    controller.value = controller.value.copyWith(
      text: formattedText.trim(),
      selection: TextSelection.collapsed(offset: formattedText.trim().length),
    );
  }

  void _onRealChanged(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[R$]'), '').replaceAll('.', '').replaceAll(',', '.').trim();
    final amount = double.tryParse(cleanValue) ?? 0.0;
    if (widget.crypto.currentPrice != 0) {
      final result = amount / widget.crypto.currentPrice;
      _cryptoController.text = NumberFormat('#,##0.000000', 'pt_BR').format(result);
    } else {
      _cryptoController.text = '0.0';
    }
  }

  void _onCryptoChanged(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[R$]'), '').replaceAll('.', '').replaceAll(',', '.').trim();
    final amount = double.tryParse(cleanValue) ?? 0.0;
    final result = amount * widget.crypto.currentPrice;
    _realController.text = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(result);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));
    final formattedPriceFull = _formatPriceFull(widget.crypto.currentPrice);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.crypto.name,
          style: const TextStyle(
            color: Color(0xFF7AF0FF),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.redAccent : Colors.white,
            onPressed: _onToggleFavorite,
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Preço atual', style: TextStyle(fontSize: 18, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(formattedPriceFull, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            widget.crypto.priceChangePercentage24h >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            color: widget.crypto.priceChangePercentage24h >= 0 ? Colors.greenAccent : Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: widget.crypto.priceChangePercentage24h >= 0 ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Último dia', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 150,
                        child: _isChartLoading
                            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                            : _chartData.isEmpty
                                ? const Center(child: Text('Dados indisponíveis', style: TextStyle(color: Colors.white38)))
                                : LineChart(_buildChartData()),
                      ),
                      const SizedBox(height: 20),
                      _buildTimeFilterRow(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Calculadora de Conversão', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    _buildConversionTextField(
                      controller: _cryptoController,
                      focusNode: _cryptoFocusNode,
                      labelText: widget.crypto.symbol.toUpperCase(),
                      hintText: 'Quantidade de ${widget.crypto.symbol.toUpperCase()}',
                      onChanged: _onCryptoChanged,
                    ),
                    const Center(child: Icon(Icons.swap_vert, color: Colors.white54, size: 30)),
                    _buildConversionTextField(
                      controller: _realController,
                      focusNode: _realFocusNode,
                      labelText: 'BRL',
                      hintText: 'Valor em Reais (R\$)',
                      onChanged: _onRealChanged,
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.lightbulb_outline, color: Colors.yellowAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Você Sabia?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(widget.crypto.curiosity, style: const TextStyle(color: Colors.white70, height: 1.4)),
                      ]),
                    ),
                  ]),
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildConversionTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required String hintText,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 20),
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 18),
        filled: true,
        fillColor: Colors.black,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildTimeFilterRow() {
    final List<Map<String, dynamic>> filters = [
      {'text': '1D', 'days': 1},
      {'text': '7D', 'days': 7},
      {'text': '1M', 'days': 30},
      {'text': '1A', 'days': 365},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: filters.map((f) {
        final int days = f['days'] as int;
        final String label = f['text'] as String;
        final bool isSelected = _selectedDays == days;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (_selectedDays != days) {
                setState(() => _selectedDays = days);
                _fetchChartData();
              }
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: Colors.white24),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  LineChartData _buildChartData() {
    final priceChangeColor = widget.crypto.priceChangePercentage24h >= 0 ? Colors.greenAccent.shade400 : Colors.redAccent.shade400;
    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((bar) {
            return LineTooltipItem(
              _formatPriceFull(bar.y),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          }).toList(),
          getTooltipColor: (_) => Colors.black.withOpacity(0.8),
        ),
      ),
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _chartData,
          isCurved: true,
          color: priceChangeColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [priceChangeColor.withOpacity(0.3), priceChangeColor.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
