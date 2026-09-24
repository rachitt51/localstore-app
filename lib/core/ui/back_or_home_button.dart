import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App-bar leading for pushed screens. Pops when there is history; after a
/// login redirect (a `go`) there may be none, so it falls back to [fallback].
class BackOrHomeButton extends StatelessWidget {
  const BackOrHomeButton({super.key, this.fallback = '/'});

  final String fallback;

  @override
  Widget build(BuildContext context) {
    return BackButton(
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallback);
        }
      },
    );
  }
}
