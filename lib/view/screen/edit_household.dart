import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irise/data/repositories/beneficiary_repository.dart';
import 'package:irise/data/models/beneficiary.dart';
import 'package:irise/core/utils/image_utils.dart';
import 'package:irise/core/storage/token_storage.dart';
import 'package:irise/core/constants/api_constants.dart';
import 'package:irise/data/services/data_service.dart';
import 'package:irise/view/widgets/network_image_with_retry.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:developer' as developer;

class EditHouseholdScreen extends StatefulWidget {
  final String? householdId;
  
  const EditHouseholdScreen({super.key, this.householdId});

  @override
  State<EditHouseholdScreen> createState() => _EditHouseholdScreenState();
}

class _EditHouseholdScreenState extends State<EditHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final BeneficiaryRepository _beneficiaryRepo = BeneficiaryRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final TokenStorage _tokenStorage = TokenStorage();
  final DataService _dataService = DataService();
  
  // Controllers
  final _cookStoveDetailsController = TextEditingController();
  final _deviceSerialNoController = TextEditingController();
  
  // GPS coordinates
  double? _latitude;
  double? _longitude;
  
  // Images
  File? _houseImage;
  String? _houseImagePath;
  String? _houseImageTimestamp;
  
  File? _cookStoveImage;
  String? _cookStoveImagePath;
  String? _cookStoveImageTimestamp;
  
  // Consent toggles
  bool _consent1 = false; // stove_status_delivery
  bool _consent2 = false; // no_other_cook_stove_present
  bool _consent3 = false; // primary_residence_confirmation
  
  bool _isSaving = false;
  bool _isLoading = true;
  Beneficiary? _beneficiary;
  
  // Validation state
  bool _isDeviceSerialNoChecking = false;
  bool _isDeviceSerialNoDuplicate = false;

  @override
  void initState() {
    super.initState();
    _loadBeneficiary();
    _setupDeviceSerialNoListener();
  }
  
  void _setupDeviceSerialNoListener() {
    _deviceSerialNoController.addListener(() async {
      final text = _deviceSerialNoController.text;

      developer.log('=== Device Serial No Listener Fired ===', name: 'EditHouseholdScreen');
      developer.log('Text: "$text"', name: 'EditHouseholdScreen');
      
      // Convert to uppercase and filter to alphanumeric only
      final filtered = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (filtered != text) {
        developer.log('Converting "$text" to "$filtered"', name: 'EditHouseholdScreen');
        _deviceSerialNoController.value = TextEditingValue(
          text: filtered,
          selection: TextSelection.collapsed(offset: filtered.length),
        );
        return;
      }
      
      developer.log('Text after filtering: "$text"', name: 'EditHouseholdScreen');
      developer.log('Current _beneficiary: ${_beneficiary != null ? "LOADED" : "NULL"}', name: 'EditHouseholdScreen');
      if (_beneficiary != null) {
        developer.log('  - beneficiary_id: ${_beneficiary!.beneficiaryId}', name: 'EditHouseholdScreen');
        developer.log('  - offline_id: ${_beneficiary!.offlineId}', name: 'EditHouseholdScreen');
        developer.log('  - name: ${_beneficiary!.firstName} ${_beneficiary!.lastName}', name: 'EditHouseholdScreen');
      }
      
      // Check for duplicates (exclude current beneficiary if editing)
      if (text.trim().isNotEmpty) {
        setState(() => _isDeviceSerialNoChecking = true);
        
        developer.log('Calling isDeviceSerialNoExists...', name: 'EditHouseholdScreen');
        final exists = await _beneficiaryRepo.isDeviceSerialNoExists(
          text.trim(),
          excludeBeneficiaryId: _beneficiary?.beneficiaryId,
          excludeOfflineId: _beneficiary?.offlineId,
        );
        
        developer.log('Result: ${exists ? "EXISTS (DUPLICATE)" : "NOT EXISTS (AVAILABLE)"}', name: 'EditHouseholdScreen');
        developer.log('=== End Device Serial No Check ===', name: 'EditHouseholdScreen');
        
        setState(() {
          _isDeviceSerialNoChecking = false;
          _isDeviceSerialNoDuplicate = exists;
        });
      } else {
        developer.log('Text is empty, skipping check', name: 'EditHouseholdScreen');
        setState(() {
          _isDeviceSerialNoChecking = false;
          _isDeviceSerialNoDuplicate = false;
        });
      }
    });
  }

  Future<void> _loadBeneficiary() async {
    if (widget.householdId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      developer.log('Loading beneficiary with ID: ${widget.householdId}', name: 'EditHouseholdScreen');
      
      // Try to parse as beneficiary_id or offline_id
      final id = int.tryParse(widget.householdId!);
      
      if (id != null) {
        // Use getById which properly queries by beneficiary_id OR offline_id
        _beneficiary = await _beneficiaryRepo.getById(id);
        
        if (_beneficiary == null) {
          developer.log('Beneficiary not found with ID: $id', name: 'EditHouseholdScreen');
          setState(() => _isLoading = false);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Beneficiary not found'),
                backgroundColor: Colors.red,
              ),
            );
            context.pop();
          }
          return;
        }
      }
      
      if (_beneficiary != null) {
        developer.log('========================================', name: 'EditHouseholdScreen');
        developer.log('Beneficiary loaded successfully', name: 'EditHouseholdScreen');
        developer.log('Name: ${_beneficiary!.firstName} ${_beneficiary!.lastName}', name: 'EditHouseholdScreen');
        developer.log('beneficiary_id: ${_beneficiary!.beneficiaryId}', name: 'EditHouseholdScreen');
        developer.log('offline_id: ${_beneficiary!.offlineId}', name: 'EditHouseholdScreen');
        developer.log('device_serial_no: ${_beneficiary!.deviceSerialNo}', name: 'EditHouseholdScreen');
        developer.log('========================================', name: 'EditHouseholdScreen');
        
        // Populate form fields
        _cookStoveDetailsController.text = _beneficiary!.cookingMethod ?? '';
        _deviceSerialNoController.text = _beneficiary!.deviceSerialNo ?? '';
        _latitude = _beneficiary!.latitude;
        _longitude = _beneficiary!.longitude;
        
        // Load image paths and files
        _houseImagePath = _beneficiary!.housePic;
        _houseImageTimestamp = _beneficiary!.housePicTimestamp;
        if (_houseImagePath != null) {
          // Check if it's a server path (starts with /uploads/) or local file path
          if (_houseImagePath!.startsWith('/uploads/')) {
            // Server path - don't load as File, will display using network image
            _houseImage = null;
          } else if (File(_houseImagePath!).existsSync()) {
            // Local file path
            _houseImage = File(_houseImagePath!);
          }
        }
        
        _cookStoveImagePath = _beneficiary!.cookstovePic;
        _cookStoveImageTimestamp = _beneficiary!.cookstovePicTimestamp;
        if (_cookStoveImagePath != null) {
          // Check if it's a server path (starts with /uploads/) or local file path
          if (_cookStoveImagePath!.startsWith('/uploads/')) {
            // Server path - don't load as File, will display using network image
            _cookStoveImage = null;
          } else if (File(_cookStoveImagePath!).existsSync()) {
            // Local file path
            _cookStoveImage = File(_cookStoveImagePath!);
          }
        }
        
        // Load consent values
        _consent1 = _beneficiary!.stoveStatusDelivery?.toLowerCase() == 'yes';
        _consent2 = _beneficiary!.noOtherCookStovePresent?.toLowerCase() == 'yes';
        _consent3 = _beneficiary!.primaryResidenceConfirmation?.toLowerCase() == 'yes';
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error loading beneficiary: $e', name: 'EditHouseholdScreen');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading household: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cookStoveDetailsController.dispose();
    _deviceSerialNoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _captureGPS() async {
    try {
      // Check location permission
      var permission = await Permission.location.status;
      
      if (permission.isDenied) {
        permission = await Permission.location.request();
      }
      
      if (permission.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is permanently denied. Please enable it in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (!permission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to capture GPS'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
        );
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      developer.log('Error capturing GPS: $e', name: 'EditHouseholdScreen');
      
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing GPS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto(String type) async {
    try {
      // Directly use camera (gallery option removed)
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Validate image format (PNG, JPEG, JPG only)
      final extension = pickedFile.path.toLowerCase().split('.').last;
      if (!['png', 'jpg', 'jpeg'].contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only PNG, JPEG, and JPG formats are allowed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
        );
      }

      // Compress and save image
      final compressedPath = await ImageUtils.saveCompressedImage(
        File(pickedFile.path),
        prefix: type.toLowerCase().replaceAll(' ', '_'),
        targetSizeKB: 500, // Target 500KB
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (compressedPath != null) {
        final fileSizeKB = await ImageUtils.getFileSizeKB(compressedPath);
        final timestamp = DateTime.now().toUtc().toIso8601String();
        
        setState(() {
          if (type == 'house') {
            _houseImage = File(compressedPath);
            _houseImagePath = compressedPath;
            _houseImageTimestamp = timestamp;
          } else if (type == 'cookstove') {
            _cookStoveImage = File(compressedPath);
            _cookStoveImagePath = compressedPath;
            _cookStoveImageTimestamp = timestamp;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$type image captured (${fileSizeKB.toStringAsFixed(1)} KB)'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error taking photo: $e', name: 'EditHouseholdScreen');
      
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(String type) async {
    // Show confirmation dialog since images are mandatory
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image?'),
        content: Text(
          'Are you sure you want to remove this image? You will need to capture a new ${type == 'house' ? 'house' : 'cook stove'} image before saving.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        if (type == 'house') {
          _houseImage = null;
          _houseImagePath = null;
          _houseImageTimestamp = null;
        } else if (type == 'cookstove') {
          _cookStoveImage = null;
          _cookStoveImagePath = null;
          _cookStoveImageTimestamp = null;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type == 'house' ? 'House' : 'Cook stove'} image removed. Please capture a new image.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveHousehold() async {
    if (_formKey.currentState!.validate()) {
      if (_beneficiary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No beneficiary data to save'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Check for duplicate Device Serial Number (double-check before saving)
      if (_isDeviceSerialNoDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device Serial No already exists. Please use a different one.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Final check: Verify Device Serial No doesn't exist in database
      final deviceSerialNoExists = await _beneficiaryRepo.isDeviceSerialNoExists(
        _deviceSerialNoController.text.trim(),
        excludeBeneficiaryId: _beneficiary?.beneficiaryId,
        excludeOfflineId: _beneficiary?.offlineId,
      );
      
      if (deviceSerialNoExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device Serial No already exists. Please use a different one.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
      
      // Validate all mandatory fields
      if (_deviceSerialNoController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device Serial No is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS location is required. Please capture GPS coordinates.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (_houseImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('House image is required. Please capture house image.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (_cookStoveImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cook stove image is required. Please capture cook stove image.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() => _isSaving = true);
      
      try {
        developer.log('========================================', name: 'EditHouseholdScreen');
        developer.log('Saving household changes...', name: 'EditHouseholdScreen');
        developer.log('Beneficiary: ${_beneficiary!.firstName} ${_beneficiary!.lastName}', name: 'EditHouseholdScreen');
        developer.log('Before update - beneficiary_id: ${_beneficiary!.beneficiaryId}, offline_id: ${_beneficiary!.offlineId}, s_is_sync: ${_beneficiary!.sIsSync}', name: 'EditHouseholdScreen');
        
        // Get user ID from token storage
        final userId = await _tokenStorage.getUserId();
        
        // Create updated beneficiary with household data
        // IMPORTANT: Preserve createdDate and createdBy - only update modifiedDate
        final updatedBeneficiary = _beneficiary!.copyWith(
          deviceSerialNo: _deviceSerialNoController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          housePic: _houseImagePath,
          housePicTimestamp: _houseImageTimestamp,
          cookstovePic: _cookStoveImagePath,
          cookstovePicTimestamp: _cookStoveImageTimestamp,
          stoveStatusDelivery: _consent1 ? 'yes' : 'no',
          noOtherCookStovePresent: _consent2 ? 'yes' : 'no',
          primaryResidenceConfirmation: _consent3 ? 'yes' : 'no',
          // Preserve createdDate and createdBy from original beneficiary
          createdDate: _beneficiary!.createdDate,
          createdBy: _beneficiary!.createdBy,
          modifiedDate: DateTime.now().toUtc().toIso8601String(),
          modifiedBy: userId,
          sIsSync: 0, // Mark as unsynced since we modified it
        );
        
        developer.log('After update - beneficiary_id: ${updatedBeneficiary.beneficiaryId}, offline_id: ${updatedBeneficiary.offlineId}, s_is_sync: ${updatedBeneficiary.sIsSync}', name: 'EditHouseholdScreen');
        developer.log('Marked as UNSYNCED (s_is_sync = 0)', name: 'EditHouseholdScreen');
        
        // Update in database
        await _beneficiaryRepo.update(updatedBeneficiary);
        
        developer.log('Household saved successfully to database', name: 'EditHouseholdScreen');
        
        // Reload the complete beneficiary data from database for potential sync
        final reloadedBeneficiary = await _beneficiaryRepo.getById(updatedBeneficiary.beneficiaryId ?? updatedBeneficiary.offlineId!);
        if (reloadedBeneficiary != null) {
          developer.log('Reloaded complete beneficiary data from database', name: 'EditHouseholdScreen');
          developer.log('Reloaded beneficiary - beneficiary_id: ${reloadedBeneficiary.beneficiaryId}, offline_id: ${reloadedBeneficiary.offlineId}', name: 'EditHouseholdScreen');
          developer.log('Complete data ready for sync: ${reloadedBeneficiary.toJsonForSync()}', name: 'EditHouseholdScreen');
        }
        
        developer.log('========================================', name: 'EditHouseholdScreen');
        
        setState(() => _isSaving = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Household saved successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          context.pop();
        }
      } catch (e) {
        developer.log('Error saving household: $e', name: 'EditHouseholdScreen');
        setState(() => _isSaving = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving household: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _syncHousehold() async {
    if (_beneficiary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No beneficiary data to sync'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      developer.log('Syncing household: ${_beneficiary!.firstName} ${_beneficiary!.lastName}', name: 'EditHouseholdScreen');
      
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
        );
      }
      
      // Reload complete beneficiary data from database
      final reloadedBeneficiary = await _beneficiaryRepo.getById(_beneficiary!.beneficiaryId ?? _beneficiary!.offlineId!);
      if (reloadedBeneficiary == null) {
        throw Exception('Failed to reload beneficiary data');
      }
      
      developer.log('Reloaded beneficiary for sync - beneficiary_id: ${reloadedBeneficiary.beneficiaryId}, offline_id: ${reloadedBeneficiary.offlineId}', name: 'EditHouseholdScreen');
      
      // Convert beneficiary to JSON for sync (send complete data from local DB)
      final beneficiaryJson = reloadedBeneficiary.toJsonForSync();
      
      developer.log('Beneficiary sync payload (complete data from local DB): $beneficiaryJson', name: 'EditHouseholdScreen');
      
      // Sync to server using beneficiaryBeneSync
      final response = await _dataService.beneficiaryBeneSync(
        beneficiaries: [beneficiaryJson],
      );
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (response.success) {
        developer.log('========================================', name: 'EditHouseholdScreen');
        developer.log('Household synced successfully', name: 'EditHouseholdScreen');
        developer.log('Response data: ${response.data}', name: 'EditHouseholdScreen');
        developer.log('Current household - beneficiary_id: ${_beneficiary!.beneficiaryId}, offline_id: ${_beneficiary!.offlineId}, s_is_sync: ${_beneficiary!.sIsSync}', name: 'EditHouseholdScreen');
        
        // Try to extract beneficiary_id from response
        int? beneficiaryId;
        
        if (response.data != null) {
          // Response format: {success: true, action: updated, beneficiary_id: 94, message: ...}
          if (response.data!['beneficiary_id'] != null) {
            beneficiaryId = response.data!['beneficiary_id'] as int?;
            developer.log('Found beneficiary_id in response: $beneficiaryId', name: 'EditHouseholdScreen');
          } else if (response.data!['data'] is Map) {
            // Alternative format: {success: true, data: {beneficiary_id: 94}}
            final dataMap = response.data!['data'] as Map;
            beneficiaryId = dataMap['beneficiary_id'] as int?;
            developer.log('Found beneficiary_id in data map: $beneficiaryId', name: 'EditHouseholdScreen');
          } else if (response.data!['data'] is List) {
            // Alternative format: {success: true, data: [{beneficiary_id: 94}]}
            final mappings = response.data!['data'] as List;
            if (mappings.isNotEmpty) {
              final mapping = mappings.first;
              beneficiaryId = mapping['beneficiary_id'] as int?;
              developer.log('Found beneficiary_id in data list: $beneficiaryId', name: 'EditHouseholdScreen');
            }
          }
        }
        
        // Always mark as synced after successful sync
        developer.log('Marking household as synced...', name: 'EditHouseholdScreen');
        
        if (_beneficiary!.offlineId != null && beneficiaryId != null && _beneficiary!.beneficiaryId == null) {
          // Has offline_id, got beneficiary_id from server, and doesn't already have beneficiary_id - update with server ID
          developer.log('Updating offline_id ${_beneficiary!.offlineId} with server beneficiary_id: $beneficiaryId', name: 'EditHouseholdScreen');
          await _beneficiaryRepo.updateWithServerId(_beneficiary!.offlineId!, beneficiaryId);
        } else {
          // Already has beneficiary_id or no beneficiary_id in response - just mark as synced
          developer.log('Marking as synced (beneficiary_id: ${_beneficiary!.beneficiaryId ?? beneficiaryId})', name: 'EditHouseholdScreen');
          final updatedHousehold = _beneficiary!.copyWith(
            sIsSync: 1,
            beneficiaryId: beneficiaryId ?? _beneficiary!.beneficiaryId,
          );
          await _beneficiaryRepo.update(updatedHousehold);
        }
        
        developer.log('Update complete, reloading beneficiary...', name: 'EditHouseholdScreen');
        developer.log('========================================', name: 'EditHouseholdScreen');
        
        // Reload beneficiary to reflect changes
        await _loadBeneficiary();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Household synced successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error syncing household: $e', name: 'EditHouseholdScreen');
      
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFEAF4EA),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4EA),
      body: Stack(
        children: [
          // Green quarter-circle top-right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 90,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(120),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
                      ),
                      const Expanded(
                        child: Text(
                          'Edit House Hold Distribution',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    
                      
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.question_mark_rounded, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // _buildCookStoveDetailsSection(),
                          // const SizedBox(height: 20),
                          _buildDeviceSerialNoSection(),
                          const SizedBox(height: 20),
                          _buildGPSSection(),
                          const SizedBox(height: 20),
                          _buildImageSection(
                            title: 'HOUSE IMAGE',
                            image: _houseImage,
                            timestamp: _houseImageTimestamp,
                            onRetake: () => _takePhoto('house'),
                            onRemove: () => _removeImage('house'),
                          ),
                          const SizedBox(height: 20),
                          _buildImageSection(
                            title: 'COOK STOVE IMAGE',
                            image: _cookStoveImage,
                            timestamp: _cookStoveImageTimestamp,
                            onRetake: () => _takePhoto('cookstove'),
                            onRemove: () => _removeImage('cookstove'),
                          ),
                          const SizedBox(height: 20),
                          _buildConsentSection(),
                          const SizedBox(height: 20),
                          _buildSaveButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookStoveDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DEVICE SERIAL NUMBER',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Text(
            _cookStoveDetailsController.text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceSerialNoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'DEVICE SERIAL NO',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDeviceSerialNoDuplicate ? Colors.red : const Color(0xFFE0E0E0),
                ),
              ),
              child: TextFormField(
                cursorColor: Colors.green,
                controller: _deviceSerialNoController,
                decoration: const InputDecoration(
                  hintText: 'Enter Device Serial No (A-Z, 0-9)',
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Device Serial No is required';
                  
                  // Validate alphanumeric only
                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value!)) {
                    return 'Only alphanumeric characters (A-Z, 0-9) are allowed';
                  }
                  
                  return null;
                },
              ),
            ),
            if (_isDeviceSerialNoChecking)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Checking...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            if (!_isDeviceSerialNoChecking && _deviceSerialNoController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Row(
                  children: [
                    Icon(
                      _isDeviceSerialNoDuplicate ? Icons.error : Icons.check_circle,
                      size: 14,
                      color: _isDeviceSerialNoDuplicate ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isDeviceSerialNoDuplicate ? 'Already exists' : 'Available',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isDeviceSerialNoDuplicate ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildGPSSection() {
    final gpsText = (_latitude != null && _longitude != null)
        ? 'GPS: $_latitude, $_longitude'
        : 'GPS: Not captured';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'GPS LOCATION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gpsText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: (_latitude != null && _longitude != null) 
                          ? Colors.grey.shade600 
                          : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _captureGPS,
              icon: const Icon(Icons.gps_fixed, size: 18),
              label: const Text('Capture GPS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageSection({
    required String title,
    required File? image,
    required String? timestamp,
    required VoidCallback onRetake,
    required VoidCallback onRemove,
  }) {
    // Determine the image path based on title
    String? imagePath;
    if (title.contains('HOUSE')) {
      imagePath = _houseImagePath;
    } else if (title.contains('COOK STOVE')) {
      imagePath = _cookStoveImagePath;
    }
    
    final bool hasServerImage = imagePath != null && imagePath.startsWith('/uploads/');
    final bool hasLocalImage = image != null;
    final bool hasAnyImage = hasServerImage || hasLocalImage;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Image Preview Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Dashed border container for image
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Image display
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: hasAnyImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: hasLocalImage
                                  ? Image.file(image, fit: BoxFit.cover)
                                  : NetworkImageWithRetry(
                                      imageUrl: '${ApiConstants.baseUrl}$imagePath',
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No image captured',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    // Preview label (only show if image exists)
                    if (hasAnyImage)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              if (timestamp != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Captured at ${_formatTimestamp(timestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Retake Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Retake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Remove Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Info message
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ensure all details are clearly visible',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONSENT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildConsentToggle(
            text: 'I can confirm that the household has only received 1 cookstove and that the cookstove was delivered in good condition and in full working order',
            value: _consent1,
            onChanged: (value) => setState(() => _consent1 = value),
            isRequired: false,
          ),
          
          const SizedBox(height: 16),
          
          _buildConsentToggle(
            text: 'I confirm I performed a visual inspection of the household and that no other cookstove from any other company was found or was deemed to have recently removed from the household',
            value: _consent2,
            onChanged: (value) => setState(() => _consent2 = value),
            isRequired: false,
          ),
          
          const SizedBox(height: 16),
          
          _buildConsentToggle(
            text: 'I can confirm that the beneficiary lives at this household and that they are the primary resident of this household',
            value: _consent3,
            onChanged: (value) => setState(() => _consent3 = value),
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildConsentToggle({
    required String text,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isRequired = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF4CAF50),
            activeTrackColor: const Color(0xFF4CAF50).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final isSynced = _beneficiary?.sIsSync == 1;
    
    return Column(
      children: [
        // Sync status indicator
        // if (_beneficiary != null) ...[
        //   Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        //     decoration: BoxDecoration(
        //       color: isSynced ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        //       borderRadius: BorderRadius.circular(12),
        //       border: Border.all(
        //         color: isSynced ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
        //       ),
        //     ),
        //     child: Row(
        //       children: [
        //         Icon(
        //           isSynced ? Icons.cloud_done : Icons.cloud_off,
        //           color: isSynced ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
        //           size: 20,
        //         ),
        //         const SizedBox(width: 8),
        //         Expanded(
        //           child: Text(
        //             isSynced 
        //                 ? 'This household is synced with the server' 
        //                 : 'This household is not synced. Save and sync to upload changes.',
        //             style: TextStyle(
        //               fontSize: 13,
        //               color: isSynced ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
        //               fontWeight: FontWeight.w500,
        //             ),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        //   const SizedBox(height: 16),
        // ],
        
        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveHousehold,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        
        // Sync button (only show if not synced)
        // if (!isSynced && _beneficiary != null) ...[
        //   const SizedBox(height: 12),
        //   SizedBox(
        //     width: double.infinity,
        //     child: OutlinedButton.icon(
        //       onPressed: _syncHousehold,
        //       icon: const Icon(Icons.sync, size: 18),
        //       label: const Text('Sync to Server'),
        //       style: OutlinedButton.styleFrom(
        //         foregroundColor: const Color(0xFFFF9800),
        //         side: const BorderSide(color: Color(0xFFFF9800)),
        //         padding: const EdgeInsets.symmetric(vertical: 16),
        //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        //       ),
        //     ),
        //   ),
        // ],
      ],
    );
  }
  
  String _formatTimestamp(String isoTimestamp) {
    try {
      final dateTime = DateTime.parse(isoTimestamp).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = dateTime.day;
      final month = months[dateTime.month - 1];
      final year = dateTime.year;
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      return 'Unknown';
    }
  }
}
