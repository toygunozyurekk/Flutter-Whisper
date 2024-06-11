import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordButton extends StatefulWidget {
  final void Function(String) onRecordComplete;

  const RecordButton({Key? key, required this.onRecordComplete}) : super(key: key);

  @override
  _RecordButtonState createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initRecorder();
    _initPlayer();
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder!.openRecorder();
      if (await Permission.microphone.request().isGranted) {
        print('Mikrofon izni verildi');
      } else {
        print('Mikrofon izni reddedildi');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mikrofon izni gerekli')),
        );
      }
    } catch (e) {
      print('Recorder başlatılamadı: $e');
    }
  }

  Future<void> _initPlayer() async {
    try {
      if (await Permission.microphone.request().isGranted && await Permission.storage.request().isGranted) {
        await _player!.openPlayer();
        print('Player başlatıldı');
      } else {
        print('Mikrofon ve depolama izinleri gerekli');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mikrofon ve depolama izinleri gerekli')),
        );
      }
    } catch (e) {
      print('Player başlatılamadı: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_recorder == null) {
      print('Recorder başlatılamadı');
      return;
    }
    try {
      if (await Permission.microphone.request().isGranted && await Permission.storage.request().isGranted) {
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = '${tempDir.path}/flutter_sound.m4a';

        await _recorder!.startRecorder(
          toFile: tempPath,
          codec: Codec.aacMP4, // m4a formatı için codec ayarı
          sampleRate: 44100,   // Örnekleme hızını artırma
          bitRate: 128000      // Bit hızını artırma
        );
        setState(() {
          _isRecording = true;
          _filePath = tempPath;
        });
        print('Kayıt başladı: $_filePath');
      } else {
        print('Mikrofon ve depolama izinleri gerekli');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mikrofon ve depolama izinleri gerekli')),
        );
      }
    } catch (e) {
      print('Kayıt başlatılamadı: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder == null) {
      print('Recorder durdurulamadı');
      return;
    }
    try {
      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      print('Kayıt durduruldu: $_filePath');
      if (_filePath != null) {
        widget.onRecordComplete(_filePath!);
      }
    } catch (e) {
      print('Kayıt durdurulamadı: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_player == null) {
      print('Player başlatılamadı');
      return;
    }
    try {
      if (_filePath != null && await File(_filePath!).exists()) {
        await _player!.startPlayer(
          fromURI: _filePath,
          codec: Codec.aacMP4,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
            });
          },
        );
        setState(() {
          _isPlaying = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt dosyası bulunamadı')),
        );
      }
    } catch (e) {
      print('Kayıt oynatılamadı: $e');
    }
  }

  Future<void> _stopPlaying() async {
    if (_player == null) {
      print('Player durdurulamadı');
      return;
    }
    try {
      await _player!.stopPlayer();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      print('Kayıt durdurulamadı: $e');
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          color: _isRecording ? Colors.red : Colors.blue,
          onPressed: _isRecording ? _stopRecording : _startRecording,
        ),
        IconButton(
          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
          color: _isPlaying ? Colors.red : Colors.green,
          onPressed: _isPlaying ? _stopPlaying : _playRecording,
        ),
      ],
    );
  }
}
