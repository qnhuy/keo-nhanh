import 'package:flutter/material.dart';

/// Widget hiển thị trạng thái đang tải dữ liệu
class LoadingView extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingView({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? const Color(0xFF16A34A),
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
