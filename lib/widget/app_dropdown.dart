import 'package:flutter/material.dart';

/// A beautiful custom dropdown widget that can be used across all screens.
/// Supports both toolbar-style (compact) and form-style (full-width) modes.
class AppDropdown<T> extends StatefulWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T?) onChanged;
  final String? hint;
  final IconData? prefixIcon;
  final Color? accentColor;
  final bool isCompact; // true = toolbar pill style, false = full-width form style
  final String? label;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.hint,
    this.prefixIcon,
    this.accentColor,
    this.isCompact = false,
    this.label,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    setState(() => _isOpen = true);
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    _animCtrl.forward();
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _animCtrl.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) setState(() => _isOpen = false);
    });
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final accent = widget.accentColor ?? const Color(0xFF003366);

    // Position check: open upward if not enough space below
    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    const dropdownMaxH = 260.0;
    final spaceBelow = screenHeight - position.dy - size.height;
    final openUpward = spaceBelow < dropdownMaxH;
    final dropdownOffset = openUpward
        ? Offset(0, -(dropdownMaxH + 6))
        : Offset(0, size.height + 6);

    return OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: SizedBox.expand(
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: dropdownOffset,
                child: Material(
                  color: Colors.transparent,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: widget.isCompact ? null : size.width,
                        constraints: BoxConstraints(
                          minWidth: widget.isCompact ? 160 : size.width,
                          maxWidth: widget.isCompact ? 220 : size.width,
                          maxHeight: 260,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.items.map((item) {
                                final isSelected = item == widget.value;
                                final label = widget.labelBuilder(item);
                                return GestureDetector(
                                  onTap: () {
                                    _closeDropdown();
                                    widget.onChanged(item);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    color: isSelected
                                        ? accent.withOpacity(0.08)
                                        : Colors.transparent,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? accent
                                                  : const Color(0xFF2D3436),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check_circle_rounded,
                                              size: 18, color: accent),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? const Color(0xFF003366);
    final label = widget.labelBuilder(widget.value);

    if (widget.isCompact) {
      // ── COMPACT PILL STYLE (for toolbar filters) ──
      return CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _isOpen ? accent.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isOpen ? accent : Colors.grey.withOpacity(0.25),
                width: _isOpen ? 1.5 : 1,
              ),
              boxShadow: _isOpen
                  ? [BoxShadow(color: accent.withOpacity(0.15), blurRadius: 8)]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.prefixIcon != null) ...[
                  Icon(widget.prefixIcon,
                      size: 16,
                      color: _isOpen ? accent : Colors.grey[600]),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isOpen ? accent : Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _isOpen ? accent : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── FORM STYLE (full-width for forms) ──
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isOpen ? accent.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isOpen ? accent : Colors.grey.withOpacity(0.2),
              width: _isOpen ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isOpen
                    ? accent.withOpacity(0.1)
                    : Colors.black.withOpacity(0.03),
                blurRadius: _isOpen ? 10 : 6,
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(widget.prefixIcon,
                    size: 20,
                    color: _isOpen ? accent : Colors.grey[500]),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.label != null)
                      Text(
                        widget.label!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _isOpen ? accent : Colors.grey[400],
                          letterSpacing: 0.5,
                        ),
                      ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: _isOpen ? accent : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
