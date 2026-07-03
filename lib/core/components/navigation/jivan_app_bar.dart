import 'package:flutter/material.dart';
import '../../utils/theme_utils.dart';

class JivanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const JivanAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: context.text.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false, // Professional apps usually left-align titles
      automaticallyImplyLeading: showBack,
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: 8), // Right padding
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
