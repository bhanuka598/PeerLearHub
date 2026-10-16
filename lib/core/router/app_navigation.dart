import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Returns to the previous page when one exists. Otherwise opens [fallback],
/// which covers screens reached with `go()` or opened directly by URL.
void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(fallback);
}
