import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:marquee/marquee.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path; // Path paketini içe aktar

// Track Model
class Track {
  final String youtubeLink;
  final String filePath;
  final String trackName;
  final String artist;
  final String coverLocal;

  Track(
      {required this.youtubeLink,
      required this.filePath,
      required this.trackName,
      required this.artist,
      required this.coverLocal});

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      youtubeLink: json['youtube_link'],
      filePath: json['file_path'],
      trackName: json['trackName'],
      artist: json['artist'],
      coverLocal: json['coverLocal'],
    );
  }
}

// MusicPageWidget
class MusicPageWidget extends StatefulWidget {
  const MusicPageWidget({super.key});

  @override
  _MusicPageWidgetState createState() => _MusicPageWidgetState();
}

class _MusicPageWidgetState extends State<MusicPageWidget> {
  List<Track> tracks = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Track? currentTrack;
  List<bool> _isDeleting = []; // List to track download state for each track

  @override
  void initState() {
    super.initState();
    _isDeleting = List.filled(999, false);
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
      });
    });
    loadTracks();
  }

  Future<void> loadTracks() async {
    // Dış depolama dizinini al
    Directory? directory = await getExternalStorageDirectory();
    String jsonFilePath = path.join(directory!.path, 'downloaded_tracks.json');

    // JSON dosyasını oku
    File jsonFile = File(jsonFilePath);
    if (await jsonFile.exists()) {
      String jsonString = await jsonFile.readAsString();
      List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        tracks = jsonList.map((json) => Track.fromJson(json)).toList();
      });
    } else {
      print("Dosya bulunamadı: $jsonFilePath");
    }
  }

  void playTrack(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      try {
        await _audioPlayer.setSource(DeviceFileSource(filePath));
        await _audioPlayer.resume();
        setState(() {
          isPlaying = true;
          currentTrack =
              tracks.firstWhere((track) => track.filePath == filePath);
        });
      } catch (e) {
        print("Çalma hatası: $e");
      }
    } else {
      print("Dosya bulunamadı: $filePath");
    }
  }

  void pauseTrack() async {
    await _audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }

  void resumeTrack() async {
    await _audioPlayer.resume();
    setState(() {
      isPlaying = true;
    });
  }

  void stopTrack() async {
    await _audioPlayer.stop();
    setState(() {
      isPlaying = false;
      currentTrack = null; // Çalan parça yok
    });
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
          // Müzik kontrol butonları
          Expanded(
            child: tracks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      return _isDeleting[index]
                          ? SizedBox
                              .shrink() // Eğer silme durumu varsa, boş bir widget döndür
                          : Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color:
                                        const Color.fromARGB(25, 255, 255, 255),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Row'u çocuklarının genişliğiyle sınırlandır
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(.3),
                                            spreadRadius: 1,
                                            blurRadius: 10,
                                            offset: const Offset(0, -2),
                                          ),
                                        ],
                                      ),
                                      child: Image.file(
                                        File(tracks[index].coverLocal),
                                        height: 50,
                                        width: 50, // Genişliği sınırla
                                        fit: BoxFit
                                            .cover, // Resmin sığmasını sağla
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    // Expanded kullanımı burada uygun, çünkü kalan alanı kaplaması isteniyor
                                    child: ListTile(
                                      title: Text(
                                        tracks[index].trackName,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        tracks[index].artist,
                                        style: TextStyle(color: Colors.white60),
                                      ),
                                      onTap: () {
                                        playTrack(tracks[index].filePath);
                                      },
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    color:
                                        const Color.fromARGB(255, 21, 21, 21),
                                    onSelected: (value) {
                                      // Menüden seçilen değere göre işlemler yapabilirsiniz
                                      if (value == 'add_playlist') {
                                        // Düzenleme işlemi
                                      } else if (value == 'favorite') {
                                        // Silme işlemi
                                      } else if (value == 'remove_track') {
                                        _deleteTrack(tracks[index].youtubeLink);
                                        setState(() {
                                          _isDeleting[index] = true;
                                        });
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        PopupMenuItem(
                                          value: 'add_playlist',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.add_circle_outline_sharp,
                                                color: Colors.white60,
                                              ),
                                              const SizedBox(
                                                  width:
                                                      10), // İkon ile metin arasında boşluk
                                              Text('Add Playlist',
                                                  style: TextStyle(
                                                      color: Colors.white60)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'favorite',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.favorite_border,
                                                color: Colors.white60,
                                              ),
                                              const SizedBox(
                                                  width:
                                                      10), // İkon ile metin arasında boşluk
                                              Text('Favorite',
                                                  style: TextStyle(
                                                      color: Colors.white60)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'remove_track',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                color: Colors.white60,
                                              ),
                                              const SizedBox(
                                                  width:
                                                      10), // İkon ile metin arasında boşluk
                                              Text('Delete',
                                                  style: TextStyle(
                                                      color: Colors.white60)),
                                            ],
                                          ),
                                        ),
                                      ];
                                    },
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            );
                    },
                  ),
          ),

          // Müzik listesi
          if (currentTrack != null) ...[
            const SizedBox(height: 13),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: const Color.fromARGB(255, 100, 129, 7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(.3),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(.3),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Image.file(
                            File(currentTrack!.coverLocal),
                            height: 50,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDynamicMarquee(
                                currentTrack!.trackName, 18.0, FontWeight.bold),
                            _buildDynamicMarquee(
                                currentTrack!.artist, 15.0, FontWeight.normal),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: isPlaying ? pauseTrack : resumeTrack,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Dinamik Marquee oluşturan metod
  // Dinamik Marquee oluşturan metod
  Widget _buildDynamicMarquee(
      String text, double fontSize, FontWeight fontWeight) {
    // TextPainter kullanarak metin genişliğini hesapla
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Metin genişliğini kontrol et ve gerekirse kısalt
    String truncatedText = text;
    if (textPainter.size.width > 200) {
      // Kısaltma için bir döngü kullan
      while (truncatedText.isNotEmpty) {
        textPainter.text = TextSpan(
          text: '$truncatedText...', // Sonuna '...' ekle
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.white,
          ),
        );
        textPainter.layout();
        if (textPainter.size.width <= 200) {
          break; // Genişlik 200'ü geçmiyorsa döngüyü kır
        }
        truncatedText = truncatedText.substring(
            0, truncatedText.length - 1); // Son karakteri çıkar
      }
    }

    // Hesaplanan genişliği kullanarak Marquee oluştur
    return SizedBox(
      width: textPainter.size.width + 10, // Genişlik sınırı
      height: 20, // Yükseklik
      child: Marquee(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
        scrollAxis: Axis.horizontal,
        blankSpace: 20.0,
        velocity: 10.0,
        startAfter: const Duration(seconds: 5),
        pauseAfterRound: const Duration(seconds: 5),
      ),
    );
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
