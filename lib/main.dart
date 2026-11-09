import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MiKullMusicApp());
}

const Color bgColor = Color(0xFF121212);
const Color panelColor = Color(0xFF1E1E1E);
const Color accentColor = Color(0xFFFF8A35);

class MiKullMusicApp extends StatelessWidget {
  const MiKullMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MiKullMusic',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final Duration duration;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    this.duration = const Duration(minutes: 3, seconds: 24),
  });
}

class MusicGenre {
  final String name;
  final List<Color> colors;
  const MusicGenre(this.name, this.colors);
}

const List<MusicGenre> genres = [
  MusicGenre('Электроника', [Color(0xFF4F1428), Color(0xFF1A0510)]),
  MusicGenre('Русский рэп', [Color(0xFF2D3238), Color(0xFF15181C)]),
  MusicGenre('Танцевальная', [Color(0xFF5C134F), Color(0xFF1D0317)]),
  MusicGenre('R&B и соул', [Color(0xFF4A2E12), Color(0xFF1A0F04)]),
  MusicGenre('Русская', [Color(0xFF1A365D), Color(0xFF0A1424)]),
  MusicGenre('Рок', [Color(0xFF421D1D), Color(0xFF1A0A0A)]),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0;
  MusicTrack? _currentTrack;
  List<MusicTrack> _activePlaylist = [];
  bool _isPlaying = false;
  
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final TextEditingController _searchController = TextEditingController();
  String? _selectedGenre;
  String _searchQuery = '';
  
  bool _isLoading = false;
  List<MusicTrack> _networkTracks = [];

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });

    _audioPlayer.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _selectTrack(MusicTrack track, {List<MusicTrack>? playlist}) async {
    try {
      setState(() {
        if (playlist != null) _activePlaylist = playlist;
        _currentTrack = track;
        _position = Duration.zero;
        _duration = track.duration;
      });

      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(track.audioUrl));
    } catch (e) {
      print("Ошибка воспроизведения: \$e");
    }
  }

  Future<void> _playPause() async {
    if (_currentTrack == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  void _skipTrack(int direction) {
    if (_activePlaylist.isEmpty || _currentTrack == null) return;
    final currentIndex = _activePlaylist.indexWhere((t) => t.id == _currentTrack!.id);
    final start = currentIndex < 0 ? 0 : currentIndex;
    final nextIndex = (start + direction + _activePlaylist.length) % _activePlaylist.length;
    _selectTrack(_activePlaylist[nextIndex]);
  }

  Future<void> _fetchTracksFromApi(String query) async {
    if (query.isEmpty) {
      setState(() {
        _networkTracks = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final url = Uri.parse('http://127.0.0.1:8000/api/v1/search?q=\${Uri.encodeComponent(query)}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        
        setState(() {
          _networkTracks = jsonList.map((item) {
            return MusicTrack(
              id: item['id'].toString(),
              title: item['title'] ?? 'Без названия',
              artist: item['artist'] ?? 'Неизвестный исполнитель',
              coverUrl: item['cover_url'] ?? 'https://picsum.photos/seed/mikull/300',
              audioUrl: item['audio_url'] ?? '',
              duration: Duration(seconds: item['duration'] ?? 180),
            );
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Ошибка сети: \$e");
      setState(() => _isLoading = false);
    }
  }

  void _search(String value) {
    setState(() {
      _searchQuery = value.trim();
      _selectedGenre = null;
    });
    _fetchTracksFromApi(_searchQuery);
  }

  void _openGenre(String genre) {
    setState(() {
      _selectedGenre = genre;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  List<MusicTrack> get _searchResults {
    if (_searchQuery.isNotEmpty) {
      return _networkTracks;
    }
    return [];
  }

  Widget _cover(String url, {double size = 44, double radius = 8}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: const Color(0xFF303030),
          child: const Icon(Icons.music_note, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _homeScreen() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      children: const [
        Text('MiKullMusic', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        Text('Добро пожаловать в плеер! Открой вкладку поиска внизу экрана, чтобы найти музыку с твоего FastAPI бэкенда.',
          style: TextStyle(color: Colors.grey, fontSize: 15)),
      ],
    );
  }

  Widget _searchResultsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    final results = _searchResults;
    if (results.isEmpty && _searchQuery.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: Text('Ничего не найдено', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: results.map((track) {
        final isPlayingThis = _currentTrack?.id == track.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isPlayingThis ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _cover(track.coverUrl, size: 42, radius: 6),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isPlayingThis ? accentColor : Colors.white)),
                    Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _selectTrack(track, playlist: results),
                icon: Icon(isPlayingThis && _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: accentColor, size: 28),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _searchScreen() {
    final showingResults = _searchQuery.isNotEmpty || _selectedGenre != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      children: [
        const Text('Поиск', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          onChanged: _search,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: 'Введите название для генерации треков...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: panelColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentColor)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_searchQuery.isNotEmpty ? 'Результаты поиска бэкенда' : 'Жанры',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (!showingResults) _genreGrid() else _searchResultsList(),
      ],
    );
  }

  Widget _genreGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: genres.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final genre = genres[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openGenre(genre.name),
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: genre.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(genre.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _placeholderScreen(String title, IconData icon, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 58, color: Colors.white38),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _playerPanel() {
    if (_currentTrack == null) return const SizedBox.shrink();

    final totalMs = _duration.inMilliseconds.toDouble();
    final currentMs = _position.inMilliseconds.toDouble();

    return Container(
      decoration: const BoxDecoration(
        color: panelColor,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _cover(_currentTrack!.coverUrl, size: 42, radius: 6),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentTrack!.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(_currentTrack!.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _skipTrack(-1),
                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
              ),
              IconButton(
                onPressed: _playPause,
                icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 29),
              ),
              IconButton(
                onPressed: () => _skipTrack(1),
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
              ),
            ],
          ),
          Row(
            children: [
              Text(_formatDuration(_position), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                    activeTrackColor: accentColor,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    min: 0,
                    max: totalMs <= 0 ? 1.0 : totalMs,
                    value: currentMs.clamp(0.0, totalMs <= 0 ? 1.0 : totalMs),
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(milliseconds: value.round()));
                    },
                  ),
                ),
              ),
              Text(_formatDuration(_duration), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomNavigation() {
    return Container(
      height: 62,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navButton(Icons.home_rounded, 0),
          _navButton(Icons.search_rounded, 1),
          _navButton(Icons.library_music_rounded, 2),
          _navButton(Icons.person_rounded, 3),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, int index) {
    return IconButton(
      onPressed: () => setState(() => _currentTab = index),
      icon: Icon(icon, size: 26, color: _currentTab == index ? Colors.white : Colors.grey),
    );
  }

  Widget _currentScreen() {
    switch (_currentTab) {
      case 0:
        return _homeScreen();
      case 1:
        return _searchScreen();
      case 2:
        return _placeholderScreen('Библиотека', Icons.library_music_rounded, 'Твои плейлисты появятся здесь');
      case 3:
        return _placeholderScreen('Профиль', Icons.person_rounded, 'Профиль будет подключён позже');
      default:
        return _homeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _currentScreen()),
            _playerPanel(),
            _bottomNavigation(),
          ],
        ),
      ),
    );
  }
}