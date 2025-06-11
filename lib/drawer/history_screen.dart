import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nghe nhạc'),
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Xử lý xóa lịch sử
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 15, // Số lượng bài hát mẫu trong lịch sử
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primaryColor.withAlpha((0.2 * 255).round()),
              ),
              child: const Icon(
                Icons.music_note,
                color: AppColors.primaryColor,
              ),
            ),
            title: Text(
              'Bài hát ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Row(
              children: [
                const Text(
                  'Ca sĩ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                Text(
                  '${index + 1} giờ trước',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onPressed: () {
                // TODO: Hiển thị menu tùy chọn
              },
            ),
          );
        },
      ),
      backgroundColor: AppColors.primaryDark,
    );
  }
}
