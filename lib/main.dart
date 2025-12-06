import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

// =========================================================
//                   KONFIGURASI DATA
// =========================================================

class CoinParticle {
  final double x;
  final double delay;
  CoinParticle({required this.x, required this.delay});
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SlotGameApp());
}

// =========================================================
//                   TEMA & GAYA APLIKASI
// =========================================================

class SlotGameApp extends StatelessWidget {
  const SlotGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Royale Slot Web',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark Navy Web Style
        primaryColor: const Color(0xFF6366F1), // Indigo
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF06B6D4), // Cyan
          surface: Color(0xFF1E293B), // Slate 800
        ),
        useMaterial3: true,
        fontFamily: 'Sans-Serif', // Menggunakan font bawaan sistem yang bersih
      ),
      home: const SlotMachinePage(),
    );
  }
}

// Helper Currency
final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
String _formatCurrency(int amount) {
  if (amount < 0) return "- ${_currencyFormat.format(amount.abs())}";
  return _currencyFormat.format(amount);
}

// =========================================================
//                  HALAMAN UTAMA (GAME)
// =========================================================

class SlotMachinePage extends StatefulWidget {
  const SlotMachinePage({super.key});

  @override
  State<SlotMachinePage> createState() => _SlotMachinePageState();
}

class _SlotMachinePageState extends State<SlotMachinePage> with SingleTickerProviderStateMixin {
  final FixedExtentScrollController _controller1 = FixedExtentScrollController();
  final FixedExtentScrollController _controller2 = FixedExtentScrollController();
  final FixedExtentScrollController _controller3 = FixedExtentScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  final List<CoinParticle> _coinParticles = [];
  final Random _random = Random();
  final int _numParticles = 20; // Lebih banyak partikel
  
  final List<String> symbols = ['🍒', '💎', '7️⃣', '🔔', '🍋', '🍇', '💣'];
  
  int _saldo = 50000; 
  final int _spinCost = 15000; 
  
  int _gameCounter = 0;
  final int _winRounds = 3;
  final int _lossRounds = 6;

  String status = "Siap Bermain? Tekan Putar!";
  bool isSpinning = false;

  // Logika RNG
  int _randomJackpotWin() => (_random.nextInt(401) + 100) * 1000; 
  int _randomMaxLoss() => (_random.nextInt(101) + 100) * 1000; 

  // --- NAVIGASI KE TOP UP ---
  void _goToTopUpPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TopUpPage()),
    );

    if (result != null && result is int) {
      setState(() {
        _saldo += result;
        status = "Saldo masuk: ${_formatCurrency(result)}";
      });
      // Tampilkan notifikasi web-style
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Top Up Berhasil! Saldo sekarang: ${_formatCurrency(_saldo)}"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.decelerate));
    for (int i = 0; i < _numParticles; i++) {
      _coinParticles.add(CoinParticle(x: _random.nextDouble() * 1.0, delay: _random.nextDouble() * 0.5));
    }
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _animationController.dispose(); 
    super.dispose();
  }

  // --- LOGIKA SPIN ---
  void spin() async {
    if (isSpinning) return; 
    if (_saldo < _spinCost) {
      setState(() => status = "Saldo Tidak Cukup!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saldo Habis! Silakan isi saldo."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _saldo -= _spinCost; 
      isSpinning = true;
      _gameCounter++; 
    });

    int result1, result2, result3;

    // Logika Rigging (Kontrol)
    if (_gameCounter <= _winRounds) {
      result1 = result2 = result3 = 0; 
    } else if (_gameCounter <= (_winRounds + _lossRounds)) {
      result1 = result2 = result3 = symbols.indexOf('💣'); 
    } else {
      result1 = _random.nextInt(symbols.length);
      result2 = _random.nextInt(symbols.length);
      result3 = _random.nextInt(symbols.length);
    }

    // Animasi Gulir
    const int spinRounds1 = 5, spinRounds2 = 8, spinRounds3 = 12;
    int currentItem1 = _controller1.selectedItem;
    int currentItem2 = _controller2.selectedItem;
    int currentItem3 = _controller3.selectedItem;
    
    // Hitung target
    int target1 = currentItem1 + (symbols.length * spinRounds1) + (result1 - (currentItem1 % symbols.length) + symbols.length) % symbols.length;
    int target2 = currentItem2 + (symbols.length * spinRounds2) + (result2 - (currentItem2 % symbols.length) + symbols.length) % symbols.length;
    int target3 = currentItem3 + (symbols.length * spinRounds3) + (result3 - (currentItem3 % symbols.length) + symbols.length) % symbols.length;

    _controller1.animateToItem(target1, duration: const Duration(milliseconds: 1000), curve: Curves.easeInOutQuad);
    await Future.delayed(const Duration(milliseconds: 200));
    _controller2.animateToItem(target2, duration: const Duration(milliseconds: 2000), curve: Curves.easeInOutQuad);
    await Future.delayed(const Duration(milliseconds: 200));
    await _controller3.animateToItem(target3, duration: const Duration(milliseconds: 2500), curve: Curves.elasticOut);

    _checkResult(symbols[result1], symbols[result2], symbols[result3]);
  }

  void _checkResult(String s1, String s2, String s3) {
    List<String> results = [s1, s2, s3];
    int bombCount = results.where((s) => s == '💣').length;

    setState(() {
      isSpinning = false;
      int amountChange = 0;
      bool isJackpot = false;
      
      if (bombCount > 0) {
        if (bombCount == 1) amountChange = -5000;
        else if (bombCount == 2) amountChange = -10000;
        else if (bombCount == 3) amountChange = -_randomMaxLoss();
        status = "TERKENA BOM! ${_formatCurrency(amountChange)}";
      } else if (s1 == s2 && s2 == s3) {
        amountChange = _randomJackpotWin(); 
        status = "JACKPOT! ${_formatCurrency(amountChange)}";
        isJackpot = true;
      } else if (s1 == s2 || s2 == s3 || s1 == s3) {
        amountChange = 2000; 
        status = "Nice! 2 Cocok (+Rp2.000)";
      } else {
        amountChange = 1000;
        status = "Lumayan! 1 Cocok (+Rp1.000)";
      }
      
      _saldo += amountChange;
      
      if (isJackpot || (amountChange > 50000 && amountChange > 0)) { 
          _animationController.forward(from: 0.0);
      } else {
          _animationController.reset();
      }
    });
  }

  void _resetGame() {
    setState(() {
      _saldo = 50000;
      _gameCounter = 0;
      status = "Sistem Di-reset.";
      _controller1.animateToItem(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      _controller2.animateToItem(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      _controller3.animateToItem(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    });
  }

  // ==========================
  //      WIDGETS UTAMA
  // ==========================

  @override
  Widget build(BuildContext context) {
    // Menggunakan ConstrainedBox agar tampilan di Web/Desktop tidak melebar
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient halus
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500), // Max Width seperti HP
              child: Column(
                children: [
                  // --- HEADER (Navbar Style) ---
                  _buildHeader(),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // --- STATUS BAR ---
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // --- MESIN SLOT (THE CABINET) ---
                          _buildSlotMachineCabinet(),

                          const SizedBox(height: 40),

                          // --- CONTROLS ---
                          _buildControls(),
                        ],
                      ),
                    ),
                  ),

                  // --- FOOTER ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "© 2024 Royale Slot Simulation • Edukasi",
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Layer Animasi Koin (Paling Atas)
          _buildCoinAnimation(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.casino_rounded, color: Colors.cyanAccent),
                SizedBox(width: 8),
                Text(
                  "ROYALE SLOT",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white,
                    letterSpacing: 1.5
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wallet, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _formatCurrency(_saldo),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSlotMachineCabinet() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Frame Mesin
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF334155), width: 8),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 0,
              ),
              const BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRoller(_controller1),
              Container(width: 2, color: Colors.white10),
              _buildRoller(_controller2),
              Container(width: 2, color: Colors.white10),
              _buildRoller(_controller3),
            ],
          ),
        ),

        // Payline (Garis Merah Tengah)
        Container(
          height: 4,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.5),
            boxShadow: const [BoxShadow(color: Colors.red, blurRadius: 5)]
          ),
        ),

        // Gradient Overlay (Efek 3D Kaca)
        IgnorePointer(
          child: Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0]
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoller(FixedExtentScrollController controller) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 80, 
        physics: const FixedExtentScrollPhysics(),
        perspective: 0.003,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: null, 
          builder: (context, index) {
            String symbol = symbols[index % symbols.length];
            return Container(
              alignment: Alignment.center,
              child: Text(
                symbol,
                style: const TextStyle(fontSize: 48, shadows: [
                  Shadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2))
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Tombol Putar Besar
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: isSpinning ? null : spin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1), // Indigo Primary
              foregroundColor: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
            ),
            child: isSpinning
                ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text("PUTAR SEKARANG (${_formatCurrency(_spinCost)})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
        
        const SizedBox(height: 15),

        // Baris Tombol Sekunder
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSpinning ? null : _goToTopUpPage,
                icon: const Icon(Icons.qr_code_2),
                label: const Text("Isi Saldo"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetGame,
                icon: const Icon(Icons.refresh),
                label: const Text("Reset"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoinAnimation(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (_animation.value == 0) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            double maxHeight = constraints.maxHeight; 
            return Stack(
              children: _coinParticles.map((particle) {
                double delayedValue = (_animation.value - particle.delay).clamp(0.0, 1.0) / (1.0 - particle.delay).clamp(0.0, 1.0);
                double topPosition = delayedValue * maxHeight;
                double opacity = 1.0 - (delayedValue > 0.8 ? (delayedValue - 0.8) * 5 : 0);

                return Positioned(
                  left: particle.x * constraints.maxWidth, 
                  top: topPosition,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: _animation.value * 6.28,
                      child: const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 32),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

// =========================================================
//                  HALAMAN TOP-UP (WEB STYLE FORM)
// =========================================================

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final TextEditingController _amountController = TextEditingController();
  String? _errorMessage;
  int _selectedAmount = 0;

  void _setNominal() {
    final String text = _amountController.text;
    final int? amount = int.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = "Masukkan angka valid.");
      return;
    }
    if (amount < 10000 || amount % 1000 != 0) {
       setState(() => _errorMessage = "Min. Rp10.000 (Kelipatan 1000).");
      return;
    }
    setState(() {
      _selectedAmount = amount;
      _errorMessage = null; 
    });
  }

  void _confirmPayment() => Navigator.pop(context, _selectedAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(_selectedAmount > 0 ? "Kasir Pembayaran" : "Isi Saldo", style: const TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: const Color(0xFF1E293B),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedAmount == 0) ...[
                      // --- FORM INPUT ---
                      const Icon(Icons.account_balance_wallet, size: 64, color: Colors.cyanAccent),
                      const SizedBox(height: 24),
                      const Text("Top Up Saldo", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text("Masukkan nominal yang ingin ditambahkan.", style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixText: "Rp ",
                          labelText: "Nominal",
                          errorText: _errorMessage,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _setNominal,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text("LANJUTKAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      // --- QR DISPLAY ---
                      const Text("Scan QR Code", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text("Total: ${_formatCurrency(_selectedAmount)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.cyanAccent)),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.qr_code_2, size: 200, color: Colors.black),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _confirmPayment,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text("SAYA SUDAH BAYAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => _selectedAmount = 0),
                        child: const Text("Ubah Nominal", style: TextStyle(color: Colors.white54)),
                      )
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}