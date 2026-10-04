import '../entities/chat_message.dart';

/// The AI block's contract.
///
/// The server picks the Books from Waraqah's catalog and words the reply;
/// any AI key stays on the server, so recommendations stay inside our own
/// catalog.
abstract interface class AssistantRepository {
  /// The greeting shown when the chat opens.
  Future<List<ChatMessage>> openConversation();

  /// Sends one user turn and returns the assistant's reply.
  Future<ChatMessage> ask(String prompt, List<ChatMessage> history);
}
