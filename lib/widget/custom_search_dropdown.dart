import 'package:flutter/material.dart';

class CustomSearchDropdown<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) labelBuilder;
  final Function(T?) onChanged;
  final double width;

  const CustomSearchDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
    this.width = 150,
  });

  @override
  State<CustomSearchDropdown<T>> createState() => _CustomSearchDropdownState<T>();
}

class _CustomSearchDropdownState<T> extends State<CustomSearchDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

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
    setState(() {
      _isOpen = false;
      _searchQuery = "";
      _searchCtrl.clear();
    });
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
            width: 200, // Fixed width for popup so it can be larger than the button if needed
            left: offset.dx,
            top: offset.dy + size.height + 4,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 4),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).cardColor,
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    final filteredItems = widget.items
                        .where((e) => widget.labelBuilder(e).toLowerCase().contains(_searchQuery.toLowerCase()))
                        .toList();

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 36,
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "Search...",
                                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade400),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  setOverlayState(() {
                                    _searchQuery = val;
                                  });
                                },
                              ),
                            ),
                          ),
                          Flexible(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelected = widget.value == item;
                                return InkWell(
                                  onTap: () {
                                    widget.onChanged(item);
                                    _closeDropdown();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    color: isSelected ? Colors.blue.withOpacity(0.05) : null,
                                    child: Text(
                                      widget.labelBuilder(item),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? Colors.blue : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
              Icon(Icons.person_rounded, size: 16, color: _isOpen ? const Color(0xFF1CB485) : Colors.grey[600]),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.value != null ? widget.labelBuilder(widget.value as T) : widget.label,
                  style: TextStyle(
                    fontSize: 13, 
                    color: _isOpen ? const Color(0xFF1CB485) : Colors.grey[800], 
                    fontWeight: FontWeight.w600
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded, 
                  color: _isOpen ? const Color(0xFF1CB485) : Colors.grey[500], 
                  size: 18
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
