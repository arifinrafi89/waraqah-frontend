import 'package:dio/dio.dart';

import '../../../../core/network/live_events.dart';
import '../models/inbox_thread_model.dart';
import 'inbox_fake_api.dart';

/// The live connection to `/inbox/live`: one event per change. It
/// reconnects by itself when the connection drops (`liveEvents`).
class InboxLiveSource {
  InboxLiveSource(this._dio);

  final Dio _dio;

  Stream<InboxChangeModel> changes() =>
      liveEvents(_dio, InboxFakeApi.live).map(InboxChangeModel.fromJson);
}
