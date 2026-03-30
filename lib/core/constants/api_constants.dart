class ApiConstants {
  static const String baseUrl = 'https://admin.iverifycarbon.com/IV-API';
  
  // Auth endpoints
  static const String verifyUser = '/auth/verifyUser';
  
  // Data endpoints
  static const String trainingSet = '/training_set';
  static const String trainingSetPaginated = '/training-site/training_set';
  static const String sync = '/training-site/sync';
  static const String updateData = '/training-site/update_data';
  static const String districtSlug = '/training-site/district_slug';
  static const String authoritySlug = '/training-site/authority_slug';
  static const String langSlug = '/training-site/lang_slug';
  static const String cookstoveSlug = '/training-site/cookstove_slug';
  static const String getAllSites = '/training-site/getAllSites';
  static const String beneficiarySync = '/beneficiary/sync';
  static const String beneficiaryList = '/beneficiary/list';
  static const String beneficiaryBeneSync = '/beneficiary/bene_sync';
  static const String beneficiaryData = '/beneficiary/Beneficiary_data';
  
  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
