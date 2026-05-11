import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/task_template_provider.dart';
import '../provider/category_provider.dart';
import '../provider/auth_provider.dart';
import '../provider/theme_provider.dart';
import '../model/task_template_model.dart';
import '../model/category_model.dart';
import 'app_dropdown.dart';

class TaskTemplateSheet extends StatefulWidget {
  final TaskTemplateModel? template;

  const TaskTemplateSheet({Key? key, this.template}) : super(key: key);

  @override
  State<TaskTemplateSheet> createState() => _TaskTemplateSheetState();
}

class _TaskTemplateSheetState extends State<TaskTemplateSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _newChecklistItemController =
      TextEditingController();

  CategoryModel? _selectedCategory;
  final List<String> _priorityOptions = ['Urgent', 'High', 'Medium', 'Low'];
  String _selectedPriority = 'Medium';

  final List<String> _frequencyOptions = ['Once', 'Daily', 'Weekly', 'Monthly'];
  String _selectedFrequency = 'Once';

  List<Map<String, dynamic>> _checklistItems = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final catProvider = context.read<CategoryProvider>();
      if (catProvider.categories.isEmpty) {
        await catProvider.fetchCategories();
      }

      if (widget.template != null) {
        _titleController.text = widget.template!.title;
        _descriptionController.text = widget.template!.description ?? '';
        _selectedPriority = widget.template!.priority ?? 'Medium';
        _selectedFrequency = widget.template!.frequency ?? 'Once';

        if (widget.template!.category != null) {
          try {
            _selectedCategory = catProvider.categoryModels.firstWhere(
              (c) => c.name == widget.template!.category,
            );
          } catch (e) {
            _selectedCategory = null;
          }
        }

        if (widget.template!.checklistItems != null) {
          _checklistItems = widget.template!.checklistItems!.map((item) {
            if (item is Map) {
              return {
                'text': item['text'],
                'completed': item['completed'] ?? false,
              };
            }
            return {'text': item.toString(), 'completed': false};
          }).toList();
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newChecklistItemController.dispose();
    super.dispose();
  }

  void _addChecklistItem() {
    final text = _newChecklistItemController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklistItems.add({'text': text, 'completed': false});
        _newChecklistItemController.clear();
      });
    }
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
    });
  }

  Future<void> _submitTemplate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Focus Title is required')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<TaskTemplateProvider>();
      final auth = context.read<AuthProvider>().currentUser;

      final data = {
        'title': title,
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory?.name ?? '',
        'priority': _selectedPriority,
        'frequency': _selectedFrequency,
        'checklistItems': _checklistItems,
        'createdBy': auth?.id ?? '',
      };

      if (widget.template != null) {
        await provider.updateTemplate(widget.template!.id, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await provider.createTemplate(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.template == null
                          ? 'Create Task Template'
                          : 'Edit Task Template',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: appColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: appColors.textMuted),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: appColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: "Template Title...",
                        hintStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: appColors.textMuted.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.align_horizontal_left,
                          size: 20,
                          color: appColors.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            minLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              color: appColors.textSecondary,
                            ),
                            decoration: InputDecoration(
                              hintText: "Add description...",
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: appColors.textMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Divider(color: appColors.divider),
                    const SizedBox(height: 16),

                    // Priority, Category, Frequency Dropdowns
                    Consumer<CategoryProvider>(
                      builder: (context, catProvider, child) {
                        return Column(
                          children: [
                            // 1. Priority
                            AppDropdown<String>(
                              isCompact: false,
                              label: "PRIORITY",
                              prefixIcon: Icons.flag_outlined,
                              value: _selectedPriority,
                              items: _priorityOptions,
                              labelBuilder: (p) => p,
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedPriority = val);
                              },
                              accentColor: _getPriorityColor(_selectedPriority),
                            ),
                            const SizedBox(height: 16),

                            // 2. Category
                            Builder(
                              builder: (context) {
                                return AppDropdown<String>(
                                  isCompact: false,
                                  label: "CATEGORY",
                                  prefixIcon: Icons.label_outline,
                                  value: _selectedCategory?.name ?? 'Category',
                                  items: [
                                    'Category',
                                    ...catProvider.categoryModels.map(
                                      (c) => c.name,
                                    ),
                                  ],
                                  labelBuilder: (name) => name,
                                  onChanged: (val) {
                                    if (val != null && val != 'Category') {
                                      setState(() {
                                        _selectedCategory = catProvider
                                            .categoryModels
                                            .firstWhere((c) => c.name == val);
                                      });
                                    }
                                  },
                                  accentColor: _selectedCategory != null
                                      ? _parseColor(_selectedCategory!.color)
                                      : Colors.grey.shade600,
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // 3. Frequency
                            AppDropdown<String>(
                              isCompact: false,
                              label: "FREQUENCY",
                              prefixIcon: Icons.repeat,
                              value: _selectedFrequency,
                              items: _frequencyOptions,
                              labelBuilder: (f) => f,
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedFrequency = val);
                              },
                              accentColor: Colors.purple,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    Divider(color: appColors.divider),
                    const SizedBox(height: 16),

                    // Checklist Section
                    Text(
                      'CHECKLIST',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: appColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...List.generate(_checklistItems.length, (index) {
                      final item = _checklistItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_box_outline_blank,
                              size: 20,
                              color: appColors.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: appColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 16,
                                color: appColors.textMuted,
                              ),
                              onPressed: () => _removeChecklistItem(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add new checklist item
                    Row(
                      children: [
                        const Icon(
                          Icons.add,
                          size: 20,
                          color: Color(0xFF003366),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _newChecklistItemController,
                            onSubmitted: (_) => _addChecklistItem(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: appColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Add an item...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: appColors.textMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _addChecklistItem,
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              color: Color(0xFF003366),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                border: Border(top: BorderSide(color: appColors.divider)),
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTemplate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.template == null
                            ? 'Create Template'
                            : 'Update Template',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
