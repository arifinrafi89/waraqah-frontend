import 'package:dio/dio.dart';

import '../../../../core/network/live_events.dart';
import 'notification_fake_api.dart';

/// The live connection to `/notifications/live`: the new unread count on
/// each change. It reconnects by itself when the connection drops
/// (`liveEvents`).
class NotificationLiveSource {
  NotificationLiveSource(this._dio);

  final Dio _dio;

  Stream<int> unread() => liveEvents(
    _dio,
    NotificationFakeApi.live,
  ).map((event) => event['unread'] as int);
}
