import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/chatbot_providers.dart';
import '../widgets/chat_bubble.dart';

class AiChatbotScreen extends ConsumerStatefulWidget {
  final bool isOrganizerMode;
  final String? initialPrompt;

  const AiChatbotScreen({
    super.key,
    this.isOrganizerMode = false,
    this.initialPrompt,
  });

  @override
  ConsumerState<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends ConsumerState<AiChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatProvider.notifier).sendMessage(widget.initialPrompt!);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _handleSend([String? textToSend]) {
    final text = (textToSend ?? _textController.text).trim();
    if (text.isEmpty) return;
    if (textToSend == null) {
      _textController.clear();
    }
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _showVoiceInputDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _VoiceInputModal(
        onPromptSelected: (prompt) {
          Navigator.of(ctx).pop();
          _handleSend(prompt);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isDark = AppColors.isDark(context);
    final currentUser = ref.watch(authStateProvider).value;
    final isOrganizer =
        widget.isOrganizerMode || (currentUser?.isOrganizer ?? false);

    // Auto-scroll when messages change or typing state changes
    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isTyping != next.isTyping) {
        _scrollToBottom();
      }
    });

    final bgColor = isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF9FAFB);
    final appBarBg = isDark ? const Color(0xFF121215) : Colors.white;
    final inputBg = isDark ? const Color(0xFF18181C) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF282830) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: isOrganizer
                        ? const LinearGradient(
                            colors: [Color(0xFFFF5722), Color(0xFFFF9800)])
                        : AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isOrganizer ? Colors.orange : AppColors.primary)
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isOrganizer
                        ? Icons.bolt_rounded
                        : Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: appBarBg,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          isOrganizer
                              ? "Organizer AI Copilot"
                              : "EMS AI Concierge",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOrganizer) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.amber.shade700, width: 0.8),
                          ),
                          child: Text(
                            'COPILOT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    isOrganizer
                        ? "MCP Privileges Active ⚡ • Live"
                        : "Online • Powered by AI",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Clear Chat",
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemCount:
                  chatState.messages.length + (chatState.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < chatState.messages.length) {
                  final msg = chatState.messages[index];
                  return ChatBubble(
                    message: msg,
                    onSuggestedActionTapped: (reply) {
                      _handleSend(reply);
                    },
                  );
                } else {
                  return _buildTypingIndicator(isDark);
                }
              },
            ),
          ),

          // ── Organizer Quick Prompts Bar (When chat is empty) ──────────────
          if (isOrganizer && chatState.messages.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPromptChip(
                      icon: Icons.mic_rounded,
                      label: "Create Tech Leaders Summit 2026",
                      onTap: () => _handleSend(
                          "Create a new draft event titled 'Tech Leaders Summit 2026' in Bangalore at Whitefield Convention Center with VIP tickets at 2999 INR"),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPromptChip(
                      icon: Icons.analytics_outlined,
                      label: "Show My Monthly Revenue",
                      onTap: () =>
                          _handleSend("Show my total revenue for this month"),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPromptChip(
                      icon: Icons.people_outline_rounded,
                      label: "Event Attendee Check-ins",
                      onTap: () =>
                          _handleSend("Inspect event attendee check-in list"),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPromptChip(
                      icon: Icons.rocket_launch_outlined,
                      label: "Publish Draft Event",
                      onTap: () =>
                          _handleSend("Publish event evt_draft_9918"),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

          // Message Input Bar
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Voice Mic Button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isOrganizer
                                  ? Colors.orange.shade800
                                  : AppColors.primary)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          color: isOrganizer
                              ? Colors.orange.shade800
                              : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      tooltip: "Voice-to-Event Assistant",
                      onPressed: () => _showVoiceInputDialog(context, isDark),
                    ),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 110),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E24)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2E2E38)
                                : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 4,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color:
                                isDark ? Colors.white : const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: isOrganizer
                                ? "Manage events, revenue, drafts..."
                                : "Ask about events, packages...",
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF71717A)
                                  : const Color(0xFF9CA3AF),
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _textController,
                        builder: (context, value, _) {
                          final hasText = value.text.trim().isNotEmpty;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleSend,
                              borderRadius: BorderRadius.circular(22),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: hasText ? AppColors.primaryGradient : null,
                                  color: hasText
                                      ? null
                                      : (isDark
                                          ? const Color(0xFF26262C)
                                          : const Color(0xFFE2E8F0)),
                                  shape: BoxShape.circle,
                                  boxShadow: hasText
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.38),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.send_rounded,
                                  color: hasText
                                      ? Colors.white
                                      : (isDark
                                          ? const Color(0xFF52525B)
                                          : const Color(0xFF94A3B8)),
                                  size: 19,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1E24) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2C2F3A) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.orange.shade800),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey.shade200 : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 12, right: 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161618) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF28282C) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 200),
                const SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// ── Voice-to-Event Modal ─────────────────────────────────────────────────────

class _VoiceInputModal extends StatefulWidget {
  final ValueChanged<String> onPromptSelected;

  const _VoiceInputModal({required this.onPromptSelected});

  @override
  State<_VoiceInputModal> createState() => _VoiceInputModalState();
}

class _VoiceInputModalState extends State<_VoiceInputModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final samplePrompts = [
      "Create a comedy show in Mumbai for next Friday with 500 Rs tickets",
      "Create a new draft event titled 'Tech Leaders Summit 2026' in Bangalore with VIP tickets at 2999 INR",
      "Show my total revenue for this month",
      "Inspect event attendee check-in list",
      "Publish event evt_draft_9918",
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14161B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle pill
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Pulsing Mic Circle
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.45),
                          blurRadius: 20 * _pulseAnimation.value,
                          spreadRadius: 2 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            Text(
              "Listening for Organizer AI Prompt...",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Speak or tap one of the voice workflow commands below:",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),

            // Suggested Voice Commands List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: samplePrompts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final prompt = samplePrompts[index];
                  return InkWell(
                    onTap: () => widget.onPromptSelected(prompt),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.mic_none_rounded,
                              size: 16, color: Colors.orange.shade800),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '"$prompt"',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 12, color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
