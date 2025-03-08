// Format seconds to MM:SS format
String formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}

// Format a Duration to MM:SS format
String formatDurationFromDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

// Format double seconds to MM:SS format
String formatSecondsFromDouble(double seconds) {
  return formatDuration(seconds.toInt());
}