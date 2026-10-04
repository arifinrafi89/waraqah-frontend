import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

HttpClientAdapter? streamingAdapter() => _FetchStreamAdapter();

/// Answers `ResponseType.stream` requests with `fetch`, whose body can be
/// read while it arrives; everything else goes to Dio's browser adapter.
/// Dio's interceptors (the bearer token, the refresh on a 401) still run.
class _FetchStreamAdapter implements HttpClientAdapter {
  final _browser = BrowserHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.responseType != ResponseType.stream) {
      return _browser.fetch(options, requestStream, cancelFuture);
    }
    final abort = web.AbortController();
    unawaited(cancelFuture?.then((_) => abort.abort()));
    final headers = web.Headers();
    options.headers.forEach((name, value) {
      if (value != null) headers.append(name, '$value');
    });
    final response = await web.window
        .fetch(
          options.uri.toString().toJS,
          web.RequestInit(
            method: options.method,
            headers: headers,
            signal: abort.signal,
          ),
        )
        .toDart;
    final contentType = response.headers.get('content-type');
    return ResponseBody(
      _read(response.body, abort),
      response.status,
      statusMessage: response.statusText,
      headers: {
        if (contentType != null) Headers.contentTypeHeader: [contentType],
      },
    );
  }

  /// The body's chunks until it ends; cancelling aborts the request.
  Stream<Uint8List> _read(web.ReadableStream? body, web.AbortController abort) {
    final chunks = StreamController<Uint8List>(onCancel: () => abort.abort());
    if (body == null) {
      unawaited(chunks.close());
      return chunks.stream;
    }
    final reader = body.getReader() as web.ReadableStreamDefaultReader;
    Future<void> pump() async {
      try {
        while (true) {
          final chunk = await reader.read().toDart;
          if (chunk.done) break;
          chunks.add((chunk.value! as JSUint8Array).toDart);
        }
      } catch (error, stack) {
        if (!chunks.isClosed) chunks.addError(error, stack);
      }
      unawaited(chunks.close());
    }

    unawaited(pump());
    return chunks.stream;
  }

  @override
  void close({bool force = false}) => _browser.close(force: force);
}
