import 'package:flutter/material.dart';
import 'package:medicare_app/theme/app_theme.dart';

class PanelDestination {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;

  const PanelDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}

/// Shared responsive workspace for patient, doctor, and admin panels.
/// The shell owns the single global refresh and sign-out actions.
class PanelShell extends StatefulWidget {
  final int currentIndex;
  final List<PanelDestination> destinations;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  const PanelShell({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.pages,
    required this.onDestinationSelected,
    required this.onRefresh,
    required this.onLogout,
  }) : assert(destinations.length == pages.length),
       assert(destinations.length > 0);

  @override
  State<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends State<PanelShell> {
  bool _isRefreshing = false;
  bool _isSigningOut = false;

  bool get _usesMoreMenu => widget.destinations.length > 5;

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _confirmLogout() async {
    if (_isSigningOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out of MediCare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);
    try {
      await widget.onLogout();
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppTheme.tabletBreakpoint;
        final isDesktop = constraints.maxWidth >= AppTheme.desktopBreakpoint;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            leading: const Icon(
              Icons.health_and_safety_rounded,
              color: AppTheme.primary,
            ),
            title: const Text('MediCare'),
            actions: [
              IconButton(
                tooltip: 'Refresh current section',
                onPressed: _isRefreshing ? null : _refresh,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: _isSigningOut ? null : _confirmLogout,
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (isDesktop)
                _buildDesktopSidebar()
              else if (!isMobile)
                _buildTabletRail(),
              Expanded(
                child: IndexedStack(
                  index: widget.currentIndex,
                  children: widget.pages,
                ),
              ),
            ],
          ),
          bottomNavigationBar: isMobile
              ? _buildMobileNavigation(context)
              : null,
        );
      },
    );
  }

  Widget _buildDesktopSidebar() {
    return Material(
      color: AppTheme.surface,
      child: SizedBox(
        width: 250,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 26, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'WORKSPACE',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: widget.destinations.length,
                  itemBuilder: (context, index) => _buildNavigationTile(index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTile(int index) {
    final destination = widget.destinations[index];
    final selected = widget.currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: AppTheme.primary.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          selected
              ? (destination.selectedIcon ?? destination.icon)
              : destination.icon,
          color: selected ? AppTheme.primary : AppTheme.textSecondary,
        ),
        title: Text(
          destination.label,
          style: TextStyle(
            color: selected ? AppTheme.primary : AppTheme.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () => widget.onDestinationSelected(index),
      ),
    );
  }

  Widget _buildTabletRail() {
    return Container(
      color: AppTheme.surface,
      child: NavigationRail(
        selectedIndex: widget.currentIndex,
        onDestinationSelected: widget.onDestinationSelected,
        labelType: NavigationRailLabelType.all,
        backgroundColor: AppTheme.surface,
        destinations: widget.destinations
            .map(
              (destination) => NavigationRailDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(
                  destination.selectedIcon ?? destination.icon,
                ),
                label: Text(destination.label),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    final visibleDestinations = _usesMoreMenu
        ? <NavigationDestination>[
            ...widget.destinations.take(3).map(_toNavigationDestination),
            const NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              selectedIcon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
          ]
        : widget.destinations.map(_toNavigationDestination).toList();

    return NavigationBar(
      selectedIndex: _usesMoreMenu && widget.currentIndex >= 3
          ? 3
          : widget.currentIndex,
      onDestinationSelected: (index) {
        if (_usesMoreMenu && index == 3) {
          _showMoreDestinations(context);
        } else {
          widget.onDestinationSelected(index);
        }
      },
      destinations: visibleDestinations,
    );
  }

  NavigationDestination _toNavigationDestination(PanelDestination destination) {
    return NavigationDestination(
      icon: Icon(destination.icon),
      selectedIcon: Icon(destination.selectedIcon ?? destination.icon),
      label: destination.label,
    );
  }

  Future<void> _showMoreDestinations(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 3; index < widget.destinations.length; index++)
                ListTile(
                  leading: Icon(
                    widget.destinations[index].icon,
                    color: widget.currentIndex == index
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                  title: Text(widget.destinations[index].label),
                  selected: widget.currentIndex == index,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    widget.onDestinationSelected(index);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
