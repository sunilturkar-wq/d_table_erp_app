import 'package:flutter/material.dart';

class CustomCategoryDropdown extends StatefulWidget {
  final List<String> items;
  final String value;
  final Function(String) onChanged;

  const CustomCategoryDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CustomCategoryDropdown> createState() => _CustomCategoryDropdownState();
}

class _CustomCategoryDropdownState extends State<CustomCategoryDropdown> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: size.width < 160 ? 160 : size.width,
            left: offset.dx,
            top: offset.dy + size.height + 4,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 4),
              child: Material(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FBF9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isSelected = widget.value == item;
                      return InkWell(
                        onTap: () {
                          widget.onChanged(item);
                          _closeDropdown();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          color: Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF1CB485) : Colors.black87,
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Color(0xFF1CB485), size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = widget.value != "All" && widget.value.isNotEmpty;
    String displayValue = hasSelection ? widget.value : "Category";

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _isOpen ? const Color(0xFF1CB485).withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isOpen ? const Color(0xFF1CB485) : Colors.grey.withOpacity(0.25),
              width: _isOpen ? 1.5 : 1,
            ),
            boxShadow: _isOpen
                ? [BoxShadow(color: const Color(0xFF1CB485).withOpacity(0.15), blurRadius: 8)]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.category_rounded, size: 16, color: _isOpen ? const Color(0xFF1CB485) : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 13,
                  color: _isOpen ? const Color(0xFF1CB485) : Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _isOpen ? const Color(0xFF1CB485) : Colors.grey[500],
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
