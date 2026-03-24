class AppRoutes {
  // Root
  static const String splash = '/';
  static const String splash2 = '/splash2';
  static const String login = '/login';

  // Dashboard shell
  static const String dashboard = '/dashboard';

  // Dashboard sub-routes
  static const String beneficiary = '/dashboard/beneficiary_list';
  static const String beneficiaryDetail = '/dashboard/beneficiary/:id';

  static const String training = '/dashboard/training';
  static const String trainingDetail = '/dashboard/training/:id';

  static const String monitoring = '/dashboard/monitoring';
  static const String monitoringDetail = '/dashboard/monitoring/:id';

  static const String modules = '/dashboard/modules';
  static const String training_point_identification =
      '/training_point_identification';
  static const String training_site = '/training_site';
  static const String beneficiary_list = '/beneficiary_list';
  static const String conduct_training_list = '/conduct_training_list';
  // Profile / Settings
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String forgotPassword = '/forgot-password';
}
