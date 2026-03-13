import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:sint/sint.dart';
import 'package:neom_audio_player/ui/player/miniplayer_controller.dart';
import 'widgets/web_sidebar_library.dart';
import 'widgets/web_main_feed.dart';
import 'widgets/web_bottom_player.dart';
import 'widgets/web_playlist_detail.dart';
import 'widgets/web_queue_panel.dart';
import 'widgets/web_now_playing_full.dart';
import 'widgets/web_jam_session_panel.dart';
import 'widgets/web_search_feed.dart';
import 'web_keyboard_shortcuts.dart';

class AudioPlayerWebLayout extends StatefulWidget {
  final Widget? secondaryPage;

  const AudioPlayerWebLayout({Key? key, this.secondaryPage}) : super(key: key);

  @override
  State<AudioPlayerWebLayout> createState() => _AudioPlayerWebLayoutState();
}

class _AudioPlayerWebLayoutState extends State<AudioPlayerWebLayout> {
  // 0: Home, 1: Search, 2: Library/Secondary, 3: Playlist Detail, 4: Jam Session
  int _selectedIndex = 0;
  Itemlist? _selectedItemlist;
  bool _showQueue = false;
  bool _showFullNowPlaying = false;

  void _onMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 3 && index != 4) _selectedItemlist = null;
    });
  }

  void _openJamSession() {
    setState(() => _selectedIndex = 4);
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

  Widget _buildCenterPanel() {
    final Widget child;
    switch (_selectedIndex) {
      case 0:
        child = WebMainFeed(onPlaylistSelected: _onPlaylistSelected);
      case 1:
        child = WebSearchFeed(onPlaylistSelected: _onPlaylistSelected);
      case 2:
        child = widget.secondaryPage ?? Center(
          child: Text(
            AppTranslationConstants.playlists.tr,
            style: const TextStyle(color: Colors.white),
          ),
        );
      case 3:
        child = _selectedItemlist != null
            ? WebPlaylistDetail(
                itemlist: _selectedItemlist!,
                onBack: () => _onMenuSelected(0),
              )
            : WebMainFeed(onPlaylistSelected: _onPlaylistSelected);
      case 4:
        child = WebJamSessionPanel(
          onBack: () => _onMenuSelected(0),
          onLeave: () => _onMenuSelected(0),
        );
      default:
        child = WebMainFeed(onPlaylistSelected: _onPlaylistSelected);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
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
                // Main content
                Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Sidebar ───
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: sidebarWidth,
                            margin: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                            child: Column(
                              children: [
                                // Top block: Home / Search
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
                                // Bottom block: Library
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColor.appBlack,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: WebSidebarLibrary(
                                      onLibraryTap: () => _onMenuSelected(2),
                                      onPlaylistSelected: _onPlaylistSelected,
                                      collapsed: sidebarCollapsed,
                                    ),
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
                                color: AppColor.appBlack,
                                gradient: _selectedIndex == 0
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [AppColor.getMain(), AppColor.appBlack],
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
                      if (miniPlayerController.mediaItem.value == null) {
                        return const SizedBox.shrink();
                      }
                      return WebBottomPlayer(
                        onQueueToggle: _toggleQueue,
                        onArtworkTap: () => setState(() => _showFullNowPlaying = true),
                      );
                    }),
                  ],
                ),

                // ─── Full-screen Now Playing overlay ───
                if (_showFullNowPlaying)
                  WebNowPlayingFull(
                    onClose: () => setState(() => _showFullNowPlaying = false),
                    onToggleQueue: _toggleQueue,
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
  __SidebarItemState createState() => __SidebarItemState();
}

class __SidebarItemState extends State<_SidebarItem> {
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

