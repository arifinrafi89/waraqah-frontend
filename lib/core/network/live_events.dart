import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';

/// The wait before reconnect [attempt] (0 = the first): 1 s, 2 s, 4 s …
/// up to 30 s.
Duration liveBackoff(int attempt) =>
    Duration(seconds: math.min(30, 1 << math.min(attempt, 5)));

/// The JSON of one server-sent events line, or `null` for anything that
/// isn't a `data:` line: `: ping` heartbeats, blank lines, other fields.
Map<String, dynamic>? liveEventData(String line) {
  if (!line.startsWith('data:')) return null;
  try {
    final json = jsonDecode(line.substring(5).trim());
    return json is Map<String, dynamic> ? json : null;
  } on FormatException {
    return null;
  }
}

/// A live endpoint (`/inbox/live`, `/sales/live`, `/notifications/live`)
/// as a stream of its events' JSON.
///
/// The connection stays open as long as someone listens. When it ends or
/// fails (a server restart, the network dropping, a proxy timing out), it
/// reconnects after [backoff], starting again from the shortest wait once
/// the server sends anything. Cancelling the subscription closes it.
Stream<Map<String, dynamic>> liveEvents(
  Dio dio,
  String path, {
  Duration Function(int attempt) backoff = liveBackoff,
}) => _LiveConnection(dio, path, backoff).events.stream;

class _LiveConnection {
  _LiveConnection(this._dio, this._path, this._backoff) {
    events = StreamController(onListen: _connect, onCancel: _close);
  }

  final Dio _dio;
  final String _path;
  final Duration Function(int attempt) _backoff;
  late final StreamController<Map<String, dynamic>> events;

  CancelToken? _request;
  StreamSubscription<String>? _lines;
  Timer? _retry;
  int _attempt = 0;
  bool _closed = false;

  Future<void> _connect() async {
    if (_closed) return;
    _request = CancelToken();
    try {
      final response = await _dio.get<ResponseBody>(
        _path,
        cancelToken: _request,
        // A live connection stays open as long as the app listens.
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: Duration.zero,
        ),
      );
      final body = response.data;
      if (_closed || body == null) return _reconnectLater();
      _lines = body.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _onLine,
            onError: (Object _) => _reconnectLater(),
            onDone: _reconnectLater,
            cancelOnError: true,
          );
    } on DioException {
      _reconnectLater();
    }
  }

  void _onLine(String line) {
    _attempt = 0;
    final data = liveEventData(line);
    if (data != null) events.add(data);
  }

  void _reconnectLater() {
    if (!_closed) _retry = Timer(_backoff(_attempt++), _connect);
  }

  Future<void> _close() async {
    _closed = true;
    _retry?.cancel();
    _request?.cancel();
    await _lines?.cancel();
  }
}
