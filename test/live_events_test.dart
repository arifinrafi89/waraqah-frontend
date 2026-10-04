import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:waraqah/core/network/live_events.dart';

/// A live endpoint that plays one script per connection: each script is the
/// text it sends before hanging up, or `null` to refuse the connection.
class _Server implements HttpClientAdapter {
  _Server(this.scripts, {this.holdLast = false});

  final List<String?> scripts;
  final bool holdLast;
  int connections = 0;
  final open = <StreamController<Uint8List>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final script = scripts[connections++ % scripts.length];
    if (script == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'refused',
      );
    }
    final body = StreamController<Uint8List>();
    open.add(body);
    body.add(Uint8List.fromList(utf8.encode(script)));
    if (!(holdLast && connections == scripts.length)) unawaited(body.close());
    return ResponseBody(body.stream, 200);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Server server) => Dio()..httpClientAdapter = server;

void main() {
  test('only data lines are events; pings and blank lines are skipped', () {
    expect(liveEventData(': ping'), isNull);
    expect(liveEventData(''), isNull);
    expect(liveEventData('event: x'), isNull);
    expect(liveEventData('data: not json'), isNull);
    expect(liveEventData('data: {"unread": 3}'), {'unread': 3});
    expect(liveEventData('data:{"seq":1}'), {'seq': 1});
  });

  test('the wait doubles from 1 s up to 30 s', () {
    expect(
      [for (var i = 0; i < 7; i++) liveBackoff(i).inSeconds],
      [1, 2, 4, 8, 16, 30, 30],
    );
  });

  test('reconnects when the stream ends and keeps reading events', () async {
    final server = _Server([
      ': ping\n\ndata: {"seq": 1}\n\n',
      'data: {"seq": 2}\n\n',
    ], holdLast: true);
    final events = await liveEvents(
      _dio(server),
      '/inbox/live',
      backoff: (_) => Duration.zero,
    ).take(2).toList();
    expect(events, [
      {'seq': 1},
      {'seq': 2},
    ]);
    expect(server.connections, 2);
  });

  test('keeps trying with longer waits while the server refuses', () async {
    final waits = <int>[];
    final server = _Server([null, null, null, 'data: {"unread": 1}\n\n']);
    final first = await liveEvents(
      _dio(server),
      '/notifications/live',
      backoff: (attempt) {
        waits.add(attempt);
        return Duration.zero;
      },
    ).first;
    expect(first, {'unread': 1});
    expect(waits, [0, 1, 2]);
  });

  test('a connection that sends something resets the wait', () async {
    final waits = <int>[];
    final server = _Server([null, ': ping\n\n', 'data: {"seq": 9}\n\n']);
    await liveEvents(
      _dio(server),
      '/sales/live',
      backoff: (attempt) {
        waits.add(attempt);
        return Duration.zero;
      },
    ).first;
    expect(waits, [0, 0]);
  });

  test('cancelling closes the connection and stops reconnecting', () async {
    final server = _Server(['data: {"seq": 1}\n\n'], holdLast: true);
    final sub = liveEvents(_dio(server), '/inbox/live').listen((_) {});
    await pumpEventQueue();
    await sub.cancel();
    expect(server.open.single.hasListener, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(server.connections, 1);
  });
}
