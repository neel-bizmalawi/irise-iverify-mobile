import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irise/data/repositories/language_repository.dart';
import 'package:irise/data/repositories/training_site_list_repository.dart';
import 'package:irise/data/repositories/beneficiary_repository.dart';
import 'package:irise/data/repositories/cookstove_repository.dart';
import 'package:irise/data/models/beneficiary.dart';
import 'package:irise/core/storage/token_storage.dart';
import 'package:irise/core/constants/api_constants.dart';
import 'package:irise/view/widgets/searchable_dropdown.dart';
import 'package:irise/view/widgets/simple_dropdown.dart';
import 'package:irise/view/widgets/network_image_with_retry.dart';
import 'package:irise/core/utils/image_utils.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

class BeneficiaryRegistrationScreen extends StatefulWidget {
  final String? beneficiaryId;

  const BeneficiaryRegistrationScreen({super.key, this.beneficiaryId});

  @override
  State<BeneficiaryRegistrationScreen> createState() =>
      _BeneficiaryRegistrationScreenState();
}

class _BeneficiaryRegistrationScreenState
    extends State<BeneficiaryRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Repositories
  final _languageRepo = LanguageRepository();
  final _trainingSiteListRepo = TrainingSiteListRepository();
  final _beneficiaryRepo = BeneficiaryRepository();
  final _cookstoveRepo = CookstoveRepository();
  final _tokenStorage = TokenStorage();
  final _imagePicker = ImagePicker();

  // Signature pad controller
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _femalesBelow18Controller = TextEditingController(text: '');
  final _femalesAbove18Controller = TextEditingController(text: '');
  final _malesBelow18Controller = TextEditingController(text: '');
  final _malesAbove18Controller = TextEditingController(text: '');

  // Dropdowns
  String? _selectedTrainingSite;
  String _selectedLanguage = 'English';
  String? _selectedCookingMethod;

  // Dropdown data from database
  List<String> _trainingSites = [];
  List<String> _languages = ['English'];
  List<String> _cookingMethods = []; // Will be loaded from database

  // Toggles
  bool _readDoc = false;
  bool _readToYou = false;
  bool _understoodDoc = false;
  bool _hasOtherCookstove = false;

  // Images
  File? _nationalIdImage;
  File? _signatureImage;
  
  // Image timestamps
  String? _nationalIdTimestamp;
  String? _signatureTimestamp;

  // Expandable sections
  bool _termsExpanded = false;
  bool _legalConsentExpanded = false;

  // Loading state
  bool _isLoading = true;
  bool _isSaving = false;

  // Validation state
  bool _isNationalIdChecking = false;
  bool _isNationalIdDuplicate = false;

  // Edit mode
  Beneficiary? _existingBeneficiary;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupNationalIdListener();
  }

  Future<void> _loadData() async {
    await _loadDropdownData();
    if (widget.beneficiaryId != null) {
      await _loadExistingBeneficiary();
    }
  }

  Future<void> _loadExistingBeneficiary() async {
    try {
      final id = int.tryParse(widget.beneficiaryId!);
      if (id != null) {
        final beneficiary = await _beneficiaryRepo.getById(id);
        if (beneficiary != null) {
          setState(() {
            _existingBeneficiary = beneficiary;
            _isEditMode = true;

            // Populate form fields
            _selectedTrainingSite = beneficiary.trainingSite;
            _firstNameController.text = beneficiary.firstName ?? '';
            _lastNameController.text = beneficiary.lastName ?? '';
            _mobileController.text = beneficiary.mobileNo ?? '';
            _nationalIdController.text = beneficiary.nationalId ?? '';
            _femalesBelow18Controller.text =
                beneficiary.femalesBelow18?.toString() ?? '';
            _femalesAbove18Controller.text =
                beneficiary.femalesAbove18?.toString() ?? '';
            _malesBelow18Controller.text =
                beneficiary.malesBelow18?.toString() ?? '';
            _malesAbove18Controller.text =
                beneficiary.malesAbove18?.toString() ?? '';
            _selectedCookingMethod = beneficiary.cookingMethod;
            _selectedLanguage = beneficiary.language ?? 'English';
            _readDoc = beneficiary.readDoc?.toLowerCase() == 'yes';
            _readToYou = beneficiary.readToYou?.toLowerCase() == 'yes';
            _understoodDoc = beneficiary.understoodDoc?.toLowerCase() == 'yes';
            _hasOtherCookstove = beneficiary.otherCookstove?.toLowerCase() == 'yes';

            // Load images
            if (beneficiary.nationalIdAttachment != null) {
              // Check if it's a server path (starts with /uploads/) or local file path
              if (beneficiary.nationalIdAttachment!.startsWith('/uploads/')) {
                // Server path - don't load as File, will display using network image
                _nationalIdImage = null;
              } else if (File(beneficiary.nationalIdAttachment!).existsSync()) {
                // Local file path
                _nationalIdImage = File(beneficiary.nationalIdAttachment!);
              }
              _nationalIdTimestamp = beneficiary.nationalIdTimestamp;
            }
            if (beneficiary.signature != null) {
              // Check if it's a server path (starts with /uploads/) or local file path
              if (beneficiary.signature!.startsWith('/uploads/')) {
                // Server path - don't load as File, will display using network image
                _signatureImage = null;
              } else if (File(beneficiary.signature!).existsSync()) {
                // Local file path
                _signatureImage = File(beneficiary.signature!);
              }
              _signatureTimestamp = beneficiary.signatureTimestamp;
            }
          });
        }
      }
    } catch (e) {
      developer.log('Error loading existing beneficiary: $e',
          name: 'BeneficiaryRegistration');
    }
  }

  void _setupNationalIdListener() {
    _nationalIdController.addListener(() async {
      final text = _nationalIdController.text;

      // Convert to uppercase
      if (text != text.toUpperCase()) {
        final selection = _nationalIdController.selection;
        _nationalIdController.value = TextEditingValue(
          text: text.toUpperCase(),
          selection: selection,
        );
        return;
      }

      // Check for duplicates (exclude current beneficiary if editing)
      if (text.trim().isNotEmpty) {
        setState(() => _isNationalIdChecking = true);

        final exists = await _beneficiaryRepo.isNationalIdExists(
          text.trim(),
          excludeBeneficiaryId: _existingBeneficiary?.beneficiaryId,
          excludeOfflineId: _existingBeneficiary?.offlineId,
        );

        setState(() {
          _isNationalIdChecking = false;
          _isNationalIdDuplicate = exists;
        });
      } else {
        setState(() {
          _isNationalIdChecking = false;
          _isNationalIdDuplicate = false;
        });
      }
    });
  }

  Future<void> _loadDropdownData() async {
    try {
      developer.log('Loading dropdown data from database...',
          name: 'BeneficiaryRegistration');

      final languages = await _languageRepo.getAll();
      final trainingSites = await _trainingSiteListRepo.getAll();
      final cookstoves = await _cookstoveRepo.getAll();

      setState(() {
        _languages = languages.map((l) => l.langName).toList();
        if (_languages.isNotEmpty && !_languages.contains(_selectedLanguage)) {
          _selectedLanguage = _languages.first;
        }

        _trainingSites = trainingSites.map((t) => t.trainingSite).toList();
        
        _cookingMethods = cookstoves.map((c) => c.cookstoveName).toList();

        _isLoading = false;
      });

      developer.log(
          'Loaded ${_languages.length} languages, ${_trainingSites.length} training sites, ${_cookingMethods.length} cooking methods',
          name: 'BeneficiaryRegistration');
    } catch (e) {
      developer.log('Error loading dropdown data: $e',
          name: 'BeneficiaryRegistration');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _nationalIdController.dispose();
    _femalesBelow18Controller.dispose();
    _femalesAbove18Controller.dispose();
    _malesBelow18Controller.dispose();
    _malesAbove18Controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
        );
      }

      // Compress and save image
      final compressedPath = await ImageUtils.saveCompressedImage(
        File(pickedFile.path),
        prefix: type.toLowerCase().replaceAll(' ', '_'),
        targetSizeKB: 500,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (compressedPath != null) {
        final fileSizeKB = await ImageUtils.getFileSizeKB(compressedPath);
        final timestamp = DateTime.now().toUtc().toIso8601String();

        setState(() {
          switch (type) {
            case 'National ID':
              _nationalIdImage = File(compressedPath);
              _nationalIdTimestamp = timestamp;
              break;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '$type image captured (${fileSizeKB.toStringAsFixed(1)} KB)'),
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
      developer.log('Error taking photo: $e', name: 'BeneficiaryRegistration');

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

  void _clearSignature() {
    _signaturePadKey.currentState?.clear();
    setState(() {
      _signatureImage = null;
    });
  }

  Future<void> _saveSignature() async {
    try {
      final signatureData =
          await _signaturePadKey.currentState?.toImage();
      if (signatureData != null) {
        final byteData =
            await signatureData.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final directory = await getApplicationDocumentsDirectory();
          final filePath =
              '${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(filePath);
          await file.writeAsBytes(byteData.buffer.asUint8List());

          setState(() {
            _signatureImage = file;
            _signatureTimestamp = DateTime.now().toUtc().toIso8601String();
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signature saved!'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          }
        }
      }
    } catch (e) {
      developer.log('Error saving signature: $e',
          name: 'BeneficiaryRegistration');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving signature: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveRegistration() async {
    if (_formKey.currentState!.validate()) {
      // Additional validation for required fields
      if (_selectedTrainingSite == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a training site'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedCookingMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a cooking method'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check for duplicate National ID (double-check before saving)
      if (_isNationalIdDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'National ID already exists. Please use a different one.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Final check: Verify National ID doesn't exist in database
      final nationalIdExists = await _beneficiaryRepo.isNationalIdExists(
        _nationalIdController.text.trim(),
        excludeBeneficiaryId: _existingBeneficiary?.beneficiaryId,
        excludeOfflineId: _existingBeneficiary?.offlineId,
      );
      
      if (nationalIdExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'National ID already exists. Please use a different one.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
      
      // Validate National ID attachment is captured
      if (_nationalIdImage == null && 
          (_existingBeneficiary?.nationalIdAttachment == null || 
           _existingBeneficiary!.nationalIdAttachment!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('National ID image is required. Please capture National ID image.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
      
      // Validate Signature is captured
      if (_signatureImage == null && 
          (_existingBeneficiary?.signature == null || 
           _existingBeneficiary!.signature!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature is required. Please capture signature.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      setState(() => _isSaving = true);

      try {
        developer.log('Saving beneficiary registration...',
            name: 'BeneficiaryRegistration');

        // Get user ID from token storage
        final userId = await _tokenStorage.getUserId();

        Beneficiary beneficiary;

        if (_isEditMode && _existingBeneficiary != null) {
          developer.log('Updating existing beneficiary...',
              name: 'BeneficiaryRegistration');

          beneficiary = _existingBeneficiary!.copyWith(
            trainingSite: _selectedTrainingSite,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            mobileNo: _mobileController.text.trim().isEmpty
                ? null
                : _mobileController.text.trim(),
            nationalId: _nationalIdController.text.trim(),
            femalesBelow18:
                int.tryParse(_femalesBelow18Controller.text) ?? 0,
            femalesAbove18:
                int.tryParse(_femalesAbove18Controller.text) ?? 0,
            malesBelow18: int.tryParse(_malesBelow18Controller.text) ?? 0,
            malesAbove18: int.tryParse(_malesAbove18Controller.text) ?? 0,
            cookingMethod: _selectedCookingMethod,
            otherCookstove: _hasOtherCookstove ? 'yes' : 'no',
            language: _selectedLanguage,
            readDoc: _readDoc ? 'yes' : 'no',
            readToYou: _readToYou ? 'yes' : 'no',
            understoodDoc: _understoodDoc ? 'yes' : 'no',
            nationalIdAttachment: _nationalIdImage?.path,
            signature: _signatureImage?.path,
            nationalIdTimestamp: _nationalIdTimestamp ?? _existingBeneficiary!.nationalIdTimestamp,
            signatureTimestamp: _signatureTimestamp ?? _existingBeneficiary!.signatureTimestamp,
            modifiedDate: DateTime.now().toUtc().toIso8601String(),
            modifiedBy: userId,
            sIsSync: 0,
          );

          await _beneficiaryRepo.update(beneficiary);
          developer.log('Beneficiary updated successfully',
              name: 'BeneficiaryRegistration');
          
          // Reload the complete beneficiary data from database for potential sync
          final reloadedBeneficiary = await _beneficiaryRepo.getById(beneficiary.id!);
          if (reloadedBeneficiary != null) {
            developer.log('Reloaded complete beneficiary data from database', name: 'BeneficiaryRegistration');
            developer.log('Complete data ready for sync: ${reloadedBeneficiary.toJsonForSync()}', name: 'BeneficiaryRegistration');
          }
        } else {
          developer.log('Creating new beneficiary...',
              name: 'BeneficiaryRegistration');

          final offlineId = await _beneficiaryRepo.getNextOfflineId();

          beneficiary = Beneficiary(
            offlineId: offlineId,
            trainingSite: _selectedTrainingSite,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            mobileNo: _mobileController.text.trim().isEmpty
                ? null
                : _mobileController.text.trim(),
            nationalId: _nationalIdController.text.trim(),
            femalesBelow18:
                int.tryParse(_femalesBelow18Controller.text) ?? 0,
            femalesAbove18:
                int.tryParse(_femalesAbove18Controller.text) ?? 0,
            malesBelow18: int.tryParse(_malesBelow18Controller.text) ?? 0,
            malesAbove18: int.tryParse(_malesAbove18Controller.text) ?? 0,
            cookingMethod: _selectedCookingMethod,
            otherCookstove: _hasOtherCookstove ? 'yes' : 'no',
            language: _selectedLanguage,
            readDoc: _readDoc ? 'yes' : 'no',
            readToYou: _readToYou ? 'yes' : 'no',
            understoodDoc: _understoodDoc ? 'yes' : 'no',
            nationalIdAttachment: _nationalIdImage?.path,
            signature: _signatureImage?.path,
            nationalIdTimestamp: _nationalIdTimestamp,
            signatureTimestamp: _signatureTimestamp,
            createdDate: DateTime.now().toUtc().toIso8601String(),
            createdBy: userId,
            modifiedDate: null,
            modifiedBy: null,
            status: 'active',
            sIsSync: 0,
          );

          await _beneficiaryRepo.insert(beneficiary);
          developer.log(
              'Beneficiary saved successfully with offline_id: $offlineId',
              name: 'BeneficiaryRegistration');
          
          // Reload the complete beneficiary data from database for potential sync
          // For new records, we need to find by offline_id since we don't have the database id yet
          final allBeneficiaries = await _beneficiaryRepo.getAll();
          final reloadedBeneficiary = allBeneficiaries.firstWhere(
            (b) => b.offlineId == offlineId,
            orElse: () => beneficiary,
          );
          developer.log('Reloaded complete beneficiary data from database', name: 'BeneficiaryRegistration');
          developer.log('Complete data ready for sync: ${reloadedBeneficiary.toJsonForSync()}', name: 'BeneficiaryRegistration');
        }

        setState(() => _isSaving = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode
                  ? 'Beneficiary updated successfully!'
                  : 'Registration saved successfully!'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
          context.pop();
        }
      } catch (e) {
        developer.log('Error saving beneficiary: $e',
            name: 'BeneficiaryRegistration');

        setState(() => _isSaving = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving registration: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEAF4EA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
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
                  bottomLeft: Radius.circular(150),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.black87, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          _isEditMode
                              ? 'Edit Beneficiary'
                              : 'Beneficiary Registration',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // FIX 1: replaced withValues(alpha:) → withOpacity()
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.question_mark, color: Colors.white, size: 12),
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
                          _buildTrainingSiteSection(),
                          const SizedBox(height: 20),
                          _buildPersonalInfoSection(),
                          const SizedBox(height: 20),
                          _buildDemographicsSection(),
                          const SizedBox(height: 20),
                          _buildCookingMethodSection(),
                          const SizedBox(height: 20),
                          _buildOtherCookstoveSection(),
                          const SizedBox(height: 20),
                          _buildNationalIdImageSection(),
                          const SizedBox(height: 20),
                          _buildLanguageSection(),
                          const SizedBox(height: 20),
                          _buildConsentSection(),
                          const SizedBox(height: 20),
                          _buildExpandableSections(),
                          const SizedBox(height: 20),
                          _buildSignatureSection(),
                          const SizedBox(height: 20),
                          _buildActionButtons(),
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

  Widget _buildTrainingSiteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'TRAINING SITE',
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
        SearchableDropdown<String>(
          value: _selectedTrainingSite,
          items: _trainingSites,
          itemLabel: (site) => site,
          onChanged: (value) =>
              setState(() => _selectedTrainingSite = value),
          hint: _isLoading
              ? 'Loading training sites...'
              : 'Select Site Location',
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'FIRST NAME',
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
                  _buildTextField(
                    controller: _firstNameController,
                    hint: 'Enter First Name',
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value!)) {
                        return 'Only alphabets are allowed';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final filtered =
                          value.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
                      if (filtered != value) {
                        _firstNameController.value = TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(
                              offset: filtered.length),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'LAST NAME',
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
                  _buildTextField(
                    controller: _lastNameController,
                    hint: 'Enter Last Name',
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value!)) {
                        return 'Only alphabets are allowed';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final filtered =
                          value.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
                      if (filtered != value) {
                        _lastNameController.value = TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(
                              offset: filtered.length),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            text: 'MOBILE NUMBER',
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
        _buildTextField(
          controller: _mobileController,
          hint: 'e.g. +91 9690989098',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required';
            final digits = value!.replaceAll(RegExp(r'[^\d]'), '');
            if (digits.length < 6) return 'Minimum 6 digits required';
            if (digits.length > 15) return 'Maximum 15 digits allowed';
            return null;
          },
          onChanged: (value) {
            final filtered =
                value.replaceAll(RegExp(r'[^\d+\-\s()]'), '');
            if (filtered != value) {
              _mobileController.value = TextEditingValue(
                text: filtered,
                selection:
                    TextSelection.collapsed(offset: filtered.length),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            text: 'NATIONAL ID',
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
            _buildTextField(
              controller: _nationalIdController,
              hint: 'e.g. A-000000 000',
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                final cleanValue =
                    value!.replaceAll(RegExp(r'[\s\-]'), '');
                if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleanValue)) {
                  return 'Only alphanumeric characters (A-Z, 0-9) are allowed';
                }
                // if (_isNationalIdDuplicate) {
                //   return 'This National ID already exists';
                // }
                return null;
              },
            ),
            if (_isNationalIdChecking)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey.shade600),
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
            if (!_isNationalIdChecking &&
                _nationalIdController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Row(
                  children: [
                    Icon(
                      _isNationalIdDuplicate
                          ? Icons.error
                          : Icons.check_circle,
                      size: 14,
                      color: _isNationalIdDuplicate
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isNationalIdDuplicate
                          ? 'Already exists'
                          : 'Available',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isNationalIdDuplicate
                            ? Colors.red
                            : Colors.green,
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

  Widget _buildDemographicsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'FEMALES -18',
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
                  _buildTextField(
                    controller: _femalesBelow18Controller,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final num = int.tryParse(value!);
                      if (num == null) return 'Only numbers allowed';
                      if (num < 0) return 'Negative numbers not allowed';
                      return null;
                    },
                    onChanged: (value) {
                      final filtered =
                          value.replaceAll(RegExp(r'[^\d]'), '');
                      if (filtered != value) {
                        _femalesBelow18Controller.value = TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(
                              offset: filtered.length),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'FEMALES +18',
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
                  _buildTextField(
                    controller: _femalesAbove18Controller,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final num = int.tryParse(value!);
                      if (num == null) return 'Only numbers allowed';
                      if (num < 0) return 'Negative numbers not allowed';
                      return null;
                    },
                    onChanged: (value) {
                      final filtered =
                          value.replaceAll(RegExp(r'[^\d]'), '');
                      if (filtered != value) {
                        _femalesAbove18Controller.value = TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(
                              offset: filtered.length),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'MALES -18',
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
                  _buildTextField(
                    controller: _malesBelow18Controller,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final num = int.tryParse(value!);
                      if (num == null) return 'Only numbers allowed';
                      if (num < 0) return 'Negative numbers not allowed';
                      return null;
                    },
                    onChanged: (value) {
                      final filtered =
                          value.replaceAll(RegExp(r'[^\d]'), '');
                      if (filtered != value) {
                        _malesBelow18Controller.value = TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(
                              offset: filtered.length),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'MALES +18',
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
                  _buildTextField(
                    controller: _malesAbove18Controller,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final num = int.tryParse(value!);
                      if (num == null) return 'Only numbers allowed';
                      if (num < 0) return 'Negative numbers not allowed';
                      return null;
                    },
                    onChanged: (value) {
                      final filtered =
                          value.replaceAll(RegExp(r'[^\d]'), '');
                      if (filtered != value) {
                        _malesAbove18Controller.value = TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(
                              offset: filtered.length),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCookingMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'COOKING METHOD',
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
        SimpleDropdown<String>(
          value: _selectedCookingMethod,
          items: _cookingMethods,
          itemLabel: (method) => method,
          onChanged: (value) =>
              setState(() => _selectedCookingMethod = value),
          hint: 'Select Cooking Method',
        ),
      ],
    );
  }

  Widget _buildOtherCookstoveSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.kitchen,
              color: Color(0xFF4CAF50),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OTHER COOKSTOVE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Any Other Cookstove From other suppliers?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: _hasOtherCookstove,
            onChanged: (value) => setState(() => _hasOtherCookstove = value),
            activeThumbColor: const Color(0xFF4CAF50),
            activeTrackColor: const Color(0xFF4CAF50).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNationalIdImageSection() {
    return _buildImageCaptureSection(
      title: 'NATIONAL ID IMAGE',
      isRequired: true,
      buttonText: 'Take National ID Image',
      image: _nationalIdImage,
      onTakePhoto: () => _takePhoto('National ID'),
      timestamp: _nationalIdTimestamp,
    );
  }

  Widget _buildImageCaptureSection({
    required String title,
    bool isRequired = false,
    required String buttonText,
    required File? image,
    required VoidCallback onTakePhoto,
    String? timestamp,
  }) {
    // Determine if we should display an image from server
    final String? imagePath = _getImagePathForTitle(title);
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
            children: [
              if (isRequired)
                const TextSpan(
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFE0E0E0),
                style: BorderStyle.solid,
                width: 2),
          ),
          child: Column(
            children: [
              if (!hasAnyImage) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: hasLocalImage
                      ? Image.file(image,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover)
                      : NetworkImageWithRetry(
                          imageUrl: '${ApiConstants.baseUrl}$imagePath',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Captured at ${_formatTimestamp(timestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton.icon(
            onPressed: onTakePhoto,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: Text(hasAnyImage ? 'Retake Photo' : 'Take Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'Ensure all details are clearly visible',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }
  
  // Helper method to get image path based on title
  String? _getImagePathForTitle(String title) {
    if (_existingBeneficiary == null) return null;
    
    if (title.contains('NATIONAL ID')) {
      return _existingBeneficiary!.nationalIdAttachment;
    } else if (title.contains('SIGNATURE')) {
      return _existingBeneficiary!.signature;
    }
    return null;
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

  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'PREFERRED LANGUAGE',
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
        SimpleDropdown<String>(
          value: _selectedLanguage,
          items: _languages,
          itemLabel: (lang) => lang,
          onChanged: (value) =>
              setState(() => _selectedLanguage = value ?? 'English'),
          hint: _isLoading ? 'Loading languages...' : 'Select Language',
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildConsentSection() {
    return Column(
      children: [
        _buildSwitchTile(
          title: 'WOULD YOU LIKE TO READ THIS?',
          value: _readDoc,
          onChanged: (value) => setState(() => _readDoc = value),
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          title: 'WOULD YOU LIKE IT READ TO YOU?',
          value: _readToYou,
          onChanged: (value) => setState(() => _readToYou = value),
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          title: 'HAS THE PERSON UNDERSTOOD THE DOCUMENT?',
          value: _understoodDoc,
          onChanged: (value) => setState(() => _understoodDoc = value),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSections() {
    return Column(
      children: [
        _buildExpandableSection(
          icon: Icons.description,
          title: 'TERMS & CONDITION',
          isExpanded: _termsExpanded,
          onTap: () => setState(() => _termsExpanded = !_termsExpanded),
          content:  Text(
            'Language: $_selectedLanguage\n'
            'Please get the individual to confirm he/she has clearly understood '
            'and accepted the terms of the FPIC documents by signing below.',
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        _buildExpandableSection(
          icon: Icons.gavel,
          title: 'LEGAL CONSENT DETAILS',
          isExpanded: _legalConsentExpanded,
          onTap: () => setState(
              () => _legalConsentExpanded = !_legalConsentExpanded),
          // FIX 3: Replaced raw multi-line string literal with explicit \n escapes
          content:  Text(
            'Language: $_selectedLanguage\n'
            'Waiver of Carbon Rights from Energy Efficient Cookstoves\n\n'
            'Confirmation of the Terms of this Waiver by Household Cookstove User\n\n'
            'By accepting and using my IAH Cookstoves and by signing or by making '
            'my mark on this waiver, I (the Household Cookstove User) agree as follows:\n\n'
            'I am the representative of the recipient household.\n\n'
            'I confirm that my household does not currently possess an energy efficient '
            'cookstove and that on the date of this waiver my household received two IAH '
            'Cookstoves from IAH.\n\n'
            'I agree to use my IAH Cookstoves for all of my household cooking.\n\n'
            'I understand that for IAH to pay for the production and delivery of the IAH '
            'Cookstoves, it is necessary for IAH to own the rights to the associated '
            'Emission Reductions generated by the use of the IAH Cookstoves.\n\n'
            'I hereby assign and transfer all rights, title and interest to the Emissions '
            'Reductions or other environmental or social attributes arising from my '
            'household\'s use of our IAH Cookstove to IAH and hereby permanently waive '
            'any claim or right to such Emissions Reductions and attributes. I understand '
            'that IAH may, at any time, transfer those rights to another person without '
            'further notice or consent.\n\n'
            'I consent to the collection, processing, storage and use of my personal and '
            'my household information, as provided in this waiver, by IAH for the purposes '
            'of calculating and selling Emissions Reductions from my IAH Cookstoves.\n\n'
            'I confirm that the information above has been explained to me in a language I understand.',
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon,
                        color: const Color(0xFF4CAF50), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    // Check if we have a server signature image
    final String? signaturePath = _existingBeneficiary?.signature;
    final bool hasServerSignature = signaturePath != null && signaturePath.startsWith('/uploads/');
    final bool hasLocalSignature = _signatureImage != null;
    final bool hasAnySignature = hasServerSignature || hasLocalSignature;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'SIGNATURE',
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
        
        // Show existing signature if available
        if (hasAnySignature) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBDBDBD)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: hasLocalSignature
                      ? Image.file(_signatureImage!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          colorBlendMode: BlendMode.darken)
                      : NetworkImageWithRetry(
                          imageUrl: '${ApiConstants.baseUrl}$signaturePath',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                ),
                if (_signatureTimestamp != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Captured at ${_formatTimestamp(_signatureTimestamp!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Clear existing signature to allow new one
                setState(() {
                  _signatureImage = null;
                  _signatureTimestamp = null;
                });
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Update Signature'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ] else ...[
          // Show signature pad for new signature
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBDBDBD)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SfSignaturePad(
                key: _signaturePadKey,
                backgroundColor: Colors.white,
                strokeColor: Colors.black,
                minimumStrokeWidth: 1.0,
                maximumStrokeWidth: 3.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _saveSignature,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Signature'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _clearSignature,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isEditMode ? 'Update Beneficiary' : 'Save Registration',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        cursorColor: Colors.green,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Colors.black38, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }
}