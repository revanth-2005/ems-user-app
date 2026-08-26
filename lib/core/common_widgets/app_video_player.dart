import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../constants/app_colors.dart';
import 'app_network_image.dart';

/// Shows a sleek, fullscreen video player dialog for playing promotional reels/videos.
void showAppVideoPlayerDialog(
  BuildContext context,
  String videoUrl, {
  String? title,
  String? caption,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (_) => _AppVideoPlayerDialog(
      videoUrl: videoUrl,
      title: title,
      caption: caption,
    ),
  );
}

class _AppVideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? caption;

  const _AppVideoPlayerDialog({
    required this.videoUrl,
    this.title,
    this.caption,
  });

  @override
  State<_AppVideoPlayerDialog> createState() => _AppVideoPlayerDialogState();
}

class _AppVideoPlayerDialogState extends State<_AppVideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _hasError = false;
      _isInitialized = false;
      _errorMessage = '';
    });

    final normalized = AppNetworkImage.normalizeUrl(widget.videoUrl);
    if (normalized == null || normalized.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid video URL';
      });
      return;
    }

    try {
      final uri = Uri.parse(normalized);
      _controller = VideoPlayerController.networkUrl(uri);

      await _controller!.initialize();
      _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        String message = 'Unable to stream this video.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('404') ||
            errStr.contains('source error') ||
            errStr.contains('nosuchkey')) {
          message =
              'This video file is unavailable or missing from the media server (404).';
        } else if (errStr.contains('connection') ||
            errStr.contains('failed to connect') ||
            errStr.contains('refused') ||
            errStr.contains('socket')) {
          message =
              'Could not connect to media server. Ensure media service & port 6006 are running.';
        } else if (errStr.contains('channel-error') ||
            errStr.contains('pigeon')) {
          message =
              'Restart the app process (flutter run) to compile the native video player plugin.';
        } else {
          message = 'Failed to load video: $e';
        }

        setState(() {
          _hasError = true;
          _errorMessage = message;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
      } else {
        _controller!.play();
        _showControls = false;
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0D15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header Bar ───────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: AppColors.accentRose,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title ?? 'Video Preview',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── Video Player Area ─────────────────────────────────────────
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 220,
                  maxHeight: 460,
                ),
                child: AspectRatio(
                  aspectRatio: _isInitialized && _controller != null
                      ? _controller!.value.aspectRatio
                      : 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isInitialized && _controller != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showControls = !_showControls;
                              });
                            },
                            child: VideoPlayer(_controller!),
                          ),

                        // Loading State
                        if (!_isInitialized && !_hasError)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Loading video…',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                        // Error State
                        if (_hasError)
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.accentRose,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Unable to play video',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _errorMessage.contains('channel-error') ||
                                          _errorMessage.contains('pigeon')
                                      ? 'Restart the app process (run flutter run) to compile the native video player plugin.'
                                      : _errorMessage,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: _initializePlayer,
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 14),
                                  label: const Text('Retry',
                                      style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Play/Pause Center Button Overlay
                        if (_isInitialized && (_showControls || !_controller!.value.isPlaying))
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _controller!.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Video Controls Bottom Bar ─────────────────────────────────
              if (_isInitialized && _controller != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: AppColors.primary,
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white10,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      const SizedBox(height: 6),
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _controller!,
                        builder: (ctx, val, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(val.position),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatDuration(val.duration),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

              // Caption Footer (if any)
              if (widget.caption != null && widget.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    widget.caption!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An inline video player widget built for hero headers, media carousels, and inline cards.
class AppInlineVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? caption;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final BoxFit fit;
  final VoidCallback? onExpandFullscreen;

  const AppInlineVideoPlayer({
    super.key,
    required this.videoUrl,
    this.title,
    this.caption,
    this.autoPlay = true,
    this.looping = true,
    this.muted = false,
    this.fit = BoxFit.cover,
    this.onExpandFullscreen,
  });

  @override
  State<AppInlineVideoPlayer> createState() => _AppInlineVideoPlayerState();
}

class _AppInlineVideoPlayerState extends State<AppInlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  late bool _isMuted;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.muted;
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant AppInlineVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _hasError = false;
      _isInitialized = false;
      _errorMessage = '';
    });

    final normalized = AppNetworkImage.normalizeUrl(widget.videoUrl);
    if (normalized == null || normalized.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid video URL';
      });
      return;
    }

    try {
      final uri = Uri.parse(normalized);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();
      _controller!.setLooping(widget.looping);
      if (_isMuted) {
        await _controller!.setVolume(0.0);
      }
      if (widget.autoPlay) {
        await _controller!.play();
      }
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
      } else {
        _controller!.play();
        _showControls = false;
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          if (_isInitialized && _controller != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: Center(
                child: FittedBox(
                  fit: widget.fit,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width > 0
                        ? _controller!.value.size.width
                        : 16,
                    height: _controller!.value.size.height > 0
                        ? _controller!.value.size.height
                        : 9,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            ),

          // Loading indicator
          if (!_isInitialized && !_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading video…',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Error state
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.accentRose, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    'Unable to play video in header',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white60, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _initializePlayer,
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Retry', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    ),
                  )
                ],
              ),
            ),

          // Top badge: "VIDEO PREVIEW"
          if (_isInitialized)
            Positioned(
              top: 16,
              left: 64, // Keep clearance for back button
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accentRose,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VIDEO PREVIEW',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Floating Center Play/Pause button
          if (_isInitialized &&
              (_showControls || !_controller!.value.isPlaying))
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Icon(
                    _controller!.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),

          // Floating Action Buttons (Mute & Fullscreen Showcase)
          if (_isInitialized)
            Positioned(
              bottom: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mute/Unmute
                  GestureDetector(
                    onTap: _toggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Icon(
                        _isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Fullscreen Lightbox / Showcase Button
                  if (widget.onExpandFullscreen != null)
                    GestureDetector(
                      onTap: widget.onExpandFullscreen,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fullscreen_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Showcase',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Subtle Bottom Progress Bar
          if (_isInitialized && _controller != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.transparent,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}

/// A performant, dynamic video thumbnail widget that loads and displays
/// the exact first frame of any remote video URL.
class AppVideoThumbnail extends StatefulWidget {
  final String videoUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool showPlayOverlay;
  final String? categoryHint;
  final String? titleHint;

  const AppVideoThumbnail({
    super.key,
    required this.videoUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.showPlayOverlay = true,
    this.categoryHint,
    this.titleHint,
  });

  @override
  State<AppVideoThumbnail> createState() => _AppVideoThumbnailState();
}

class _AppVideoThumbnailState extends State<AppVideoThumbnail> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFirstFrame();
  }

  @override
  void didUpdateWidget(covariant AppVideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _hasError = false;
      _loadFirstFrame();
    }
  }

  Future<void> _loadFirstFrame() async {
    final normalized = AppNetworkImage.normalizeUrl(widget.videoUrl);
    if (normalized == null || normalized.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      final uri = Uri.parse(normalized);
      final ctrl = VideoPlayerController.networkUrl(uri);
      _controller = ctrl;
      await ctrl.initialize();
      await ctrl.pause();
      await ctrl.setVolume(0.0);
      if (mounted && _controller == ctrl) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isInitialized && _controller != null) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller!.value.size.width > 0
                  ? _controller!.value.size.width
                  : 160,
              height: _controller!.value.size.height > 0
                  ? _controller!.value.size.height
                  : 90,
              child: VideoPlayer(_controller!),
            ),
          ),
          if (widget.showPlayOverlay) ...[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      );
    } else if (_hasError) {
      content = Container(
        color: const Color(0xFF1A1A24),
        child: Center(
          child: Icon(
            Icons.videocam_off_rounded,
            color: Colors.white.withValues(alpha: 0.4),
            size: 24,
          ),
        ),
      );
    } else {
      // Loading placeholder
      content = Container(
        color: const Color(0xFF14141E),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }

    if (widget.borderRadius > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: content,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: content,
    );
  }
}


