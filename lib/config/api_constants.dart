class ApiConstants {
  // ✅ Mobile Backend Base URL
  static const String baseUrl = "http://3.110.68.228:5000/api";
  static const List<String> baseUrls = [
    "http://3.110.68.228:5000/api",
  ];

  // -- Auth ----------------------
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String bulkRegister = '/auth/bulk-register'; // ⚠️ Requires ADMIN/MANAGER token
  static const String me = '/auth/me';
  static const String getAllUser = '/auth/users'; // Response: direct array (not {users:[]})

  // Update user: PUT /auth/users/:userId  (use ApiConstants.userById(id))
  // Change credentials: PUT /auth/users/:userId/credentials

  // -- Teams ----------------------
  static const String teams = '/teams';
  static const String myTeamMembers = '/teams/my-members'; // replaces old /auth/my-team

  // -- Delegations (Tasks) --------
  static const String delegations = '/delegations';
  static const String deletedDelegations = '/delegations/deleted';

  // -- Categories -----------------
  static const String categories = '/categories';

  // -- Tags -----------------------
  static const String tags = '/tags';

  // -- Groups ---------------------
  static const String groupsList = '/groups/list';   // GET all groups
  static const String groupsCreate = '/groups/create'; // POST create group
  static const String roles = '/roles';
  // Update group: PATCH /groups/:id/update (use ApiConstants.groupById(id))

  // -- Notifications --------------
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notification-settings';
  static const String notificationTemplates = '/notification-templates';

  // -- Task Templates -------------
  static const String taskTemplates = '/task-templates';

  // -- Holidays -------------------
  static const String holidays = '/holidays';

  // -- Activities -----------------
  static const String activities = '/activities';

  // -- Upload ---------------------
  static const String uploadProfileImage = '/upload/profile-image';

  // -- Dynamic URL Builders -------
  static String userById(String userId) => '/auth/users/$userId';
  static String userCredentials(String userId) => '/auth/users/$userId/credentials';
  static String changePassword(String userId) => '/auth/users/$userId/password';
  static String userDeleteTasks(String userId) => '/auth/users/$userId/tasks';
  static String groupById(String groupId) => '/groups/$groupId';
  static String groupMembers(String groupId) => '/groups/$groupId/members';
  static String groupUpdate(String groupId) => '/groups/$groupId/update';
  static String delegationById(String id) => '/delegations/$id';
  static String delegationRemarks(String id) => '/delegations/$id/remarks';
  static String delegationRestore(String id) => '/delegations/$id/restore';
  static String teamMembers(String teamId) => '/teams/$teamId/members';

  // -- Timeouts -------------------
  static const Duration requestTimeout = Duration(seconds: 45);
  static const Duration connectTimeout = Duration(seconds: 45);
}
