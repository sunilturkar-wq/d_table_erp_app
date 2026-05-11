import 'package:flutter/material.dart';

class CustomMultiDropdown<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) labelBuilder;
  final Function(List<T>) onChanged;
  final double width;

  const CustomMultiDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.labelBuilder,
    required this.onChanged,
    this.width = 150,
  });

  @override
  State<CustomMultiDropdown<T>> createState() => _CustomMultiDropdownState<T>();
}

class _CustomMultiDropdownState<T> extends State<CustomMultiDropdown<T>> {
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
            width: 200,
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
                                final isSelected = widget.selectedItems.contains(item);
                                return InkWell(
                                  onTap: () {
                                    setOverlayState(() {
                                      final newList = List<T>.from(widget.selectedItems);
                                      if (isSelected) {
                                        newList.remove(item);
                                      } else {
                                        newList.add(item);
                                      }
                                      widget.onChanged(newList);
                                      setState(() {}); 
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          visualDensity: VisualDensity.compact,
                                          activeColor: Colors.blue,
                                          onChanged: (val) {
                                            setOverlayState(() {
                                              final newList = List<T>.from(widget.selectedItems);
                                              if (val == true) {
                                                newList.add(item);
                                              } else {
                                                newList.remove(item);
                                              }
                                              widget.onChanged(newList);
                                              setState(() {});
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Text(
                                            widget.labelBuilder(item),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
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
    String display = widget.label;
    if (widget.selectedItems.isNotEmpty) {
      if (widget.selectedItems.length == 1) {
        display = widget.labelBuilder(widget.selectedItems.first);
      } else {
        display = "${widget.selectedItems.length} selected";
      }
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          width: widget.width,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  display,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(_isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.blueGrey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
