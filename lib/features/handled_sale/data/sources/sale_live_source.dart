import 'package:dio/dio.dart';

import '../../../../core/network/live_events.dart';
import 'handled_sale_fake_api.dart';

/// The live connection to `/sales/live`: the id of each sale that changed.
/// It reconnects by itself when the connection drops (`liveEvents`).
class SaleLiveSource {
  SaleLiveSource(this._dio);

  final Dio _dio;

  Stream<String> changes() => liveEvents(
    _dio,
    HandledSaleFakeApi.live,
  ).map((event) => event['saleId'] as String);
}
