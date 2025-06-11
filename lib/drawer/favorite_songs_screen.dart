import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FavoriteSongsScreen extends StatelessWidget {
  const FavoriteSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài hát yêu thích'),
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: 10, // Số lượng bài hát mẫu
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
              'Bài hát yêu thích ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              'Ca sĩ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () {
                // TODO: Xử lý khi bỏ yêu thích
              },
            ),
          );
        },
      ),
      backgroundColor: AppColors.primaryDark,
    );
  }
}
