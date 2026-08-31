import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/services/chat_service.dart';
import '../../domain/models/chat_message_model.dart';

// ── ChatService provider ──────────────────────────────────────────────────────

final chatServiceProvider = Provider<ChatService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatService(dioClient.dio);
});

// ── Chat State ────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? sessionId;

  const ChatState({
    required this.messages,
    this.isTyping = false,
    this.sessionId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? sessionId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

// ── ChatNotifier ──────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final SecureStorageService _secureStorage;

  static const _uuid = Uuid();

  ChatNotifier(this._chatService, this._secureStorage)
      : super(_welcomeState());

  static ChatState _welcomeState() {
    return ChatState(
      messages: [
        ChatMessage(
          id: _uuid.v4(),
          text:
              'Hello! I am your EMS AI Assistant. How can I help you plan your event today?',
          type: ChatMessageType.bot,
          timestamp: DateTime.now(),
          suggestedActions: [
            '🎉 Find Wedding Packages',
            '📍 Catering in Mumbai',
            '🛒 View My Cart',
            '🎫 My Event Tickets',
          ],
        ),
      ],
      sessionId: _uuid.v4(),
    );
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Add user message immediately
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          id: _uuid.v4(),
          text: trimmed,
          type: ChatMessageType.user,
          timestamp: DateTime.now(),
        ),
      ],
      isTyping: true,
    );

    try {
      final jwtToken = await _secureStorage.getAccessToken();

      final botReply = await _chatService.sendMessage(
        message: trimmed,
        jwtToken: jwtToken,
        sessionId: state.sessionId,
      );

      state = state.copyWith(
        messages: [...state.messages, botReply],
        isTyping: false,
      );
    } catch (e) {
      final errorMsg = _buildErrorMessage(e);
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            id: _uuid.v4(),
            text: errorMsg,
            type: ChatMessageType.bot,
            timestamp: DateTime.now(),
            suggestedActions: ['🔄 Try Again', '🎉 Find Events', '📦 Browse Packages'],
          ),
        ],
        isTyping: false,
      );
    }
  }

  void clearChat() {
    state = _welcomeState();
  }

  String _buildErrorMessage(Object e) {
    final err = e.toString().toLowerCase();
    if (err.contains('connection') || err.contains('socket') || err.contains('host lookup')) {
      return "I couldn't connect to the event service right now. Please check your internet connection and try again.";
    }
    if (err.contains('401') || err.contains('unauthorized')) {
      return "Your session has expired. Please log in again to use the full assistant.";
    }
    if (err.contains('timeout')) {
      return "The request timed out. The server might be busy — please try again in a moment.";
    }
    return "I encountered an unexpected error. Please try again or rephrase your question.";
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return ChatNotifier(chatService, secureStorage);
});
