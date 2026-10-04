import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../models/assistant_reply_model.dart';
import '../sources/assistant_remote_source.dart';

/// Answers come from the `/assistant` API, which picks Books from
/// Waraqah's catalog and words the reply (the server may ask Gemini to;
/// no AI key ships in the app).
class AssistantRepositoryImpl implements AssistantRepository {
  /// [_lang] says which language to answer in (`en` or `bn`).
  AssistantRepositoryImpl(this._source, this._lang);

  final AssistantRemoteSource _source;
  final String Function() _lang;

  @override
  Future<List<ChatMessage>> openConversation() async => [
    (await _source.greeting(_lang())).toEntity(),
  ];

  @override
  Future<ChatMessage> ask(String prompt, List<ChatMessage> history) async =>
      (await _source.ask(prompt, history, _lang())).toEntity();
}
