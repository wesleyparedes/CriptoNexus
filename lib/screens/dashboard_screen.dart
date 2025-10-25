import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'crypto_detail_screen.dart';
import '../models/crypto.dart';
import '../services/app_update_checker.dart';

class AppColors {
  static const Color gradienteInicio = Color(0xFFC084FC);
  static const Color gradienteFim = Color(0xFF60A5FA);
  static const Color bgPrincipal = Color(0xFF07070C);
  static const Color roxo = Color(0xFF120336);
  static const Color roxoEscuro = Color(0xFF0D0326);
  static const Color azul = Color(0xFF60A5FA);
  static const Color lavender = Color(0xFFCECBCE);
  static const Color azulClaro = Color(0xFF7AF0FF);
  static const Color branco = Color(0xFFFFFFFF);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  List<Crypto> _cryptoList = [];
  List<Crypto> _favoriteCryptos = [];
  List<String> _favoriteCryptoIds = [];
  bool _isLoading = true;
  Timer? _timer;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  late AnimationController _dividerController;
  late Animation<double> _dividerFadeAnimation;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  static const purple = AppColors.roxo;
  static const appBackgroundColor = AppColors.bgPrincipal;
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _initializeFCM();
    _getTokenAndPrint();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    _dividerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _expandController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _expandAnimation = CurvedAnimation(parent: _expandController, curve: Curves.easeInOut);
    _dividerFadeAnimation = CurvedAnimation(parent: _dividerController, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _dividerController.forward();
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _fetchCryptoData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dividerController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  Future<void> _getTokenAndPrint() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint("========= TOKEN FCM =========");
      debugPrint(token);
      debugPrint("=============================");
    }
  }

  Future<void> _initializeFCM() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission(alert: true, badge: true, sound: true);
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings, onDidReceiveNotificationResponse: (response) async {
      _handleNotificationClick(response.payload);
    });
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif != null) {
        _showLocalNotification(notif.title ?? 'Alerta Cripto', notif.body ?? 'Mudança detectada em uma moeda favorita.', message.data);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationClick(jsonEncode(message.data));
    });
    fcm.getInitialMessage().then((message) {
      if (message != null) _handleNotificationClick(jsonEncode(message.data));
    });
  }

  void _showLocalNotification(String title, String body, Map<String, dynamic> payloadData) async {
    const androidDetails = AndroidNotificationDetails('price_alerts_channel', 'Alertas CriptoNexus', channelDescription: 'Notificações sobre moedas favoritas.', importance: Importance.max, priority: Priority.high);
    const details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(DateTime.now().millisecondsSinceEpoch % 100000, title, body, details, payload: jsonEncode(payloadData));
  }

  void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final cryptoId = data['cryptoId'];
      if (cryptoId != null && mounted) {
        final target = _cryptoList.firstWhere((c) => c.id == cryptoId, orElse: () => _cryptoList.first);
        Navigator.push(context, MaterialPageRoute(builder: (_) => CryptoDetailScreen(crypto: target, isFavorite: _favoriteCryptoIds.contains(target.id), onToggleFavorite: _toggleFavorite)));
      }
    } catch (e) {
      debugPrint('Erro ao abrir notificação: $e');
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favoriteCryptoIds = prefs.getStringList('favoriteCryptos') ?? [];
    });
    await _fetchCryptoData();
  }

  Future<void> _saveFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _favoriteCryptos.map((c) => c.id).toList();
    await prefs.setStringList('favoriteCryptos', ids);
  }

  Future<void> _fetchCryptoData() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cryptos_cache');
    final cachedTime = prefs.getInt('cryptos_cache_time');
    final now = DateTime.now().millisecondsSinceEpoch;
    final bool cacheValido = cachedData != null && cachedTime != null && (now - cachedTime) < 300000;
    if (cacheValido) {
      final data = jsonDecode(cachedData) as List<dynamic>;
      final fullList = data.map((e) => Crypto.fromJson(e as Map<String, dynamic>)).toList();
      _atualizarListas(fullList);
      return;
    }
    final uri = Uri.parse("https://api.coingecko.com/api/v3/coins/markets?vs_currency=brl&order=market_cap_desc&per_page=15&page=1&sparkline=false");
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as List<dynamic>;
        final fullList = data.map((e) => Crypto.fromJson(e as Map<String, dynamic>)).toList();
        await prefs.setString('cryptos_cache', res.body);
        await prefs.setInt('cryptos_cache_time', now);
        _atualizarListas(fullList);
      } else {
        if (cachedData != null) {
          final data = jsonDecode(cachedData) as List<dynamic>;
          final fullList = data.map((e) => Crypto.fromJson(e as Map<String, dynamic>)).toList();
          _atualizarListas(fullList);
        }
      }
    } catch (e) {
      if (cachedData != null) {
        final data = jsonDecode(cachedData) as List<dynamic>;
        final fullList = data.map((e) => Crypto.fromJson(e as Map<String, dynamic>)).toList();
        _atualizarListas(fullList);
      }
    }
  }

  void _atualizarListas(List<Crypto> fullList) {
    final favs = <Crypto>[];
    for (final id in _favoriteCryptoIds) {
      final match = fullList.where((c) => c.id == id);
      if (match.isNotEmpty) favs.add(match.first);
    }
    setState(() {
      _cryptoList = fullList;
      _favoriteCryptos = favs;
      _isLoading = false;
    });
  }

  void _toggleFavorite(Crypto crypto, bool isFav) {
    setState(() {
      if (isFav) {
        if (!_favoriteCryptoIds.contains(crypto.id)) {
          _favoriteCryptoIds.add(crypto.id);
          _favoriteCryptos.add(crypto);
        }
      } else {
        _favoriteCryptoIds.remove(crypto.id);
        _favoriteCryptos.removeWhere((c) => c.id == crypto.id);
      }
    });
    _saveFavoriteIds();
  }

  Future<void> _abrirCalculadoraPopup() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CalculadoraBottomSheet(moedas: _cryptoList),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCalculadoraPopup,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 6,
        child: const Icon(Icons.swap_calls, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: BottomAppBar(
            color: const Color(0xFF07070C).withOpacity(0.9),
            surfaceTintColor: Colors.transparent,
            height: 65 + MediaQuery.of(context).padding.bottom,
            elevation: 0,
            shape: const CircularNotchedRectangle(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 80,
                  child: _navItem(
                    icon: Icons.home,
                    label: 'Início',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 40),
                SizedBox(
                  width: 80,
                  child: _navItem(
                    icon: Icons.account_circle,
                    label: 'Perfil',
                    onTap: () => Navigator.pushNamed(context, '/perfil'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: appBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 12 + MediaQuery.of(context).padding.top),
                child: const Center(
                  child: Text('CriptoNexus', style: TextStyle(fontSize: 17, color: AppColors.azulClaro, fontWeight: FontWeight.w700)),
                ),
              ),
              FadeTransition(opacity: _dividerFadeAnimation, child: const Divider(color: Colors.white24, thickness: 0.5, height: 20)),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showFavorites = !_showFavorites;
                    if (_showFavorites) {
                      _expandController.forward();
                    } else {
                      _expandController.reverse();
                    }
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Suas favoritas', style: TextStyle(color: AppColors.branco, fontSize: 16, fontWeight: FontWeight.w600)),
                    Icon(_showFavorites ? Icons.favorite : Icons.favorite_border, color: _showFavorites ? Colors.redAccent : AppColors.lavender, size: 26),
                  ],
                ),
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.azul))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _favoriteCryptos
                                    .map((c) => GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CryptoDetailScreen(crypto: c, isFavorite: true, onToggleFavorite: _toggleFavorite),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            width: 160,
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(color: AppColors.roxoEscuro.withOpacity(0.4), borderRadius: BorderRadius.circular(14)),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.network(c.image, height: 32, width: 32),
                                                const SizedBox(height: 8),
                                                Text(c.symbol.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.branco)),
                                                const SizedBox(height: 4),
                                                Text(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(c.currentPrice), style: const TextStyle(color: AppColors.lavender)),
                                                const SizedBox(height: 2),
                                                Text('${c.priceChangePercentage24h.toStringAsFixed(2)}%', style: TextStyle(color: c.priceChangePercentage24h >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              FadeTransition(opacity: _dividerFadeAnimation, child: const Divider(color: Colors.white24, thickness: 0.5, height: 20)),
              const Text('Moedas', style: TextStyle(color: AppColors.branco, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchCryptoData,
                  backgroundColor: AppColors.azul,
                  color: AppColors.branco,
                  child: _cryptoList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 60),
                            Center(child: Text('Ops! Algo deu errado. Tente novamente.', style: TextStyle(color: AppColors.branco))),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _cryptoList.length,
                          itemBuilder: (context, index) => _cryptoListItem(_cryptoList[index]),
                          padding: EdgeInsets.only(bottom: 75 + MediaQuery.of(context).padding.bottom),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cryptoListItem(Crypto crypto) {
    final priceColor = crypto.priceChangePercentage24h >= 0 ? Colors.greenAccent : Colors.redAccent;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(14)),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CryptoDetailScreen(crypto: crypto, isFavorite: _favoriteCryptoIds.contains(crypto.id), onToggleFavorite: _toggleFavorite)));
        },
        child: Row(
          children: [
            Image.network(crypto.image, height: 36, width: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(crypto.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.branco)),
                  const SizedBox(height: 4),
                  Text(crypto.symbol.toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.lavender)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatter.format(crypto.currentPrice), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.branco)),
                const SizedBox(height: 4),
                Text('${crypto.priceChangePercentage24h.toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, color: priceColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.branco, size: 28),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.branco, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CalculadoraBottomSheet extends StatefulWidget {
  final List<Crypto> moedas;
  const _CalculadoraBottomSheet({required this.moedas});

  @override
  State<_CalculadoraBottomSheet> createState() => _CalculadoraBottomSheetState();
}

class _CalculadoraBottomSheetState extends State<_CalculadoraBottomSheet> {
  final TextEditingController _realCtrl = TextEditingController();
  final TextEditingController _cryptoCtrl = TextEditingController();
  late List<Crypto> _moedas;
  Crypto? _selecionada;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _moedas = widget.moedas;
    if (_moedas.isNotEmpty) {
      _selecionada = _moedas.first;
      _carregando = false;
    } else {
      _carregando = true;
    }
  }

  void _onRealChanged(String value) {
    if (_selecionada == null) return;
    final clean = value.replaceAll(RegExp(r'[R$]'), '').replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(clean) ?? 0;
    final result = amount / _selecionada!.currentPrice;
    _cryptoCtrl.text = NumberFormat('#,##0.000000', 'pt_BR').format(result);
  }

  void _onCryptoChanged(String value) {
    if (_selecionada == null) return;
    final clean = value.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(clean) ?? 0;
    final result = amount * _selecionada!.currentPrice;
    _realCtrl.text = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(result);
  }

  void _abrirSelecao() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF07070C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Escolher moeda", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _moedas.length,
                  itemBuilder: (_, i) {
                    final c = _moedas[i];
                    return Container(
                      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Image.network(c.image, height: 30, width: 30),
                        title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        subtitle: Text(c.symbol.toUpperCase(), style: const TextStyle(color: Colors.white70)),
                        onTap: () {
                          setState(() => _selecionada = c);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: EdgeInsets.only(bottom: viewInsets),
        decoration: const BoxDecoration(
          color: Color(0xFF07070C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _carregando
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _abrirSelecao,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            if (_selecionada != null)
                              Image.network(_selecionada!.image, height: 26, width: 26)
                            else
                              const Icon(Icons.search, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              _selecionada != null ? "${_selecionada!.symbol.toUpperCase()} - ${_selecionada!.name}" : "Escolher moeda...",
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_selecionada != null)
                      Column(
                        children: [
                          TextField(
                            controller: _cryptoCtrl,
                            onChanged: _onCryptoChanged,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: _selecionada!.symbol.toUpperCase(),
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Icon(Icons.swap_vert, color: Colors.white70),
                          TextField(
                            controller: _realCtrl,
                            onChanged: _onRealChanged,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'BRL',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
        ),
      ),
    );
  }
}
