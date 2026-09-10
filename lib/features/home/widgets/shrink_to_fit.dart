/// Text that scales down to fit its box instead of being cut off.
///
/// The brief asks for system text scaling to be supported (14). On a phone
/// with a large font that meant a card titled "Засиді…" and a subtitle ending
/// in an ellipsis mid-word, which is worse than the same words a little
/// smaller — so the words win and the size gives way.
library;

import 'package:flutter/material.dart';

class ShrinkToFit extends StatelessWidget {
  const ShrinkToFit({required this.child, this.alignment, super.key});

  final Widget child;

  /// Defaults to the top-left, which is what a left-aligned label wants; a
  /// centred title passes its own.
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment ?? Alignment.topLeft,
          // A definite width, so the text inside wraps the way it would
          // without the FittedBox and only then gets scaled.
          child: SizedBox(width: constraints.maxWidth, child: child),
        );
      },
    );
  }
}
