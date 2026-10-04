import 'package:dio/dio.dart';

import 'live_adapter_io.dart'
    if (dart.library.js_interop) 'live_adapter_web.dart';

/// Gives [dio] an adapter that streams `ResponseType.stream` answers as they
/// arrive, so live endpoints work on every platform. Dio's own adapter does
/// this everywhere except the web, where it waits for the answer to end
/// (and a live answer never ends).
void useStreamingAdapter(Dio dio) {
  final adapter = streamingAdapter();
  if (adapter != null) dio.httpClientAdapter = adapter;
}
