import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../../data/repositories/audit_repository.dart';
import '../../data/models/audit.dart';
import '../../core/utils/image_utils.dart';
import '../widgets/simple_dropdown.dart';

class AuditFormScreen extends StatefulWidget {
  const AuditFormScreen({super.key});

  @override
  State<AuditFormScreen> createState() => _AuditFormScreenState();
}

class _AuditFormScreenState extends State<AuditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _auditRepository = AuditRepository();

  // Controllers
  final _householdNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _femalesBelow18Controller = TextEditingController(text: '');
  final _femalesAbove18Controller = TextEditingController(text: '');
  final _malesBelow18Controller = TextEditingController(text: '');
  final _malesAbove18Controller = TextEditingController(text: '');
  final _whereTrainedController = TextEditingController();
  final _whereReceivedController = TextEditingController();

  // Dates
  DateTime? _visitDate;
  DateTime? _cookstoveReceivedDate;

  // Dropdowns
  String? _cookingMethodBefore;
  String? _fuelUsedBefore;

  // Toggles
  bool _hasCookstoveObserve = false;
  bool _otherCookingDevice = false;
  bool _paymentRequested = false;
  bool _trainingBeforeReceiving = false;
  bool _readConsent = false;
  bool _signConsent = false;
  bool _deliveredCondition = false;

  // GPS
  double? _latitude;
  double? _longitude;
  bool _isCapturingGPS = false;

  // Images
  File? _cookStoveImage;
  File? _cookStoveAreaImage;
  String? _cookStoveImagePath;
  String? _cookStoveAreaImagePath;

  // Loading
  bool _isSaving = false;

  final List<String> _cookingMethods = [
    'Threestone Fire',
    'Traditional Stove',
    'Gas Stove',
    'Electric Stove',
    'Other',
  ];

  final List<String> _fuelTypes = [
    'Charcol',
    'Firewood',
    'Gas',
    'Electricity',
    'Other',
  ];

  @override
  void dispose() {
    _householdNameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _femalesBelow18Controller.dispose();
    _femalesAbove18Controller.dispose();
    _malesBelow18Controller.dispose();
    _malesAbove18Controller.dispose();
    _whereTrainedController.dispose();
    _whereReceivedController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isVisitDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isVisitDate) {
          _visitDate = picked;
        } else {
          _cookstoveReceivedDate = picked;
        }
      });
    }
  }

  Future<void> _captureGPS() async {
    setState(() => _isCapturingGPS = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isCapturingGPS = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS captured successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCapturingGPS = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture GPS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(bool isCookStove) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return;

      // Validate file extension
      final extension = image.path.toLowerCase().split('.').last;
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

      // Show loading indicator
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
        File(image.path),
        prefix: isCookStove ? 'audit_cookstove' : 'audit_cookstove_area',
        targetSizeKB: 500,
      );

      if (mounted) Navigator.of(context).pop();

      if (compressedPath != null) {
        final fileSizeKB = await ImageUtils.getFileSizeKB(compressedPath);
        setState(() {
          if (isCookStove) {
            _cookStoveImage = File(compressedPath);
            _cookStoveImagePath = compressedPath;
          } else {
            _cookStoveAreaImage = File(compressedPath);
            _cookStoveAreaImagePath = compressedPath;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${isCookStove ? 'Cookstove' : 'Cookstove area'} image captured (${fileSizeKB.toStringAsFixed(1)} KB)',
              ),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAudit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select visit date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture GPS location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_cookStoveImagePath == null || _cookStoveAreaImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture both stove images'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create Audit object
      final audit = Audit(
        householdName: _householdNameController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        visitDate: _visitDate!.toIso8601String(),
        femalesBelow18: int.tryParse(_femalesBelow18Controller.text) ?? 0,
        femalesAbove18: int.tryParse(_femalesAbove18Controller.text) ?? 0,
        malesBelow18: int.tryParse(_malesBelow18Controller.text) ?? 0,
        malesAbove18: int.tryParse(_malesAbove18Controller.text) ?? 0,
        hasCookstoveObserve: _hasCookstoveObserve ? 'yes' : 'no',
        cookingMethodBefore: _cookingMethodBefore,
        fuelUsedBefore: _fuelUsedBefore,
        otherCookingDeviceBefore: _otherCookingDevice ? 'yes' : 'no',
        paymentRequested: _paymentRequested ? 'yes' : 'no',
        paymentRequestedBy: _paymentRequested ? _householdNameController.text.trim() : null,
        trainingBeforeReceiving: _trainingBeforeReceiving ? 'yes' : 'no',
        readConset: _readConsent ? 'yes' : 'no',
        signConsent: _signConsent ? 'yes' : 'no',
        deliveredCondition: _deliveredCondition ? 'yes' : 'no',
        dateOfCookstoveRecieved: _cookstoveReceivedDate?.toIso8601String(),
        whereReceived: _whereReceivedController.text.trim().isEmpty 
            ? null 
            : _whereReceivedController.text.trim(),
        whereTrained: _whereTrainedController.text.trim().isEmpty 
            ? null 
            : _whereTrainedController.text.trim(),
        latitude: _latitude.toString(),
        longitude: _longitude.toString(),
        photoPathCookStove: _cookStoveImagePath,
        photoPathCookStoveArea: _cookStoveAreaImagePath,
        sIsSync: 0, // Mark as unsynced
        status: 'active',
        createdDate: DateTime.now().toIso8601String(),
      );

      // Save to local database
      await _auditRepository.insert(audit);

      developer.log('Audit saved to local database successfully', name: 'AuditForm');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit saved successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      developer.log('Error saving audit: $e', name: 'AuditForm');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save audit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // Top bar
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
                          'Audit Process',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
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

                // Form
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildTextField(
                          label: 'HOUSEHOLD NAME',
                          controller: _householdNameController,
                          hint: 'Enter Household Name',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Household name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'NATIONAL ID',
                          controller: _nationalIdController,
                          hint: 'Enter National ID',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'National ID is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'MOBILE NUMBER',
                          controller: _phoneController,
                          hint: 'e.g. +91 9890989098',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Mobile number is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildDateField(
                          label: 'DATE OF VISIT',
                          hint: 'Select Date',
                          date: _visitDate,
                          onTap: () => _selectDate(context, true),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'FEMALES -18',
                                controller: _femalesBelow18Controller,
                                hint: '0',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'FEMALES +18',
                                controller: _femalesAbove18Controller,
                                hint: '0',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'MALES -18',
                                controller: _malesBelow18Controller,
                                hint: '0',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'MALES +18',
                                controller: _malesAbove18Controller,
                                hint: '0',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: 'COOKING METHOD BEFORE RECEIVING COOKSTOVE.',
                          value: _cookingMethodBefore,
                          items: _cookingMethods,
                          hint: 'Select Cooking Method',
                          onChanged: (value) => setState(() => _cookingMethodBefore = value),
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: 'FUEL USED BEFORE RECEIVING COOKSTOVE.',
                          value: _fuelUsedBefore,
                          items: _fuelTypes,
                          hint: 'Select Fuel',
                          onChanged: (value) => setState(() => _fuelUsedBefore = value),
                        ),
                        const SizedBox(height: 16),

                        _buildToggle(
                          label: 'Other Cooking device before',
                          value: _otherCookingDevice,
                          onChanged: (value) => setState(() => _otherCookingDevice = value),
                        ),
                        const SizedBox(height: 8),

                        _buildToggle(
                          label: 'Was any payment requested for the cookstove?',
                          value: _paymentRequested,
                          onChanged: (value) => setState(() => _paymentRequested = value),
                        ),
                        const SizedBox(height: 8),

                        _buildToggle(
                          label: 'Did HH undergo training before receiving cookstove?',
                          value: _trainingBeforeReceiving,
                          onChanged: (value) => setState(() => _trainingBeforeReceiving = value),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'WHERE TRAINED (LOCATION)',
                          controller: _whereTrainedController,
                          hint: 'Enter Trained Location',
                        ),
                        const SizedBox(height: 16),

                        _buildDateField(
                          label: 'DATE OF COOKSTOVE RECEIVED',
                          hint: 'Select Date',
                          date: _cookstoveReceivedDate,
                          onTap: () => _selectDate(context, false),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'WHERE RECEIVED (LOCATION)',
                          controller: _whereReceivedController,
                          hint: 'Enter Received Location',
                        ),
                        const SizedBox(height: 16),

                        _buildToggle(
                          label: 'Was the Consent Form Read to you?',
                          value: _readConsent,
                          onChanged: (value) => setState(() => _readConsent = value),
                        ),
                        const SizedBox(height: 8),

                        _buildToggle(
                          label: 'Did HH agree/ sign consent form?',
                          value: _signConsent,
                          onChanged: (value) => setState(() => _signConsent = value),
                        ),
                        const SizedBox(height: 8),

                        _buildToggle(
                          label: 'Was Stove delivered in good condition?',
                          value: _deliveredCondition,
                          onChanged: (value) => setState(() => _deliveredCondition = value),
                        ),
                        const SizedBox(height: 16),

                        _buildGPSSection(),
                        const SizedBox(height: 16),

                        _buildImageCapture(
                          label: 'TAKE PHOTO OF STOVE',
                          image: _cookStoveImage,
                          onTap: () => _pickImage(true),
                        ),
                        const SizedBox(height: 16),

                        _buildImageCapture(
                          label: 'TAKE PHOTO OF STOVE AREA',
                          image: _cookStoveAreaImage,
                          onTap: () => _pickImage(false),
                        ),
                        const SizedBox(height: 24),

                        _buildSaveButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                        : hint,
                    style: TextStyle(
                      color: date != null ? Colors.black87 : Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today, color: Color(0xFF4CAF50), size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        SimpleDropdown<String>(
          value: value,
          items: items,
          itemLabel: (item) => item,
          onChanged: onChanged,
          hint: hint,
          isLoading: false,
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
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

  Widget _buildGPSSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _latitude != null && _longitude != null
                    ? 'GPS: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                    : 'GPS: ------, ------',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isCapturingGPS ? null : _captureGPS,
              icon: _isCapturingGPS
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: const Text('Capture GPS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageCapture({
    required String label,
    required File? image,
    required VoidCallback onTap,
  }) {
    final bool hasImage = image != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        // Image Preview Container with border
        GestureDetector(
          onTap: hasImage ? () => _showImagePreview(context, image) : null,
          child: Container(
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
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(image, fit: BoxFit.cover),
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
                if (hasImage)
                  IgnorePointer(
                    child: Container(
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
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Take Photo / Retake Button (full width)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: Text(hasImage ? 'Retake' : 'Take Photo'),
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
        
        // Remove Button (only show if image exists)
        if (hasImage) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  if (label.contains('STOVE AREA')) {
                    _cookStoveAreaImage = null;
                    _cookStoveAreaImagePath = null;
                  } else {
                    _cookStoveImage = null;
                    _cookStoveImagePath = null;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image removed'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
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
        ],
        
        // Info message
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'Ensure all details are clearly visible',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  void _showImagePreview(BuildContext context, File? localImage) {
    if (localImage == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(localImage),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveAudit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
