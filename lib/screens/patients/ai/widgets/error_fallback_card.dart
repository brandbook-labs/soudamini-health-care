import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// ✅ NEW: Enum to define exact error states
enum AiErrorType { network, timeout, server, unknown }

class ErrorFallbackCard extends StatelessWidget {
  final AiErrorType errorType;
  final String cachedPayload;
  final Function(String) onRetry;
  final String? customMessage; // Optional override for backend error strings

  const ErrorFallbackCard({
    super.key,
    required this.cachedPayload,
    required this.onRetry,
    this.errorType = AiErrorType.unknown,
    this.customMessage,
  });

  // Dynamic UI Data based on Error Type
  IconData _getIcon() {
    switch (errorType) {
      case AiErrorType.network:
        return LucideIcons.wifiOff;
      case AiErrorType.timeout:
        return LucideIcons.timer;
      case AiErrorType.server:
        return LucideIcons.serverCrash;
      case AiErrorType.unknown:
      default:
        return LucideIcons.alertTriangle;
    }
  }

  String _getTitle() {
    switch (errorType) {
      case AiErrorType.network:
        return "Connection Lost";
      case AiErrorType.timeout:
        return "Request Timed Out";
      case AiErrorType.server:
        return "System Hiccup";
      case AiErrorType.unknown:
      default:
        return "Something went wrong";
    }
  }

  String _getDescription() {
    if (customMessage != null && customMessage!.isNotEmpty) {
      return customMessage!;
    }
    switch (errorType) {
      case AiErrorType.network:
        return "Please check your internet connection and try sending your symptoms again.";
      case AiErrorType.timeout:
        return "The medical database took too long to respond. This usually happens on slow networks.";
      case AiErrorType.server:
        return "Our medical servers are currently experiencing high traffic. Please try again in a moment.";
      case AiErrorType.unknown:
      default:
        return "We encountered an unexpected error while processing your request.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Defines the red/amber color palette for errors
    final bgCol = isDark ? const Color(0xFF3B1219) : const Color(0xFFFEF2F2);
    final borderCol = isDark
        ? const Color(0xFF7F1D1D)
        : const Color(0xFFFECACA);
    final textMainCol = isDark
        ? const Color(0xFFFCA5A5)
        : const Color(0xFF991B1B);
    final textSubCol = isDark
        ? const Color(0xFFFECACA)
        : const Color(0xFFB91C1C);
    final iconBgCol = isDark
        ? const Color(0xFF7F1D1D).withValues(alpha: 0.5)
        : const Color(0xFFFEE2E2);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 8,
        right: 32,
      ), // Leaves room on the right so it looks like a chat bubble
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Icon in a subtle circular background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBgCol, shape: BoxShape.circle),
            child: Icon(_getIcon(), color: textMainCol, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamic Title
                Text(
                  _getTitle(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textMainCol,
                  ),
                ),
                const SizedBox(height: 6),
                // Dynamic Description
                Text(
                  _getDescription(),
                  style: TextStyle(
                    fontSize: 14,
                    color: textSubCol,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Redesigned Actionable Retry Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onRetry(cachedPayload);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: borderCol),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Hugs the text
                      children: [
                        Icon(
                          LucideIcons.refreshCw, // Much better icon for retry
                          size: 14,
                          color: textMainCol,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Retry",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textMainCol,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
