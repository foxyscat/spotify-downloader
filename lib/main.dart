import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/music_page.dart';
import 'pages/favorites_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; // GNav için import eklemeyi unutmayın

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Navigation Example',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // Mevcut sekmeyi izlemek için değişken

  final List<Widget> _pages = [
    const HomePageWidget(), // Ana sayfa widget'ı
    MusicPageWidget(), // Müzik sayfası widget'ı
    const FavoritesPageWidget(), // Favoriler sayfası widget'ı
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Mevcut sayfayı göster
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF000000), // Arka plan rengi
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5), // Gölge rengi
              spreadRadius: 5, // Yayılma yarıçapı
              blurRadius: 10, // Bulanıklık yarıçapı
              offset: const Offset(0, -2), // Gölgenin konumu
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15),
          child: GNav(
            backgroundColor: const Color(0xFF000000),
            color: const Color(0xFF576574),
            activeColor: const Color(0xFF576574),
            tabBackgroundColor: const Color(0xFF0f0f0f),
            gap: 8,
            onTabChange: (index) {
              setState(() {
                _currentIndex = index; // Mevcut sekmeyi güncelle
              });
            },
            padding: const EdgeInsets.all(12),
            tabs: const [
              GButton(
                icon: Icons.home_outlined,
                text: "Home",
              ),
              GButton(
                icon: Icons.headphones,
                text: "Musics",
              ),
              GButton(
                icon: Icons.favorite_border,
                text: "Favorites",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
