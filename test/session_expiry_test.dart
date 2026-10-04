import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:waraqah/core/network/api_exception.dart';
import 'package:waraqah/core/network/session_tokens.dart';
import 'package:waraqah/features/auth/data/models/app_user_model.dart';
import 'package:waraqah/features/auth/data/sources/session_store.dart';
import 'package:waraqah/features/auth/data/sources/stored_session_tokens.dart';

/// A server that refuses every refresh with 401, or is down.
class _Server implements HttpClientAdapter {
  _Server(this.status);

  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(null),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// The refresh client as the app builds it: errors lose their response and
/// carry an [ApiException] instead (see DioClient).
Dio _dio(int status) {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test/v1'))
    ..httpClientAdapter = _Server(status);
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) => handler.next(
        DioException(
          requestOptions: error.requestOptions,
          error: ApiException(
            error.message ?? 'Request failed',
            statusCode: error.response?.statusCode,
          ),
          type: error.type,
        ),
      ),
    ),
  );
  return dio;
}

Future<SessionStore> _signedIn() async {
  SharedPreferences.setMockInitialValues({});
  final store = SessionStore(await SharedPreferences.getInstance());
  await store.write(
    const AppUserModel(
      id: 'u_1',
      name: 'Reader',
      email: 'reader@waraqah.test',
      role: 'reader',
      accessToken: 'old',
      refreshToken: 'dead',
    ),
  );
  return store;
}

void main() {
  test('a refused refresh token signs the reader out', () async {
    final store = await _signedIn();
    final expiry = SessionExpiry();
    var expired = 0;
    expiry.stream.listen((_) => expired++);

    final tokens = StoredSessionTokens(store, _dio(401), expiry);
    expect(await tokens.refresh(), isNull);
    await Future<void>.delayed(Duration.zero);

    expect(store.read(), isNull, reason: 'the saved session is cleared');
    expect(expired, 1, reason: 'the app is told, so it goes to login');
  });

  test('a server that is down does not sign the reader out', () async {
    final store = await _signedIn();
    final expiry = SessionExpiry();
    var expired = 0;
    expiry.stream.listen((_) => expired++);

    final tokens = StoredSessionTokens(store, _dio(503), expiry);
    expect(await tokens.refresh(), isNull);
    await Future<void>.delayed(Duration.zero);

    expect(store.read(), isNotNull);
    expect(expired, 0);
  });
}
