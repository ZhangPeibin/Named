import 'dart:typed_data';

import '../../domain/talk.dart';
import '../api/talk_api.dart';
import '../dto/talk_dto.dart';

class TalkRepository {
  const TalkRepository(this._api);

  final TalkApi _api;

  Future<Conversation> createConversation({
    required String focusType,
    required String focusId,
  }) async {
    return (await _api.createConversation(
      focusType: focusType,
      focusId: focusId,
    )).toDomain();
  }

  Future<Conversation> fetch(String conversationId) async {
    return (await _api.fetch(conversationId)).toDomain();
  }

  Future<PronunciationAudio> synthesizePronunciation(String text) async {
    return (await _api.synthesizePronunciation(text)).toDomain();
  }

  Future<String> transcribeAudio(Uint8List audio) {
    return _api.transcribeAudio(audio);
  }

  Future<TalkAudio> synthesizeSpeech(String text) async {
    return (await _api.synthesizeSpeech(text)).toDomain();
  }

  Future<HelpSuggestion> helpExpression({
    required String conversationId,
    required String text,
  }) async {
    return (await _api.helpExpression(
      conversationId: conversationId,
      text: text,
    )).toDomain();
  }

  Future<Turn> sendMessage({
    required String conversationId,
    required String text,
    required String clientMessageId,
  }) async {
    return (await _api.sendMessage(
      conversationId: conversationId,
      text: text,
      clientMessageId: clientMessageId,
    )).toDomain();
  }
}
