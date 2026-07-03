import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/api_service.dart';

class AdminPaymentQRScreen extends StatefulWidget {
  final String appointmentId;
  final double amount; // UI ରେ ଟଙ୍କା ଦେଖାଇବା ପାଇଁ

  const AdminPaymentQRScreen({
    Key? key,
    required this.appointmentId,
    required this.amount,
  }) : super(key: key);

  @override
  State<AdminPaymentQRScreen> createState() => _AdminPaymentQRScreenState();
}

class _AdminPaymentQRScreenState extends State<AdminPaymentQRScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isPaid = false;
  String? _qrUrl;
  String? _errorMessage;

  Timer? _pollingTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // 🚀 ପଲ୍ସ (Pulse) ଆନିମେସନ୍ Waiting ସମୟ ପାଇଁ
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _generatePaymentQR();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // 🛑 ସ୍କ୍ରିନ୍ ବନ୍ଦ ହେଲେ ଟାଇମର୍ ବନ୍ଦ କରିବା ଅତି ଜରୁରୀ (Memory Leak ରୋକିବା ପାଇଁ)
    _pulseController.dispose();
    super.dispose();
  }

  // =========================================================
  // 🚀 ୧. API କଲ୍: QR ଲିଙ୍କ୍ ତିଆରି କରିବା
  // =========================================================
  Future<void> _generatePaymentQR() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // 🚀 FIX: ସିଧାସଳଖ dio.get() ବଦଳରେ api_service ର ମେଥଡ୍ କଲ୍ କରନ୍ତୁ
      final response = await _apiService.generateAdminPaymentQR(
        tokenKey: 'admin_token', 
        appointmentId: widget.appointmentId,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _qrUrl = response.data['data']['qr_data_url'];
          _isLoading = false;
        });
        // QR ମିଳିବା ମାତ୍ରେ ଅଟୋ-ଚେକିଂ ଆରମ୍ଭ କରନ୍ତୁ
        _startPollingPaymentStatus();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.data['message'] ?? "Failed to generate QR Code.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Network error. Please check connection and try again.";
      });
    }
  }

  // =========================================================
  // 🚀 ୨. ଅଟୋମେଟିକ୍ ପେମେଣ୍ଟ୍ ଚେକିଂ (Polling System)
  // =========================================================
  void _startPollingPaymentStatus() {
    // ପ୍ରତି ୩ ସେକେଣ୍ଡ୍ ରେ ବ୍ୟାକଏଣ୍ଡ୍ କୁ ପଚାରିବ ଯେ ଟଙ୍କା ଆସିଲା କି ନାହିଁ
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isPaid) {
        timer.cancel();
        return;
      }
      await _verifyPaymentStatus();
    });
  }

  // =========================================================
  // 🚀 ୨. ଅଟୋମେଟିକ୍ ପେମେଣ୍ଟ୍ ଚେକିଂ (Polling System)
  // =========================================================
  Future<void> _verifyPaymentStatus() async {
    try {
      // 🚀 FIX: ସିଧାସଳଖ dio.get() ବଦଳରେ api_service ର ମେଥଡ୍ କଲ୍ କରନ୍ତୁ
      final response = await _apiService.verifyAdminPaymentQR(
        tokenKey: 'admin_token',
        appointmentId: widget.appointmentId,
      );
      
      if (response.statusCode == 200 && response.data['data']['is_paid'] == true) {
        // 🚀 PAYMENT SUCCESSFUL!
        _pollingTimer?.cancel();
        HapticFeedback.heavyImpact(); // ଫୋନ୍ ଭାଇବ୍ରେଟ୍ ହେବ
        
        setState(() {
          _isPaid = true;
        });
      }
    } catch (e) {
      debugPrint("Polling error: $e"); // ସାଇଲେଣ୍ଟ୍ ଏରର୍, ୟୁଜର୍ କୁ ଡିଷ୍ଟର୍ବ କରିବନି
    }
  }

  // =========================================================
  // 🚀 UI BUILDER
  // =========================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Payment QR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Center(
        child: _buildBodyContent(theme, colorScheme),
      ),
    );
  }

  Widget _buildBodyContent(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 24),
          const Text("Generating Secure Payment Link...", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Connecting to Razorpay gateway", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertTriangle, size: 60, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text("Error", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generatePaymentQR,
              icon: const Icon(LucideIcons.refreshCcw),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
            )
          ],
        ),
      );
    }

    if (_isPaid) {
      return _buildSuccessState(theme);
    }

    return _buildQRState(theme, colorScheme);
  }

  // 🚀 ସଫଳତା ସ୍କ୍ରିନ୍ (Payment Success)
  Widget _buildSuccessState(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                child: Icon(LucideIcons.checkCircle, size: 80, color: Colors.green.shade600),
              ),
              const SizedBox(height: 32),
              const Text("Payment Successful!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
              const SizedBox(height: 8),
              Text("₹${widget.amount} has been received.", style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context), // ଫେରିଯିବା ପାଇଁ
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  child: const Text("Back to Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // 🚀 QR ଦେଖାଇବା ସ୍କ୍ରିନ୍ (Waiting for scan)
  Widget _buildQRState(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ଟଙ୍କା ଦେଖାନ୍ତୁ
          Text("Amount to Collect", style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("₹${widget.amount}", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: colorScheme.primary)),
          const SizedBox(height: 32),

          // 🚀 QR CODE CARD (Premium Look)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, // QR ସବୁବେଳେ ଧଳା ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ରେ ଭଲ ସ୍କାନ ହୁଏ
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: _qrUrl!, // Razorpay Short URL
                  version: QrVersions.auto,
                  size: 250.0,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.scan, color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    const Text("Scan with Any UPI App", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ପଲ୍ସିଂ (Pulsing) ୱେଟିଂ ଇଣ୍ଡିକେଟର୍
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange.shade700)),
                  const SizedBox(width: 12),
                  Text("Waiting for payment...", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ଅପସନାଲ୍: ଲିଙ୍କ୍ କପି ବଟନ୍
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _qrUrl!));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Link copied to clipboard!")));
            },
            icon: const Icon(LucideIcons.copy),
            label: const Text("Copy Payment Link"),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          )
        ],
      ),
    );
  }
}