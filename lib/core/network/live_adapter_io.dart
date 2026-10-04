import 'package:dio/dio.dart';

/// Dio's own adapter already streams on Android, iOS and desktop.
HttpClientAdapter? streamingAdapter() => null;
