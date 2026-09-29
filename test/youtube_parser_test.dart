import 'package:flutter_test/flutter_test.dart';
import 'package:peer_learn_hub/features/learning/screens/student_lesson_details_screen.dart';

void main() {
  test('parseYoutubeUrl correctly parses YouTube playlist URLs', () {
    final info = parseYoutubeUrl('https://www.youtube.com/playlist?list=PL12345abcdef');
    expect(info, isNotNull);
    expect(info!.isPlaylist, isTrue);
    expect(info.playlistId, 'PL12345abcdef');
  });

  test('parseYoutubeUrl correctly parses YouTube watch URLs with playlist', () {
    final info = parseYoutubeUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLxyz123');
    expect(info, isNotNull);
    expect(info!.isPlaylist, isTrue);
    expect(info.playlistId, 'PLxyz123');
    expect(info.videoId, 'dQw4w9WgXcQ');
  });

  test('parseYoutubeUrl correctly parses YouTube single video watch URLs', () {
    final info = parseYoutubeUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    expect(info, isNotNull);
    expect(info!.isPlaylist, isFalse);
    expect(info.videoId, 'dQw4w9WgXcQ');
  });

  test('parseYoutubeUrl correctly parses short youtu.be URLs', () {
    final info = parseYoutubeUrl('https://youtu.be/dQw4w9WgXcQ');
    expect(info, isNotNull);
    expect(info!.isPlaylist, isFalse);
    expect(info.videoId, 'dQw4w9WgXcQ');
  });
}
