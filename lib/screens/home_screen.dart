import 'package:flutter/material.dart';
import 'package:flutter_music_app/chatbox/chat_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import 'tabs/home_tab.dart';
import 'tabs/search_tab.dart';
import 'tabs/library_tab.dart';
import 'tabs/profile_tab.dart';
import '../drawer/favorite_songs_screen.dart';
import '../drawer/history_screen.dart';
import '../drawer/downloaded_songs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late List<Animation<double>> _tabIconAnimations;
  int? userId;
  final List<Widget> _screens = [
    const HomeTab(),
    const SearchTab(),
    const LibraryTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _tabIconAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.1 * index,
            0.1 * index + 0.6,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    fetchUser();
  }
   Future<int?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || JwtDecoder.isExpired(token)) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final userId = decodedToken['nameid'];

    return int.tryParse(userId.toString());
  }

   Future<void> fetchUser() async {

    userId = await getUserIdFromToken();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: AppColors.primaryDark,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 42, 16, 16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.music_note, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      'Music App',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title: const Text(
                  'Trang chủ',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _onTabTapped(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.white),
                title: const Text(
                  'Bài hát yêu thích',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoriteSongsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.white),
                title: const Text(
                  'Lịch sử',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.white),
                title: const Text(
                  'Bài hát đã tải',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DownloadedSongsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.white),
                title: const Text(
                  'Trợ lý AI (Chat)',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  ); // Đóng drawer hoặc bottom sheet nếu có
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              MusicChatScreen(userId: userId), // 👈 Mở chatbox
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _animationController.reset();
          _animationController.forward();
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0x20000000)],
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.primaryDark,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.textSecondary,
          items: List.generate(4, (index) {
            final iconData =
                [
                  Icons.home,
                  Icons.search,
                  Icons.library_music,
                  Icons.person,
                ][index];

            final label = ['Home', 'Search', 'Library', 'Profile'][index];

            return BottomNavigationBarItem(
              icon: ScaleTransition(
                scale: _tabIconAnimations[index],
                child: Icon(iconData),
              ),
              label: label,
            );
          }),
        ),
      ),
    );
  }
}
