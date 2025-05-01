import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert'; // JSON verilerini işlemek için
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as path; // Import the path package

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  bool _isLoading = false; // Yükleniyor durumu
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic> _playlistData = {}; // Çalma listesi verileri
  Map<String, dynamic> _trackData = {}; // Tek şarkı verileri
  late YoutubePlayerController _youtubePlayerController;
  List<bool> _isPlaying = []; // Her şarkının oynatma durumu
  late AnimationController _animationController;
  Duration _currentPosition = Duration.zero; // Geçerli pozisyon
  bool _isPlayingTrack = false; // Her şarkının oynatma durumu
  List<bool> _isDownloading = []; // List to track download state for each track
  List<bool> _isDeleting = []; // List to track download state for each track

  @override
  void initState() {
    super.initState();
    _isDownloading = List.filled(999, false);
    _isDeleting = List.filled(999, false);
    _youtubePlayerController = YoutubePlayerController(
      initialVideoId: '',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false, // Ses kapalı
      ),
    );
    _youtubePlayerController.addListener(() {
      if (_youtubePlayerController.value.isPlaying) {
        _currentPosition = _youtubePlayerController.value.position;
      }
    });
    // Animasyon kontrolcüsü
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _youtubePlayerController.dispose(); // YoutubePlayerController'ı kapat
    _animationController.dispose(); // Animasyon kontrolcüsünü kapat
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f0f),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(1),
                spreadRadius: 5,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Image.network(
                  'https://storage.googleapis.com/pr-newsroom-wp/1/2023/05/Spotify_Primary_Logo_RGB_Green.png',
                  height: 40,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Focus',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF576574),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            width: 0,
            height: 0,
            child: YoutubePlayer(
              controller: _youtubePlayerController,
              aspectRatio: 16 / 9,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _isFocused
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _isFocused
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: _isFocused ? 3 : 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      controller: _controller,
                      onTap: () {
                        setState(() {
                          _isFocused = true;
                        });
                      },
                      onEditingComplete: () {
                        setState(() {
                          _isFocused = false;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Paste Link...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      String inputUrl = _controller.text.trim();
                      if (inputUrl.isNotEmpty) {
                        _handleUrl(inputUrl);
                      }
                    },
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                    ), // Yüklenme göstergesi
                  )
                : _playlistData.isNotEmpty &&
                        _playlistData['youtube_links'] != null &&
                        _playlistData['youtube_links']['tracks'] != null
                    ? Column(
                        children: [
                          SizedBox(
                            height: 25,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Container(
                              child: Image.network(
                                _playlistData['youtube_links']
                                        ['playlist_cover_url'] ??
                                    '',
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 35,
                          ),
                          Text(
                            _playlistData['youtube_links']['playlist_name'],
                            style: TextStyle(color: Colors.white, fontSize: 30),
                          ),
                          SizedBox(
                            height: 25,
                          ),
                          Expanded(
                            // Burada ListView için bir Expanded kullanıyoruz
                            child: ListView.builder(
                              itemCount: _playlistData['youtube_links']
                                      ['tracks']
                                  .length,
                              itemBuilder: (context, index) {
                                var track = _playlistData['youtube_links']
                                    ['tracks'][index];
                                _deletableTrack(track['youtube_link'], index);
                                return ListTile(
                                  leading: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.2),
                                          spreadRadius: .01,
                                          blurRadius: 10,
                                          offset: const Offset(0, -2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Kapak resmi
                                        Image.network(track['cover_url']),
                                      ],
                                    ),
                                  ),
                                  title: Text(
                                    track['track'],
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(track['artist']),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _isPlaying[index]
                                              ? Icons.pause_circle_filled
                                              : Icons.play_circle_filled,
                                        ),
                                        onPressed: () {
                                          _playTrack(
                                              track['youtube_link'], index);
                                        },
                                      ),
                                      _isDeleting[index]
                                          ? IconButton(
                                              onPressed: () {
                                                _deleteTrack(
                                                    track['youtube_link']);
                                              },
                                              icon: const Icon(Icons.delete),
                                            )
                                          : _isDownloading[
                                                  index] // Check if downloading
                                              ? SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                    strokeWidth: 2.0,
                                                  ), // Show loading indicator
                                                )
                                              : IconButton(
                                                  icon: const Icon(
                                                      Icons.download),
                                                  onPressed: () {
                                                    _downloadTrack(
                                                        track['youtube_link'],
                                                        track['cover_url'],
                                                        track['album'],
                                                        index,
                                                        track['track'],
                                                        track['artist']);
                                                  },
                                                ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : _trackData.isNotEmpty
                        ? _buildTrackDetails() // Tek şarkı detaylarını göster
                        : const Center(
                            child:
                                Text('Arama sonuçları burada görüntülenecek.'),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _playTrack(String youtubeLink, int index) async {
    print('Oynatılıyor: $youtubeLink');
    if (index < 9999) {
      String videoId = YoutubePlayer.convertUrlToId(youtubeLink) ?? '';

      if (_youtubePlayerController.metadata.videoId != videoId) {
        // Yeni video yükleniyorsa sıfırdan başlat
        _youtubePlayerController.load(videoId);
        _currentPosition = Duration.zero; // Pozisyonu sıfırla
      } else if (_isPlaying[index]) {
        // Şu an oynuyorsa duraklat ve pozisyonu güncelle
        _youtubePlayerController.pause();
        setState(() {
          _isPlaying[index] = false;
        });
        _currentPosition = _youtubePlayerController.value.position;
        return;
      } else {
        // Duruyorsa kaldığı yerden devam et
        _youtubePlayerController.seekTo(_currentPosition);
        _youtubePlayerController.play();
      }

      setState(() {
        bool firstState = !_isPlaying[index];
        for (int i = 0; i < _isPlaying.length; i++) {
          _isPlaying[i] = false;
        }
        _isPlaying[index] = firstState;
      });
    } else {
      print(_isPlayingTrack);
      String videoId = YoutubePlayer.convertUrlToId(youtubeLink) ?? '';

      if (_youtubePlayerController.metadata.videoId != videoId) {
        // Yeni video yükleniyorsa sıfırdan başlat
        _youtubePlayerController.load(videoId);
        _currentPosition = Duration.zero; // Pozisyonu sıfırla
      }
      if (_isPlayingTrack == true) {
        // Şu an oynuyorsa duraklat ve pozisyonu güncelle
        print("HEREEEE");
        _youtubePlayerController.pause();
        setState(() {
          _isPlayingTrack = !_isPlayingTrack;
        });
        _currentPosition = _youtubePlayerController.value.position;
        return;
      } else {
        // Duruyorsa kaldığı yerden devam et
        _youtubePlayerController.seekTo(_currentPosition);
        _youtubePlayerController.play();
      }

      setState(() {
        _isPlayingTrack = !_isPlayingTrack;
      });
    }
  }

  void _handleUrl(String url) {
    setState(() {
      _isLoading = true; // Yüklenmeye başla
      _trackData = {}; // Eski tek şarkı verilerini temizle
      _playlistData = {}; // Eski çalma listesi verilerini temizle
    });

    if (url.contains('track')) {
      _fetchTrackData(url);
    } else if (url.contains('playlist')) {
      _fetchPlaylistData(url);
    } else {
      setState(() {
        _isLoading = false; // Geçersiz URL durumunda yüklenmeyi durdur
      });
      print('Geçersiz URL: $url');
    }
  }

  Future<void> _fetchTrackData(String url) async {
    try {
      final response = await http.get(Uri.parse(
          'http://154.53.166.72:1919/spotify/download/music?music_url=$url'));
      if (response.statusCode == 200) {
        // Gelen veriyi UTF-8 olarak çözümleyin
        final decodedResponse = json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          _trackData = decodedResponse; // Tek şarkı verisini al
          _isLoading = false; // Yüklenmeyi durdur
        });
        print('Şarkı verileri: $_trackData');
      } else {
        setState(() {
          _isLoading = false; // Hata durumunda yüklenmeyi durdur
        });
        print('API hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hata durumunda yüklenmeyi durdur
      });
      print('Hata: $e');
    }
  }

  Future<void> _fetchPlaylistData(String url) async {
    try {
      final response = await http.get(Uri.parse(
          'http://154.53.166.72:1919/spotify/download/playlist?playlist_url=$url'));
      if (response.statusCode == 200) {
        // Gelen veriyi UTF-8 olarak çözümleyin
        final decodedResponse = json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          _playlistData = decodedResponse; // Çalma listesi verilerini al
          _isPlaying = List.filled(
              _playlistData['youtube_links']['tracks'].length,
              false); // Her şarkının oynatma durumunu false olarak başlat
          _isLoading = false; // Yüklenmeyi durdur
        });
        print('Çalma listesi verileri: $_playlistData');
      } else {
        setState(() {
          _isLoading = false; // Hata durumunda yüklenmeyi durdur
        });
        print('API hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hata durumunda yüklenmeyi durdur
      });
      print('Hata: $e');
    }
  }

  Future<String?> downloadAndSaveImage(String imageUrl, String fileName) async {
    try {
      // URL'den resmi indir
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Geçici dizini al
        Directory? directory = await getExternalStorageDirectory();
        String filePath = path.join(directory!.path, fileName);

        // Dosyayı kaydet
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('Resim kaydedildi: $filePath');
        return filePath;
      } else {
        print('Resim indirme başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('Hata oluştu: $e');
    }
    return null;
  }

  Future<void> _downloadTrack(String youtubeLink, String coverUrl,
      String albumName, int index, String Track, String Artist) async {
    // Request storage permission
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      try {
        setState(() {
          _isDownloading[index] = true; // Start download
        });

        final response = await http.get(Uri.parse(
            'http://154.53.166.72:1919/youtube/download/music?music_url=$youtubeLink&cover_url=$coverUrl&album_name=$albumName'));

        if (response.statusCode == 200) {
          // İstediğiniz formatta dosya adını oluşturma
          String filename = '$Track $Artist.mp3';

          // Get the directory for external storage
          Directory? directory = await getExternalStorageDirectory();
          if (directory != null) {
            String filePath = path.join(directory.path, filename);
            File file = File(filePath);
            await file.create(recursive: true);
            await file.writeAsBytes(response.bodyBytes);
            final coverPath =
                await downloadAndSaveImage(coverUrl, '$Track $Artist.png');
            // Save track details to JSON
            await _saveTrackToJson(
              youtubeLink,
              filePath,
              Track,
              Artist,
              coverPath!,
            );

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Download Successful: $filename')));
          } else {
            print("Invalid directory");
          }
        } else {
          print('Error: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("$e")));
        print('Download error: $e');
      } finally {
        setState(() {
          _isDownloading[index] = false; // End download
        });
      }
    } else {
      print('Storage permission denied.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied.')),
      );
    }
  }

  Future<void> _deletableTrack(String youtubeLink, int index) async {
    Directory? directory = await getExternalStorageDirectory();
    String jsonFilePath = path.join(directory!.path, 'downloaded_tracks.json');

    if (File(jsonFilePath).existsSync()) {
      final file = File(jsonFilePath);
      String jsonString = await file.readAsString();
      List<dynamic> tracks = json.decode(jsonString);

      // Find the track to delete
      final trackHasBeen = tracks.firstWhere(
          (track) => track['youtube_link'] == youtubeLink,
          orElse: () => null);

      if (trackHasBeen != null) {
        setState(() {
          _isDeleting[index] = true;
        });
      } else {
        setState(() {
          _isDeleting[index] = false;
        });
      }
      return;
    }
  }

  Future<void> _deleteTrack(String youtubeLink) async {
    try {
      Directory? directory = await getExternalStorageDirectory();
      String jsonFilePath =
          path.join(directory!.path, 'downloaded_tracks.json');

      if (File(jsonFilePath).existsSync()) {
        final file = File(jsonFilePath);
        String jsonString = await file.readAsString();
        List<dynamic> tracks = json.decode(jsonString);

        // Find the track to delete
        final trackToDelete = tracks.firstWhere(
            (track) => track['youtube_link'] == youtubeLink,
            orElse: () => null);

        if (trackToDelete != null) {
          // Delete the associated music file
          String musicFilePath = trackToDelete['file_path'];
          File musicFile = File(musicFilePath);
          if (await musicFile.exists()) {
            await musicFile.delete();
            print('Deleted music file: $musicFilePath');
          }

          // Filter out the track to be deleted
          tracks.removeWhere((track) => track['youtube_link'] == youtubeLink);

          final jsonData = json.encode(tracks);
          await file.writeAsString(jsonData);

          print('Track deleted: $youtubeLink');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Track deleted successfully.')),
          );
        } else {
          print('Track not found: $youtubeLink');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Track not found for deletion.')),
          );
        }
      }
    } catch (e) {
      print('Error deleting track: $e');
    }
  }

  Widget _buildTrackDetails() {
    _deletableTrack(_trackData['youtube_link'], 0);
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Arka planda YouTube oynatıcı (gizli)
              SizedBox(
                width: 0,
                height: 0,
                child: YoutubePlayer(
                  controller: _youtubePlayerController,
                  aspectRatio: 16 / 9,
                  onEnded: (metaData) {
                    setState(() {
                      _isPlayingTrack =
                          false; // Video bittiğinde durumu güncelle
                    });
                  },
                ),
              ),
              // Kapak resmi
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Container(
                  child: Image.network(
                    _trackData['cover_url'] ?? '',
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Oynat/Duraklat düğmesi
              Positioned(
                child: IconButton(
                  icon: Icon(
                    _isPlayingTrack
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 60,
                  ),
                  onPressed: () {
                    // Şarkıyı oynat veya duraklat
                    if (_trackData.isNotEmpty) {
                      _playTrack(_trackData['youtube_link'], 9999);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            textAlign: TextAlign.center,
            _trackData['track'] ?? 'Şarkı adı yok',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _trackData['artist'] ?? 'Sanatçı adı yok',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: _isDeleting[0]
                      ? const Icon(Icons.delete, color: Colors.white)
                      : _isDownloading[0]
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2.0,
                            )
                          : const Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    if (!_isDownloading[0] && !_isDeleting[0]) {
                      _downloadTrack(
                          _trackData['youtube_link'],
                          _trackData['cover_url'],
                          _trackData['album'],
                          0,
                          _trackData['track'],
                          _trackData['artist']);
                    } else if (_isDeleting[0]) {
                      _deleteTrack(_trackData['youtube_link']);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveTrackToJson(String youtubeLink, String filePath,
      String trackName, String artist, String coverLocal) async {
    try {
      Directory? directory = await getExternalStorageDirectory();
      String jsonFilePath =
          path.join(directory!.path, 'downloaded_tracks.json');

      List<dynamic> tracks = [];
      if (File(jsonFilePath).existsSync()) {
        final file = File(jsonFilePath);
        String jsonString = await file.readAsString();
        tracks = json.decode(jsonString);
      }

      // Check if the track is already downloaded
      if (tracks.any((track) => track['youtube_link'] == youtubeLink)) {
        print('Track already downloaded');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Song is already downloaded.')),
        );
        return; // Exit if the track is already downloaded
      }

      Map<String, dynamic> newTrack = {
        'coverLocal': coverLocal,
        'trackName': trackName,
        'artist': artist,
        'youtube_link': youtubeLink,
        'file_path': filePath, // Add the file path
      };
      tracks.add(newTrack);

      final jsonData = json.encode(tracks);
      await File(jsonFilePath).writeAsString(jsonData);
      print('Track saved to JSON: $newTrack');
    } catch (e) {
      print('Error saving track to JSON: $e');
    }
  }
}
