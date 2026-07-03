import 'package:flutter/material.dart';
import '../../utils/theme_utils.dart';

class JivanAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name; // Used for initials
  final double size;

  const JivanAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colorScheme.primaryContainer,
      ),
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitials(context),
            )
          : _buildInitials(context),
    );
  }

  Widget _buildInitials(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : "?";
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: context.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
