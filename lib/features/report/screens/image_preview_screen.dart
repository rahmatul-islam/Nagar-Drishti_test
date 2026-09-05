import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;

  const ImagePreviewScreen({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob:');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ছবি প্রিভিউ',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: isNetwork
                  ? Image.network(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        size: 80,
                        color: Colors.white54,
                      ),
                    )
                  : Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('পুনরায় ছবি তুলুন'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('ছবি নিশ্চিত করুন'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
