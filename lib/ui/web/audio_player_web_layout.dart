import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:sint/sint.dart';

import 'package:neom_audio_player/ui/player/miniplayer_controller.dart';

import 'web_keyboard_shortcuts.dart';
import 'widgets/web_bottom_player.dart';
import 'widgets/web_now_playing_full.dart';
import 'widgets/web_queue_panel.dart';

/// Spotify-style 3-column responsive layout for Flutter Web.
///
/// This layout owns the **transport** and the **chrome** of the web
/// experience — the bottom player, the full-screen now playing view, the
/// queue panel and the keyboard shortcuts. It does **not** know how to
/// render the home feed, the search feed, the playlist detail, the sidebar
/// library or the jam session panel — those views live in
/// `neom_audio_platform` (the streaming layer that depends on Firestore,
/// recommendations and listening stats).
///
/// To wire the platform views in, pass the corresponding builder
/// callbacks. Any builder left as `null` falls back to a placeholder card
/// explaining how to plug it in. This keeps `neom_audio_player` usable on
/// its own while letting the platform layer enrich it without
/// modification.
///
/// ```dart
/// AudioPlayerWebLayout(
///   mainFeedBuilder: (ctx, onPlaylistSelected) =>
///       WebMainFeed(onPlaylistSelected: onPlaylistSelected),
///   searchFeedBuilder: (ctx, onPlaylistSelected) =>
///       WebSearchFeed(onPlaylistSelected: onPlaylistSelected),
///   sidebarLibraryBuilder: (ctx, onLibraryTap, onPlaylistSelected, collapsed) =>
///       WebSidebarLibrary(
///         onLibraryTap: onLibraryTap,
///         onPlaylistSelected: onPlaylistSelected,
///         collapsed: collapsed,
///       ),
///   playlistDetailBuilder: (ctx, itemlist, onBack) =>
///       WebPlaylistDetail(itemlist: itemlist, onBack: onBack),
///   jamSessionPanelBuilder: (ctx, onBack, onLeave) =>
///       WebJamSessionPanel(onBack: onBack, onLeave: onLeave),
/// );
/// ```
///
/// Use this only on Flutter Web. On mobile, `AudioPlayerRootPage` picks the
/// mobile player automatically via `kIsWeb`.
class AudioPlayerWebLayout extends StatefulWidget {
  final Widget? secondaryPage;

  /// Optional navigation sidebar from the host app (e.g. Home's LeftSidebar)
  /// to maintain consistent navigation across the app. If null, uses the
  /// built-in collapsible audio-player sidebar (when [sidebarLibraryBuilder]
  /// is provided).
  final Widget Function({required bool expanded})? navigationSidebar;

  /// Builds the home feed (recommended playlists, top played, radio,
  /// etc.). Provided by `neom_audio_platform`'s `WebMainFeed`.
  final Widget Function(
    BuildContext context,
    void Function(Itemlist) onPlaylistSelected,
  )? mainFeedBuilder;

  /// Builds the search feed. Provided by `neom_audio_platform`'s
  /// `WebSearchFeed`.
  final Widget Function(
    BuildContext context,
    void Function(Itemlist) onPlaylistSelected,
  )? searchFeedBuilder;

  /// Builds the left sidebar's library section (playlists, follows, etc.).
  /// Provided by `neom_audio_platform`'s `WebSidebarLibrary`.
  final Widget Function(
    BuildContext context,
    VoidCallback onLibraryTap,
    void Function(Itemlist) onPlaylistSelected,
    bool collapsed,
  )? sidebarLibraryBuilder;

  /// Builds the detail view for a selected playlist. Provided by
  /// `neom_audio_platform`'s `WebPlaylistDetail`.
  final Widget Function(
    BuildContext context,
    Itemlist itemlist,
    VoidCallback onBack,
  )? playlistDetailBuilder;

  /// Builds the collaborative jam session panel. Provided by
  /// `neom_audio_platform`'s `WebJamSessionPanel`.
  final Widget Function(
    BuildContext context,
    VoidCallback onBack,
    VoidCallback onLeave,
  )? jamSessionPanelBuilder;

  const AudioPlayerWebLayout({
    super.key,
    this.secondaryPage,
    this.navigationSidebar,
    this.mainFeedBuilder,
    this.searchFeedBuilder,
    this.sidebarLibraryBuilder,
    this.playlistDetailBuilder,
    this.jamSessionPanelBuilder,
  });

  @override
  State<AudioPlayerWebLayout> createState() => _AudioPlayerWebLayoutState();
}

class _AudioPlayerWebLayoutState extends State<AudioPlayerWebLayout> {
  // 0: Home, 1: Search, 2: Library/Secondary, 3: Playlist Detail, 4: Jam Session, 5: Full Now Playing
  int _selectedIndex = 0;
  Itemlist? _selectedItemlist;
  bool _showQueue = false;

  void _onMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 3 && index != 4) _selectedItemlist = null;
    });
  }

  void _onPlaylistSelected(Itemlist itemlist) {
    setState(() {
      _selectedItemlist = itemlist;
      _selectedIndex = 3;
    });
  }

  void _toggleQueue() {
    setState(() => _showQueue = !_showQueue);
  }

  /// Placeholder shown when a builder for a platform-only view was not
  /// supplied. Tells the developer how to wire it up.
  Widget _platformPlaceholder(String viewName) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColor.appBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.extension_rounded, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              '$viewName not connected',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add `neom_audio_platform` to your app and pass the corresponding '
              'builder to `AudioPlayerWebLayout` to enable this view.',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPanel() {
    final Widget child;
    switch (_selectedIndex) {
      case 0:
        child = widget.mainFeedBuilder?.call(context, _onPlaylistSelected)
            ?? _platformPlaceholder('Home feed');
      case 1:
        child = widget.searchFeedBuilder?.call(context, _onPlaylistSelected)
            ?? _platformPlaceholder('Search');
      case 2:
        child = widget.secondaryPage ?? Center(
          child: Text(
            AppTranslationConstants.playlists.tr,
            style: const TextStyle(color: Colors.white),
          ),
        );
      case 3:
        if (_selectedItemlist != null && widget.playlistDetailBuilder != null) {
          child = widget.playlistDetailBuilder!(
            context,
            _selectedItemlist!,
            () => _onMenuSelected(0),
          );
        } else if (widget.mainFeedBuilder != null) {
          child = widget.mainFeedBuilder!(context, _onPlaylistSelected);
        } else {
          child = _platformPlaceholder('Playlist detail');
        }
      case 4:
        child = widget.jamSessionPanelBuilder?.call(
              context,
              () => _onMenuSelected(0),
              () => _onMenuSelected(0),
            ) ?? _platformPlaceholder('Jam session');
      case 5:
        child = WebNowPlayingFull(
          onClose: () => _onMenuSelected(0),
          onToggleQueue: _toggleQueue,
        );
      default:
        child = widget.mainFeedBuilder?.call(context, _onPlaylistSelected)
            ?? _platformPlaceholder('Home feed');
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey<int>(_selectedIndex),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarCollapsed = screenWidth < 1200;
    final sidebarWidth = sidebarCollapsed ? 72.0 : 280.0;

    return Shortcuts(
      shortcuts: webKeyboardShortcuts,
      child: Actions(
        actions: buildWebKeyboardActions(onToggleQueue: _toggleQueue),
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: AppFlavour.getBackgroundColor(),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Sidebar ───
                          if (widget.navigationSidebar != null)
                            widget.navigationSidebar!(expanded: !sidebarCollapsed)
                          else
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: sidebarWidth,
                              margin: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColor.appBlack,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        _SidebarItem(
                                          icon: Icons.home_filled,
                                          label: AppTranslationConstants.home.tr,
                                          isSelected: _selectedIndex == 0,
                                          onTap: () => _onMenuSelected(0),
                                          collapsed: sidebarCollapsed,
                                        ),
                                        _SidebarItem(
                                          icon: Icons.search,
                                          label: AppTranslationConstants.search.tr,
                                          isSelected: _selectedIndex == 1,
                                          onTap: () => _onMenuSelected(1),
                                          collapsed: sidebarCollapsed,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColor.appBlack,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: widget.sidebarLibraryBuilder?.call(
                                            context,
                                            () => _onMenuSelected(2),
                                            _onPlaylistSelected,
                                            sidebarCollapsed,
                                          ) ??
                                          _platformPlaceholder('Sidebar library'),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ─── Center Panel ───
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: AppColor.surfaceDim,
                                gradient: _selectedIndex == 0
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [AppColor.scaffold, AppColor.surfaceDim],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildCenterPanel(),
                              ),
                            ),
                          ),

                          // ─── Queue Panel (right side, toggleable) ───
                          if (_showQueue)
                            Container(
                              width: 320,
                              margin: const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
                              child: WebQueuePanel(
                                onClose: () => setState(() => _showQueue = false),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ─── Bottom Player ───
                    Obx(() {
                      final miniPlayerController = Sint.find<MiniPlayerController>();
                      if (miniPlayerController.mediaItem.value == null || miniPlayerController.isWebPlayerClosed.value) {
                        return const SizedBox.shrink();
                      }
                      return WebBottomPlayer(
                        onQueueToggle: _toggleQueue,
                        onArtworkTap: () => _onMenuSelected(5),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool collapsed;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.collapsed = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? Colors.white
        : (isHovered ? Colors.white : Colors.grey[400]!);

    return Tooltip(
      message: widget.collapsed ? widget.label : '',
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 24,
              vertical: 12,
            ),
            color: Colors.transparent,
            child: widget.collapsed
                ? Center(child: Icon(widget.icon, color: color, size: 28))
                : Row(
                    children: [
                      Icon(widget.icon, color: color, size: 28),
                      const SizedBox(width: 16),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: color,
                          fontWeight: widget.isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
