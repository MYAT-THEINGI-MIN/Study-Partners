// refresh_indicator_widget.dart
import 'package:flutter/material.dart';
import 'package:sp_test/Service/refreshService.dart';

class RefreshIndicatorWidget extends StatelessWidget {
  final Widget child;
  final RefreshController controller;
  final Future<void> Function() onRefresh;

  const RefreshIndicatorWidget({
    Key? key,
    required this.child,
    required this.controller,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollStartNotification &&
              notification.metrics.extentBefore == 0) {
            controller.refresh();
          }
          return false;
        },
        child: child,
      ),
    );
  }
}
