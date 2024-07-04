// refresh_controller.dart
import 'package:flutter/material.dart';

class RefreshController {
  VoidCallback? onRefresh;

  void refresh() {
    if (onRefresh != null) {
      onRefresh!();
    }
  }
}
