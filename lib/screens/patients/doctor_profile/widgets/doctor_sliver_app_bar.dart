import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

/// A premium profile hero: a brand-tinted frosted backdrop of the doctor's
/// photo with a large, perfectly-centered circular avatar (halo + glow ring).
class DoctorSliverAppBar extends StatefulWidget {
  final String imageUrl;
  final bool isVerified;
  final String shareMessage;

  const DoctorSliverAppBar({
    super.key,
    required this.imageUrl,
    this.isVerified = false,
    this.shareMessage =
        "Check out this doctor on Jivan Health — book an appointment near you.",
  });

  @override
  State<DoctorSliverAppBar> createState() => _DoctorSliverAppBarState();
}

class _DoctorSliverAppBarState extends State<DoctorSliverAppBar> {
  bool _fav = false;

  bool get _hasValidImage =>
      widget.imageUrl.isNotEmpty && !widget.imageUrl.contains("ui-avatars");

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final hasImage = _hasValidImage;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 310,
      elevation: 0,
      backgroundColor: bg,
      surfaceTintColor: bg,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _GlassButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
      ),
      actions: [
        _GlassButton(
          icon: Icons.ios_share_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            Share.share(widget.shareMessage);
          },
        ),
        const SizedBox(width: 8),
        _GlassButton(
          icon: _fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: _fav ? Colors.red.shade300 : Colors.white,
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _fav = !_fav);
          },
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Backdrop — blurred photo, or brand gradient if none.
            if (hasImage)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _brandGradient(),
                ),
              )
            else
              _brandGradient(),

            // 2. Brand tint — turns the muddy blur into a cohesive green
            //    frosted header.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.55),
                    AppPalette.jivanBlue700.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),

            // 3. Vertical scrim — subtle top for buttons, fade to sheet color.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    bg,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // 4. Centered avatar with halo + glow
            Align(
              alignment: const Alignment(0, -0.18),
              child: _Avatar(
                imageUrl: hasImage ? widget.imageUrl : '',
                isVerified: widget.isVerified,
                ring: scheme.surface,
                accent: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandGradient() {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppPalette.primaryGradient),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final bool isVerified;
  final Color ring;
  final Color accent;

  const _Avatar({
    required this.imageUrl,
    required this.isVerified,
    required this.ring,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 180;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _halo(size + 62, 0.10),
        _halo(size + 30, 0.16),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (_, __) => Container(
                          color: ring,
                          child: Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _fallback(),
                      )
                    : _fallback(),
              ),
            ),
            if (isVerified)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: ring,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(Icons.verified, color: accent, size: 26),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _halo(double d, double alpha) {
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: ring,
      child: Icon(LucideIcons.stethoscope, size: 48, color: accent),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.black.withValues(alpha: 0.28),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
