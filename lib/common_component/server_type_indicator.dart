import 'package:flutter/material.dart';

// Optimization: Extract server type indicator to separate widget
class ServerTypeIndicator extends StatelessWidget {
  final String text;

  const ServerTypeIndicator({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final isIP = RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?$').hasMatch(text);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: isIP
            ? Colors.green.withAlpha((0.12 * 255).toInt())
            : Colors.blue.withAlpha((0.12 * 255).toInt()),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isIP ? Colors.green : Colors.blue),
      ),
      child: Row(
        children: [
          Icon(
            isIP ? Icons.wifi : Icons.cloud_outlined,
            color: isIP ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isIP
                  ? 'Local server detected\nhttp://$text'
                  : 'Production server detected\nhttps://$text',
              style: TextStyle(
                color: isIP ? Colors.green[900] : Colors.blue[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
