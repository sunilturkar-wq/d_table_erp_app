import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/roles_provider.dart';

class RolePermissionScreen extends StatefulWidget {
  const RolePermissionScreen({Key? key}) : super(key: key);

  @override
  State<RolePermissionScreen> createState() => _RolePermissionScreenState();
}

class _RolePermissionScreenState extends State<RolePermissionScreen> {
  // Local state for edits
  bool _isEditing = false;
  String _activeTab = 'default';
  Map<String, Map<String, dynamic>> _localPermissions = {};

  final List<Map<String, dynamic>> _modules = [
    {
      'title': 'Task Template',
      'key': 'taskTemplate',
      'actions': [
        {'name': 'Create', 'key': 'create', 'type': 'bool'},
        {'name': 'Edit', 'key': 'edit', 'type': 'bool'},
        {'name': 'View', 'key': 'view', 'type': 'bool'},
        {'name': 'Delete', 'key': 'delete', 'type': 'bool'},
      ],
    },
    {
      'title': 'Task',
      'key': 'task',
      'actions': [
        {'name': 'Create', 'key': 'create', 'type': 'bool'},
        {'name': 'Edit', 'key': 'edit', 'type': 'list'},
        {'name': 'Delete', 'key': 'delete', 'type': 'list'},
        {'name': 'Import Task', 'key': 'importTask', 'type': 'bool'},
        {'name': 'Export Task', 'key': 'exportTask', 'type': 'list'},
      ],
    },
    {
      'title': 'My Team',
      'key': 'myTeam',
      'actions': [
        {'name': 'Add', 'key': 'add', 'type': 'bool'},
        {'name': 'Edit', 'key': 'edit', 'type': 'list'},
        {'name': 'Delete', 'key': 'delete', 'type': 'list'},
        {'name': 'View', 'key': 'view', 'type': 'list'},
      ],
    },
    {
      'title': 'Holidays',
      'key': 'holidays',
      'actions': [
        {'name': 'Create', 'key': 'create', 'type': 'bool'},
        {'name': 'Edit', 'key': 'edit', 'type': 'bool'},
        {'name': 'View', 'key': 'view', 'type': 'bool'},
        {'name': 'Delete', 'key': 'delete', 'type': 'bool'},
      ],
    },
    {
      'title': 'Groups',
      'key': 'groups',
      'actions': [
        {'name': 'Create', 'key': 'create', 'type': 'bool'},
        {'name': 'Edit', 'key': 'edit', 'type': 'bool'},
        {'name': 'View', 'key': 'view', 'type': 'bool'},
        {'name': 'Delete', 'key': 'delete', 'type': 'bool'},
      ],
    },
    {
      'title': 'Activity',
      'key': 'activity',
      'actions': [
        {'name': 'View History', 'key': 'view', 'type': 'bool'},
      ],
    },
    {
      'title': 'Idea Board',
      'key': 'ideaBoard',
      'actions': [
        {'name': 'View Board', 'key': 'view', 'type': 'bool'},
      ],
    },
    {
      'title': 'Task Directory',
      'key': 'taskDirectory',
      'actions': [
        {'name': 'View Directory', 'key': 'view', 'type': 'bool'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RolesProvider>().fetchAllRoles();
    });
  }

  Map<String, dynamic> _defaultPermissionsStruct() {
    return {
      'taskTemplate': {
        'create': false,
        'edit': false,
        'view': false,
        'delete': false,
      },
      'task': {
        'create': false,
        'edit': 'None',
        'delete': 'None',
        'importTask': false,
        'exportTask': 'None',
      },
      'myTeam': {
        'add': false,
        'edit': 'None',
        'delete': 'None',
        'view': 'None',
      },
      'holidays': {
        'create': false,
        'edit': false,
        'view': true,
        'delete': false,
      },
      'groups': {
        'create': false,
        'edit': false,
        'view': false,
        'delete': false,
      },
      'activity': {'view': false},
      'ideaBoard': {'view': false},
      'taskDirectory': {'view': false},
    };
  }

  Map<String, dynamic> _defaultAdminPermissions() {
    return {
      'taskTemplate': {
        'create': true,
        'edit': true,
        'view': true,
        'delete': true,
      },
      'task': {
        'create': true,
        'edit': 'All',
        'delete': 'All',
        'importTask': true,
        'exportTask': 'All',
      },
      'myTeam': {'add': true, 'edit': 'All', 'delete': 'All', 'view': 'All'},
      'holidays': {'create': true, 'edit': true, 'view': true, 'delete': true},
      'groups': {'create': true, 'edit': true, 'view': true, 'delete': true},
      'activity': {'view': true},
      'ideaBoard': {'view': true},
      'taskDirectory': {'view': true},
    };
  }

  String _roleId(Map<String, dynamic> role) => role['id'].toString();

  String _roleNameUpper(Map<String, dynamic> role) =>
      (role['name'] ?? '').toString().toUpperCase();

  bool _isCustomRole(Map<String, dynamic> role) => role['isCustom'] == true;

  bool _isAdminLike(Map<String, dynamic> role) {
    final roleName = _roleNameUpper(role);
    return roleName == 'ADMIN' || roleName == 'SUPERADMIN';
  }

  Map<String, dynamic> _normalizedPermissionsForRole(
    Map<String, dynamic> role,
  ) {
    final template = _isAdminLike(role)
        ? _defaultAdminPermissions()
        : _defaultPermissionsStruct();
    final incoming = role['permissions'] is Map
        ? Map<String, dynamic>.from(role['permissions'])
        : <String, dynamic>{};
    final merged = jsonDecode(jsonEncode(template)) as Map<String, dynamic>;

    for (final entry in incoming.entries) {
      if (entry.value is Map) {
        final currentModule = merged[entry.key] is Map
            ? Map<String, dynamic>.from(merged[entry.key])
            : <String, dynamic>{};
        currentModule.addAll(Map<String, dynamic>.from(entry.value));
        merged[entry.key] = currentModule;
      } else {
        merged[entry.key] = entry.value;
      }
    }

    return merged;
  }

  List<String> _baseOptions(String moduleKey, String actionKey) {
    switch ('$moduleKey.$actionKey') {
      case 'task.edit':
        return ['All', 'My Team + Assigned', 'Assigned', 'None'];
      case 'task.delete':
        return ['None', 'Assigned', 'Assignee', 'Both', 'All'];
      case 'task.exportTask':
        return ['All', 'My Team + Me', 'Me', 'None'];
      case 'myTeam.edit':
        return ['All', 'My Team', 'None'];
      case 'myTeam.delete':
        return ['All', 'None'];
      case 'myTeam.view':
        return ['All', 'My Team', 'None'];
      default:
        return const [];
    }
  }

  List<String> _roleAwareOptions(
    Map<String, dynamic> role,
    String moduleKey,
    String actionKey,
    dynamic currentValue,
  ) {
    final roleName = _roleNameUpper(role);
    final current = currentValue?.toString();
    List<String> options;

    if (_isCustomRole(role)) {
      options = _baseOptions(moduleKey, actionKey);
    } else {
      switch ('$moduleKey.$actionKey') {
        case 'task.edit':
          options = _isAdminLike(role)
              ? ['All']
              : roleName == 'MANAGER'
              ? ['My Team + Assigned', 'Assigned', 'None', 'All']
              : roleName == 'TEAM MEMBER'
              ? ['Assigned', 'None']
              : _baseOptions(moduleKey, actionKey);
          break;
        case 'task.delete':
          options = _isAdminLike(role)
              ? ['All']
              : roleName == 'MANAGER'
              ? ['None', 'Assigned', 'Assignee', 'Both', 'All']
              : roleName == 'TEAM MEMBER'
              ? ['None', 'Assigned', 'Assignee', 'Both']
              : _baseOptions(moduleKey, actionKey);
          break;
        case 'task.exportTask':
          options = _isAdminLike(role)
              ? ['All']
              : roleName == 'MANAGER'
              ? ['My Team + Me', 'None']
              : roleName == 'TEAM MEMBER'
              ? ['None', 'Me']
              : _baseOptions(moduleKey, actionKey);
          break;
        case 'myTeam.edit':
          options = _isAdminLike(role)
              ? ['All']
              : roleName == 'MANAGER'
              ? ['My Team', 'None']
              : roleName == 'TEAM MEMBER'
              ? ['None']
              : _baseOptions(moduleKey, actionKey);
          break;
        case 'myTeam.delete':
          options = _isAdminLike(role) ? ['All'] : ['None'];
          break;
        case 'myTeam.view':
          options = _isAdminLike(role)
              ? ['All']
              : roleName == 'MANAGER'
              ? ['All', 'My Team']
              : roleName == 'TEAM MEMBER'
              ? ['All', 'None']
              : _baseOptions(moduleKey, actionKey);
          break;
        default:
          options = _baseOptions(moduleKey, actionKey);
      }
    }

    if (current != null && current.isNotEmpty && !options.contains(current)) {
      return [current, ...options];
    }
    return options;
  }

  bool _isLockedCell(
    Map<String, dynamic> role,
    String moduleKey,
    String actionKey,
  ) {
    if (_isCustomRole(role)) return false;
    if (_isAdminLike(role)) return true;
    return false;
  }

  void _initLocalPermissions(List<Map<String, dynamic>> roles) {
    if (!_isEditing) {
      _localPermissions.clear();
      for (var role in roles) {
        final roleId = _roleId(role);
        _localPermissions[roleId] = _normalizedPermissionsForRole(role);
      }
    }
  }

  Future<void> _saveAllChanges(
    RolesProvider provider,
    List<Map<String, dynamic>> rolesToSave,
  ) async {
    bool overallSuccess = true;
    for (final role in rolesToSave) {
      final roleId = _roleId(role);
      bool success = await provider.updateRolePermissions(
        roleId: roleId,
        permissions: _localPermissions[roleId]!,
        refreshAfterUpdate: false,
      );
      if (!success) overallSuccess = false;
    }

    await provider.fetchAllRoles();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            overallSuccess
                ? 'Permissions saved successfully!'
                : 'Some permission updates failed.',
          ),
          backgroundColor: overallSuccess
              ? const Color(0xFF003366)
              : Colors.red,
        ),
      );
      if (overallSuccess) {
        setState(() {
          _isEditing = false;
        });
      }
    }
  }

  void _resetChanges() {
    setState(() {
      _isEditing = false;
      _localPermissions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "ROLE & PERMISSION",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<RolesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !_isEditing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && !_isEditing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.fetchAllRoles();
                      provider.clearError();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final roles = provider.roles;
          if (roles.isEmpty)
            return const Center(child: Text("No Roles Available"));

          final defaultRoles = roles
              .where((role) => role['isCustom'] != true)
              .toList();
          final customRoles = roles
              .where((role) => role['isCustom'] == true)
              .toList();
          _initLocalPermissions(defaultRoles);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton('default', 'Default Role'),
                        _buildTabButton('custom', 'Custom Role'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_activeTab == 'default') ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _resetChanges,
                          icon: const Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _saveAllChanges(provider, defaultRoles),
                          icon: const Icon(
                            Icons.save,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width - 32,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _modules.map((module) {
                                return _buildModuleSection(
                                  module,
                                  defaultRoles,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: _buildCustomRolesSection(customRoles, provider),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModuleSection(
    Map<String, dynamic> module,
    List<Map<String, dynamic>> roles,
  ) {
    final String moduleKey = module['key'];
    final String moduleTitle = module['title'];
    final List<Map<String, dynamic>> actions = List<Map<String, dynamic>>.from(
      module['actions'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(color: Color(0xFF003366)),
          child: Row(
            children: [
              SizedBox(
                width: 150,
                child: Text(
                  moduleTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              ...roles.map((role) {
                return SizedBox(
                  width: 140,
                  child: Center(
                    child: Text(
                      _roleNameUpper(role),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        // Action Rows
        ...actions.asMap().entries.map((entry) {
          int idx = entry.key;
          var action = entry.value;
          bool isLast = idx == actions.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                    ),
              color: Colors.white,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    action['name'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),

                ...roles.map((role) {
                  return SizedBox(
                    width: 140,
                    child: Center(
                      child: _buildCellContent(role, moduleKey, action),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCellContent(
    Map<String, dynamic> role,
    String moduleKey,
    Map<String, dynamic> action,
  ) {
    final roleId = _roleId(role);
    String actionKey = action['key'];
    String type = action['type'];
    final isLocked = _isLockedCell(role, moduleKey, actionKey);

    // Read from local state instead of provider directly
    Map<String, dynamic> perms = _localPermissions[roleId] ?? {};
    Map<String, dynamic> modulePerms = perms[moduleKey] != null
        ? Map<String, dynamic>.from(perms[moduleKey])
        : {};

    dynamic currentValue = modulePerms[actionKey];

    if (type == 'bool') {
      bool val = currentValue is bool
          ? currentValue
          : (currentValue == 'true' || currentValue == true);
      return GestureDetector(
        onTap: isLocked
            ? null
            : () {
                setState(() {
                  _isEditing = true;
                  modulePerms[actionKey] = !val;
                  perms[moduleKey] = modulePerms;
                  _localPermissions[roleId] = perms;
                });
              },
        child: Opacity(
          opacity: isLocked ? 0.55 : 1,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(4),
              color: val ? const Color(0xFF003366) : Colors.transparent,
              border: Border.all(
                color: val ? const Color(0xFF003366) : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: val
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
      );
    } else if (type == 'list') {
      final options = _roleAwareOptions(
        role,
        moduleKey,
        actionKey,
        currentValue,
      );
      final val = currentValue is String && options.contains(currentValue)
          ? currentValue
          : options.first;

      return Opacity(
        opacity: isLocked ? 0.7 : 1,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val,
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, size: 16),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
              items: options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: isLocked
                  ? null
                  : (newVal) {
                      if (newVal != null && newVal != val) {
                        setState(() {
                          _isEditing = true;
                          modulePerms[actionKey] = newVal;
                          perms[moduleKey] = modulePerms;
                          _localPermissions[roleId] = perms;
                        });
                      }
                    },
            ),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildDialogPermissionSection(
    Map<String, dynamic> module,
    Map<String, dynamic> permissions,
    void Function(String moduleKey, String actionKey, dynamic value) updatePerm,
  ) {
    final moduleKey = module['key'].toString();
    final modulePerms = permissions[moduleKey] is Map
        ? Map<String, dynamic>.from(permissions[moduleKey])
        : <String, dynamic>{};
    final actions = List<Map<String, dynamic>>.from(module['actions']);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF003366),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(
              module['title'].toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...actions.asMap().entries.map((entry) {
            final idx = entry.key;
            final action = entry.value;
            final actionKey = action['key'].toString();
            final currentValue = modulePerms[actionKey];
            final isLast = idx == actions.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: const Color(0xFFE2E8F0).withOpacity(0.8),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      action['name'].toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (action['type'] == 'bool')
                    GestureDetector(
                      onTap: () => updatePerm(
                        moduleKey,
                        actionKey,
                        !(currentValue == true || currentValue == 'true'),
                      ),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: currentValue == true || currentValue == 'true'
                              ? const Color(0xFF003366)
                              : Colors.transparent,
                          border: Border.all(
                            color: const Color(0xFFC7D3E3),
                            width: 1.6,
                          ),
                        ),
                        child: currentValue == true || currentValue == 'true'
                            ? const Icon(
                                Icons.check,
                                size: 15,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    )
                  else
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              currentValue is String &&
                                  _baseOptions(
                                    moduleKey,
                                    actionKey,
                                  ).contains(currentValue)
                              ? currentValue
                              : _baseOptions(moduleKey, actionKey).last,
                          items: _baseOptions(moduleKey, actionKey)
                              .map(
                                (opt) => DropdownMenuItem<String>(
                                  value: opt,
                                  child: Text(
                                    opt,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              updatePerm(moduleKey, actionKey, value);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showRoleDialog(
    BuildContext context,
    RolesProvider rolesProvider, {
    Map<String, dynamic>? roleToEdit,
  }) async {
    final controller = TextEditingController(
      text: roleToEdit?['name']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: roleToEdit?['description']?.toString() ?? '',
    );
    Map<String, dynamic> dialogPermissions = roleToEdit != null
        ? _normalizedPermissionsForRole(roleToEdit)
        : _defaultPermissionsStruct();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 10, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              roleToEdit == null ? 'Add Role' : 'Edit Role',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Configure role permissions and features.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROLE NAME',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: const Color(0xFF64748B).withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: controller,
                          onChanged: (_) => setDialogState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Enter Role Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF003366),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF003366),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF003366),
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${controller.text.length}/25',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'ROLE DESCRIPTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: const Color(0xFF64748B).withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descriptionController,
                          maxLines: 2,
                          onChanged: (_) => setDialogState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Enter Role Description',
                            filled: true,
                            fillColor: const Color(0xFFF3F7FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${descriptionController.text.length}/50',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ..._modules.map(
                          (module) => _buildDialogPermissionSection(
                            module,
                            dialogPermissions,
                            (moduleKey, actionKey, value) {
                              setDialogState(() {
                                final modulePerms =
                                    dialogPermissions[moduleKey] is Map
                                    ? Map<String, dynamic>.from(
                                        dialogPermissions[moduleKey],
                                      )
                                    : <String, dynamic>{};
                                modulePerms[actionKey] = value;
                                dialogPermissions[moduleKey] = modulePerms;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final name = controller.text.trim();
                          final description = descriptionController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Role name is required'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(dialogContext);

                          final success = roleToEdit == null
                              ? await rolesProvider.createRole(
                                  name: name,
                                  description: description,
                                  permissions: dialogPermissions,
                                )
                              : await rolesProvider.updateRole(
                                  roleId: _roleId(roleToEdit),
                                  name: name,
                                  description: description,
                                  permissions: dialogPermissions,
                                );

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? (roleToEdit == null
                                          ? 'Role added successfully'
                                          : 'Role updated successfully')
                                    : (rolesProvider.errorMessage ??
                                          'Unable to save role'),
                              ),
                              backgroundColor: success
                                  ? const Color(0xFF003366)
                                  : Colors.redAccent,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          roleToEdit == null ? 'Create Role' : 'Save Changes',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String value, String label) {
    final isActive = _activeTab == value;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF003366) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRole(
    BuildContext context,
    RolesProvider provider,
    Map<String, dynamic> role,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Are you sure you want to delete "${role['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await provider.deleteRole(_roleId(role));
    if (!mounted) return;

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Role deleted successfully'
              : (provider.errorMessage ?? 'Failed to delete role'),
        ),
        backgroundColor: success ? const Color(0xFF003366) : Colors.redAccent,
      ),
    );
  }

  Widget _buildCustomRolesSection(
    List<Map<String, dynamic>> customRoles,
    RolesProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Custom Roles',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showRoleDialog(context, provider),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'Add Role',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Edit or delete custom role details here. Permissions can be updated from the matrix above.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: customRoles.isEmpty
                ? const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'No custom roles created.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: customRoles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final role = customRoles[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${role['name'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role['description']
                                                ?.toString()
                                                .trim()
                                                .isNotEmpty ==
                                            true
                                        ? role['description'].toString()
                                        : 'No description added',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showRoleDialog(
                                context,
                                provider,
                                roleToEdit: role,
                              ),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.orange,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _confirmDeleteRole(context, provider, role),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
