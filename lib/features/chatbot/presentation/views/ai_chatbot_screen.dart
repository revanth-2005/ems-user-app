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
    _focusNode.addListener(_handleFocusChange);
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatProvider.notifier).sendMessage(widget.initialPrompt!);
      });
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
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

  void _showQuickToolsModal(
      BuildContext context, bool isOrganizer, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bg = isDark ? const Color(0xFF17171C) : Colors.white;
        final border =
            isDark ? const Color(0xFF282832) : const Color(0xFFE5E7EB);
        final textColor = isDark ? Colors.white : const Color(0xFF111827);

        final tools = isOrganizer
            ? [
                {
                  'icon': Icons.rocket_launch_rounded,
                  'title': 'Create Event Draft',
                  'desc': 'Draft a new event with AI & MCP tools',
                  'prompt':
                      'Create a new draft event titled "Tech Leaders Summit 2026" in Bangalore at Whitefield Convention Center with VIP tickets at 2999 INR',
                },
                {
                  'icon': Icons.analytics_outlined,
                  'title': 'Monthly Revenue & GMV',
                  'desc': 'Inspect your ticket sales & earnings',
                  'prompt': 'Show my total revenue for this month',
                },
                {
                  'icon': Icons.people_outline_rounded,
                  'title': 'Attendee Check-in Roster',
                  'desc': 'Verify attendee passes & QR statuses',
                  'prompt': 'Inspect event attendee check-in list',
                },
                {
                  'icon': Icons.publish_rounded,
                  'title': 'Publish Live Event',
                  'desc': 'Publish draft event to public discovery',
                  'prompt': 'Publish event',
                },
              ]
            : [
                {
                  'icon': Icons.celebration_outlined,
                  'title': 'Wedding & Luxury Packages',
                  'desc': 'Find curated packages in your city',
                  'prompt': 'Find wedding packages in Mumbai',
                },
                {
                  'icon': Icons.music_note_rounded,
                  'title': 'Live Concerts & Festivals',
                  'desc': 'Explore trending music events',
                  'prompt': 'Show upcoming music concerts in Mumbai',
                },
                {
                  'icon': Icons.shopping_bag_outlined,
                  'title': 'Cart Summary',
                  'desc': 'Review active packages & deposits',
                  'prompt': 'Show my cart',
                },
                {
                  'icon': Icons.confirmation_number_outlined,
                  'title': 'My Event Tickets',
                  'desc': 'View digital QR passes & registrations',
                  'prompt': 'Where are my tickets?',
                },
              ];

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      isOrganizer
                          ? Icons.bolt_rounded
                          : Icons.auto_awesome_rounded,
                      color: isOrganizer
                          ? Colors.orange.shade800
                          : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOrganizer
                          ? 'Organizer Copilot Tools'
                          : 'TrueGather AI Quick Actions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...tools.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isDark
                          ? const Color(0xFF202026)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _handleSend(item['prompt'] as String);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (isOrganizer
                                          ? Colors.orange
                                          : AppColors.primary)
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  size: 18,
                                  color: isOrganizer
                                      ? Colors.orange.shade800
                                      : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      item['desc'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isDark = AppColors.isDark(context);
    final currentUser = ref.watch(authStateProvider).value;
    final isOrganizer =
        widget.isOrganizerMode || (currentUser?.isOrganizer ?? false);

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 50;
    final showSuggestionsAboveInput =
        isKeyboardOpen && chatState.messages.isEmpty;
    final suggestions = _getActiveSuggestions(chatState, isOrganizer);

    final rawName = currentUser?.name.trim() ?? '';
    String greetingName = '';
    if (rawName.isNotEmpty) {
      final first = rawName.split(RegExp(r'\s+')).first;
      if (first.isNotEmpty) {
        greetingName = '${first[0].toUpperCase()}${first.substring(1)}';
      }
    }
    final centerGreeting = greetingName.isNotEmpty
        ? 'Glad to see you, $greetingName'
        : 'Glad to see you';

    // Auto-scroll when messages change or typing state changes
    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isTyping != next.isTyping) {
        _scrollToBottom();
      }
    });

    final bgColor = isDark ? const Color(0xFF0F0F12) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181E) : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          isOrganizer ? "Organizer Copilot" : "TrueGather AI",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF18181E)
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.add_rounded,
                    size: 22,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                  tooltip: "New Chat",
                  onPressed: () {
                    ref.read(chatProvider.notifier).clearChat();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Message List or Center Greeting for New Chat
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: chatState.messages.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: showSuggestionsAboveInput ? 240 : 60,
                                  left: 28,
                                  right: 28,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      centerGreeting,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                    if (!isKeyboardOpen) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        isOrganizer
                                            ? 'Hello! I am your Organizer Copilot. How can I help you manage your events today?'
                                            : 'Hello! I am your TrueGather AI Assistant. How can I help you plan your event today?',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF64748B),
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 110),
                      itemCount: chatState.messages.length +
                          (chatState.isTyping ? 1 : 0),
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
          ),

          // 2. Floating Bottom Input Capsule & Active Suggestions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Suggestions & Greeting (shown ONLY when keyboard opens)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    firstCurve: Curves.easeOutCubic,
                    secondCurve: Curves.easeInCubic,
                    crossFadeState: (showSuggestionsAboveInput &&
                            suggestions.isNotEmpty)
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                      firstChild: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: Text(
                              isOrganizer
                                  ? 'Hello! I am your Organizer Copilot. How can I help you manage your events today?'
                                  : 'Hello! I am your TrueGather AI Assistant. How can I help you plan your event today?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                                height: 1.45,
                              ),
                            ),
                          ),
                          _buildActiveSuggestionsList(suggestions, isDark),
                          const SizedBox(height: 4),
                        ],
                      ),
                    secondChild:
                        const SizedBox(width: double.infinity, height: 0),
                  ),

                  // Floating Bottom Input Capsule
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 54, maxHeight: 130),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A20) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C2C36)
                          : const Color(0xFFE5E7EB),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // + Button
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.add_rounded,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF374151),
                            size: 26,
                          ),
                          tooltip: "Quick Tools & Prompts",
                          onPressed: () => _showQuickToolsModal(
                              context, isOrganizer, isDark),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Text Field
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          textAlignVertical: TextAlignVertical.center,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 5,
                          cursorColor: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                          cursorWidth: 2.0,
                          cursorHeight: 20.0,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: isOrganizer
                                ? "Ask Organizer Copilot"
                                : "Ask TrueGather AI",
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? const Color(0xFF71717A)
                                  : const Color(0xFF9CA3AF),
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Voice Mic Button
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.mic_none_rounded,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF374151),
                            size: 23,
                          ),
                          tooltip: "Voice Assistant",
                          onPressed: () =>
                              _showVoiceInputDialog(context, isDark),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Send Up-Arrow Circular Button
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _textController,
                        builder: (context, value, _) {
                          final hasText = value.text.trim().isNotEmpty;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasText
                                  ? (isOrganizer
                                      ? const Color(0xFFFF5722)
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF111827)))
                                  : (isDark
                                      ? const Color(0xFF2A2A34)
                                      : const Color(0xFFE5E7EB)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: hasText ? _handleSend : null,
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 20,
                                    color: hasText
                                        ? (isOrganizer
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.black
                                                : Colors.white))
                                        : (isDark
                                            ? const Color(0xFF555562)
                                            : const Color(0xFF9CA3AF)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
}

  List<String> _getActiveSuggestions(ChatState chatState, bool isOrganizer) {
    if (chatState.messages.isNotEmpty) {
      return const [];
    }
    return isOrganizer
        ? const [
            '➕ Create Event Draft',
            '📊 Monthly Revenue',
            '📋 Attendee Check-ins',
            '🚀 Publish Event',
          ]
        : const [
            '🎉 Find Wedding Packages',
            '📍 Catering in Mumbai',
            '🛒 View My Cart',
            '🎫 My Event Tickets',
          ];
  }

  Widget _buildActiveSuggestionsList(List<String> suggestions, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: suggestions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleSend(action),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          action,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF374151),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 18, right: 36),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypingDot(delay: 0),
          const SizedBox(width: 5),
          _TypingDot(delay: 200),
          const SizedBox(width: 5),
          _TypingDot(delay: 400),
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
