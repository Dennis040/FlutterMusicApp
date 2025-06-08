import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.background,
          title: const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage('https://picsum.photos/32/32'),
              ),
              SizedBox(width: 16),
              Text(
                'Your Library',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(icon: const Icon(Icons.add), onPressed: () {}),
          ],
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Playlists'),
                  selected: _selectedFilter == 0,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = 0;
                      });
                    }
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: Colors.white,
                  labelStyle: TextStyle(
                    color:
                        _selectedFilter == 0
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Artists'),
                  selected: _selectedFilter == 1,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = 1;
                      });
                    }
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: Colors.white,
                  labelStyle: TextStyle(
                    color:
                        _selectedFilter == 1
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Albums'),
                  selected: _selectedFilter == 2,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = 2;
                      });
                    }
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: Colors.white,
                  labelStyle: TextStyle(
                    color:
                        _selectedFilter == 2
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://picsum.photos/56/56?random=$index',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                'Playlist ${index + 1}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Playlist • User Name',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }, childCount: 20),
        ),
      ],
    );
  }
}
