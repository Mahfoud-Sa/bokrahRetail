import 'package:bokrah_retail/app/config/theme.dart';
import 'package:flutter/material.dart';

class SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasArrow;
  final bool isExpanded;
  final Color? color;
  final Widget? trailing;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.hasArrow = false,
    this.isExpanded = false,
    this.color,
    this.trailing,
  });

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Approved Bokra Retail Sidebar Specifications:
    // Background: #243B70 (Deep Cobalt)
    // Navigation text: White
    // Selected navigation: Action Blue (#315FC7) with active indicator
    // Icons: White or contrasting blue-white tones
    // Hover: Subtle lighter cobalt surface
    final isSelected = widget.isSelected;
    final itemTextColor = widget.color ??
        (isSelected
            ? AppTheme.sidebarText
            : Colors.white.withValues(alpha: 0.90));
    final iconColor = widget.color ??
        (isSelected
            ? AppTheme.sidebarIcon
            : Colors.white.withValues(alpha: 0.85));

    final backgroundColor = isSelected
        ? AppTheme.actionBlue
        : (_isHovered ? AppTheme.sidebarHover : Colors.transparent);

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.onTap,
            hoverColor: Colors.transparent,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                // Subtle active indicator on the leading edge when selected
                border: isSelected
                    ? Border(
                        left: !isRtl
                            ? const BorderSide(
                                color: AppTheme.warmOrange,
                                width: 3.5,
                              )
                            : BorderSide.none,
                        right: isRtl
                            ? const BorderSide(
                                color: AppTheme.warmOrange,
                                width: 3.5,
                              )
                            : BorderSide.none,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: itemTextColor,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 8),
                    widget.trailing!,
                  ],
                  if (widget.hasArrow) ...[
                    const SizedBox(width: 8),
                    Icon(
                      widget.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.70),
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
