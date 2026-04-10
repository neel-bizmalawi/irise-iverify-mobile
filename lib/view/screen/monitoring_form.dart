import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../../data/repositories/beneficiary_repository.dart';
import '../../data/repositories/monitoring_repository.dart';
import '../../data/models/beneficiary.dart';
import '../../data/models/monitoring.dart';
import '../../core/utils/image_utils.dart';
import '../widgets/simple_dropdown.dart';

class MonitoringFormScreen extends StatefulWidget {
  const MonitoringFormScreen({super.key});

  @override
  State<MonitoringFormScreen> createState() => _MonitoringFormScreenState();
}

class _MonitoringFormScreenState extends State<MonitoringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final BeneficiaryRepository _beneficiaryRepo = BeneficiaryRepository();
  final MonitoringRepository _monitoringRepo = MonitoringRepository();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final _searchController = TextEditingController();
  final _newDeviceSerialNoController = TextEditingController();
  final _timesUsedTodayController = TextEditingController();
  final _dailyFuelCostController = TextEditingController();
  final _savings3MonthsController = TextEditingController();
  final _estFuelLast3mealsKgController = TextEditingController();
  final _trainingTypeController = TextEditingController();
  final _moreVisitsReasonController = TextEditingController();

  // Beneficiary selection
  List<Beneficiary> _beneficiaries = [];
  List<Beneficiary> _filteredBeneficiaries = [];
  Beneficiary? _selectedBeneficiary;

  // Physical Assessment toggles
  bool _hhNameSame = false;
  bool _stovesPresent = false;
  bool _stoveBeingUsed = false;

  // Dropdowns
  String? _stoveCondition;
  String? _userSatisfaction;
  String? _fuelType;

  // Training toggles
  bool _needsTraining = false;
  bool _trainingPerformed = false;
  bool _needsMoreVisits = false;

  // Health Assessment toggles
  bool _healthHospitalLess = false;
  bool _healthBetterAir = false;

  // GPS
  double? _latitude;
  double? _longitude;
  DateTime? _visitAt;

  // Image
  File? _cookstoveImage;
  String? _cookstoveImagePath;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
    _searchController.addListener(_filterBeneficiaries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newDeviceSerialNoController.dispose();
    _timesUsedTodayController.dispose();
    _dailyFuelCostController.dispose();
    _savings3MonthsController.dispose();
    _estFuelLast3mealsKgController.dispose();
    _trainingTypeController.dispose();
    _moreVisitsReasonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    try {
      final beneficiaries = await _beneficiaryRepo.getAll();
      developer.log('Loaded ${beneficiaries.length} beneficiaries from database', name: 'MonitoringForm');
      
      // Log some sample beneficiaries for debugging
      if (beneficiaries.isNotEmpty) {
        developer.log('Sample beneficiaries:', name: 'MonitoringForm');
        for (var i = 0; i < (beneficiaries.length > 5 ? 5 : beneficiaries.length); i++) {
          final b = beneficiaries[i];
          developer.log('  - ${b.firstName} ${b.lastName} (ID: ${b.nationalId})', name: 'MonitoringForm');
        }
      }
      
      setState(() {
        _beneficiaries = beneficiaries;
        _filteredBeneficiaries = [];
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading beneficiaries: $e', name: 'MonitoringForm');
      setState(() => _isLoading = false);
    }
  }

  void _filterBeneficiaries() {
    final query = _searchController.text.toLowerCase().trim();
    developer.log('Searching for: "$query"', name: 'MonitoringForm');
    
    setState(() {
      if (query.isEmpty) {
        _filteredBeneficiaries = [];
        developer.log('Search cleared, hiding results', name: 'MonitoringForm');
      } else {
        _filteredBeneficiaries = _beneficiaries.where((b) {
          final firstName = (b.firstName ?? '').toLowerCase();
          final lastName = (b.lastName ?? '').toLowerCase();
          final fullName = '$firstName $lastName';
          final nationalId = (b.nationalId ?? '').toLowerCase();
          return fullName.contains(query) || nationalId.contains(query);
        }).toList();
        developer.log('Found ${_filteredBeneficiaries.length} matching beneficiaries', name: 'MonitoringForm');
        
        // Log first few matches for debugging
        if (_filteredBeneficiaries.isNotEmpty) {
          developer.log('Matches:', name: 'MonitoringForm');
          for (var i = 0; i < (_filteredBeneficiaries.length > 3 ? 3 : _filteredBeneficiaries.length); i++) {
            final b = _filteredBeneficiaries[i];
            developer.log('  - ${b.firstName} ${b.lastName} (ID: ${b.nationalId})', name: 'MonitoringForm');
          }
        }
      }
    });
  }

  void _selectBeneficiary(Beneficiary beneficiary) {
    setState(() {
      _selectedBeneficiary = beneficiary;
      _searchController.clear();
      _filteredBeneficiaries = [];
    });
  }

  Future<void> _captureGPS() async {
    try {
      var permission = await Permission.location.status;
      if (permission.isDenied) {
        permission = await Permission.location.request();
      }
      if (!permission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) Navigator.of(context).pop();

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _visitAt = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'GPS captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
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

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

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

      final compressedPath = await ImageUtils.saveCompressedImage(
        File(pickedFile.path),
        prefix: 'monitoring_cookstove',
        targetSizeKB: 500,
      );

      if (mounted) Navigator.of(context).pop();

      if (compressedPath != null) {
        final fileSizeKB = await ImageUtils.getFileSizeKB(compressedPath);
        setState(() {
          _cookstoveImage = File(compressedPath);
          _cookstoveImagePath = compressedPath;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Cookstove image captured (${fileSizeKB.toStringAsFixed(1)} KB)'),
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
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveMonitoring() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBeneficiary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a beneficiary'),
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

      if (_cookstoveImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please capture cookstove photo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate all required dropdowns
      if (_timesUsedTodayController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select how many times the stove was used today'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_stoveCondition == null || _stoveCondition!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the stove condition'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_userSatisfaction == null || _userSatisfaction!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select user satisfaction'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_fuelType == null || _fuelType!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select fuel type'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate required text fields
      if (_dailyFuelCostController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter daily fuel cost'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_savings3MonthsController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter savings over 3 months'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_estFuelLast3mealsKgController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter estimated fuel for last 3 meals'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate conditional fields
      if (_needsTraining && _trainingTypeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please specify the training type'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_needsMoreVisits && _moreVisitsReasonController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please specify the reason for more visits'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isSaving = true);

      try {
        // Create Monitoring object
        final monitoring = Monitoring(
          beneficiaryId: _selectedBeneficiary!.beneficiaryId,
          nationalId: _selectedBeneficiary!.nationalId,
          agentName: _selectedBeneficiary!.firstName != null && _selectedBeneficiary!.lastName != null
              ? '${_selectedBeneficiary!.firstName} ${_selectedBeneficiary!.lastName}'
              : null,
          visitAt: _visitAt?.toIso8601String(),
          oldGpsLat: _selectedBeneficiary!.latitude?.toString(),
          oldGpsLng: _selectedBeneficiary!.longitude?.toString(),
          newGpsLat: _latitude.toString(),
          newGpsLng: _longitude.toString(),
          deviceSerialNo: _selectedBeneficiary!.deviceSerialNo,
          newDeviceSerialNo: _newDeviceSerialNoController.text.trim().isEmpty 
              ? null 
              : _newDeviceSerialNoController.text.trim(),
          hhNameSame: _hhNameSame ? 'Yes' : 'No',
          stovesPresent: _stovesPresent ? 'yes' : 'no',
          stoveBeingUsed: _stoveBeingUsed ? 'yes' : 'no',
          timesUsedToday: _timesUsedTodayController.text.isEmpty 
              ? null 
              : int.tryParse(_timesUsedTodayController.text),
          stoveCondition: _stoveCondition,
          photoPath: _cookstoveImagePath,
          userSatisfaction: _userSatisfaction,
          fuelType: _fuelType,
          dailyFuelCost: _dailyFuelCostController.text.isEmpty 
              ? null 
              : int.tryParse(_dailyFuelCostController.text),
          savings3Months: _savings3MonthsController.text.isEmpty 
              ? null 
              : int.tryParse(_savings3MonthsController.text),
          estFuelLast3mealsKg: _estFuelLast3mealsKgController.text.isEmpty 
              ? null 
              : int.tryParse(_estFuelLast3mealsKgController.text),
          needsTraining: _needsTraining ? 'Yes' : 'No',
          trainingType: _trainingTypeController.text.trim().isEmpty 
              ? null 
              : _trainingTypeController.text.trim(),
          trainingPerformed: _trainingPerformed ? 'Yes' : 'No',
          needsMoreVisits: _needsMoreVisits ? 'Yes' : 'No',
          moreVisitsReason: _moreVisitsReasonController.text.trim().isEmpty 
              ? null 
              : _moreVisitsReasonController.text.trim(),
          healthHospitalLess: _healthHospitalLess ? 'Yes' : 'No',
          healthBetterAir: _healthBetterAir ? 'Yes' : 'No',
          sIsSync: 0, // Mark as unsynced
          status: 'active',
          createdDate: DateTime.now().toIso8601String(),
        );

        // Save to local database
        await _monitoringRepo.insert(monitoring);

        setState(() => _isSaving = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Monitoring saved successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          context.pop(true); // Return true to indicate success
        }
      } catch (e) {
        developer.log('Error saving monitoring: $e', name: 'MonitoringForm');
        setState(() => _isSaving = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving monitoring: $e'),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4EA),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 90,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(90),
                ),
              ),
              // child: const Padding(
              //   padding: EdgeInsets.only(left: 30, top: 30),
              //   child: Icon(
              //     Icons.help_outline,
              //     color: Colors.white,
              //     size: 24,
              //   ),
              // ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Monitoring Form',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.question_mark,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBeneficiarySearch(),
                          if (_selectedBeneficiary != null) ...[
                            const SizedBox(height: 16),
                            _buildSelectedBeneficiaryCard(),
                          ],
                          const SizedBox(height: 20),
                          _buildUpdateSerialNumber(),
                          const SizedBox(height: 20),
                          _buildPhysicalAssessments(),
                          const SizedBox(height: 20),
                          _buildTechnicalAssessment(),
                          const SizedBox(height: 20),
                          _buildUserSatisfaction(),
                          const SizedBox(height: 20),
                          _buildEconomicalAssessment(),
                          const SizedBox(height: 20),
                          _buildTraining(),
                          const SizedBox(height: 20),
                          _buildHealthAssessment(),
                          const SizedBox(height: 20),
                          _buildOtherData(),
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

  Widget _buildBeneficiarySearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by Name or National ID...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_filteredBeneficiaries.isNotEmpty && _searchController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredBeneficiaries.length,
              itemBuilder: (context, index) {
                final beneficiary = _filteredBeneficiaries[index];
                return ListTile(
                  title: Text('${beneficiary.firstName} ${beneficiary.lastName}'),
                  subtitle: Text('ID: ${beneficiary.nationalId ?? 'N/A'}'),
                  onTap: () => _selectBeneficiary(beneficiary),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedBeneficiaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Beneficiary',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedBeneficiary!.firstName ?? ''} ${_selectedBeneficiary!.lastName ?? ''}'.trim(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                onPressed: () => setState(() => _selectedBeneficiary = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // Beneficiary Details
          _buildDetailRow('National ID', _selectedBeneficiary!.nationalId ?? 'N/A'),
          const SizedBox(height: 12),
          _buildDetailRow('Mobile Number', _selectedBeneficiary!.mobileNo ?? 'N/A'),
          const SizedBox(height: 12),
          _buildDetailRow('Training Site', _selectedBeneficiary!.trainingSite ?? 'N/A'),
          const SizedBox(height: 12),
          _buildDetailRow('Device Serial No', _selectedBeneficiary!.deviceSerialNo ?? 'N/A'),
          const SizedBox(height: 12),
          _buildDetailRow('Cooking Method', _selectedBeneficiary!.cookingMethod ?? 'N/A'),
          
          if (_selectedBeneficiary!.latitude != null && _selectedBeneficiary!.longitude != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'GPS Location',
              '${_selectedBeneficiary!.latitude}, ${_selectedBeneficiary!.longitude}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateSerialNumber() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Serial Number',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newDeviceSerialNoController,
          decoration: InputDecoration(
            hintText: 'Enter new device serial number',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhysicalAssessments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PHYSICAL ASSESSMENTS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildToggle(
          'Is the household name the same as when cookstove were registered?',
          _hhNameSame,
          (value) => setState(() => _hhNameSame = value),
        ),
        const SizedBox(height: 12),
        _buildToggle(
          'Are the cookstove physically present?',
          _stovesPresent,
          (value) => setState(() => _stovesPresent = value),
        ),
        const SizedBox(height: 12),
        _buildToggle(
          'Are cookstove being used?',
          _stoveBeingUsed,
          (value) => setState(() => _stoveBeingUsed = value),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            text: 'How Many times was the stove used today?',
            style: TextStyle(fontSize: 13, color: Colors.black87),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _timesUsedTodayController.text.isEmpty ? null : _timesUsedTodayController.text,
          items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
          onChanged: (value) => setState(() => _timesUsedTodayController.text = value ?? ''),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            text: 'Please indicate the overall condition of cookstove',
            style: TextStyle(fontSize: 13, color: Colors.black87),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _stoveCondition,
          items: ['Good', 'Fair', 'Repair', 'Replace'],
          onChanged: (value) => setState(() => _stoveCondition = value),
        ),
      ],
    );
  }

  Widget _buildTechnicalAssessment() {
    final bool hasImage = _cookstoveImage != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TECHNICAL ASSESSMENT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'TAKE COOKSTOVE PHOTO',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        // Image Preview Container with border
        GestureDetector(
          onTap: hasImage ? () => _showImagePreview(context, _cookstoveImage) : null,
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
                          child: Image.file(_cookstoveImage!, fit: BoxFit.cover),
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
            onPressed: _takePhoto,
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
                  _cookstoveImage = null;
                  _cookstoveImagePath = null;
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

  Widget _buildUserSatisfaction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'User Satisfaction/feedback',
            style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _userSatisfaction,
          items: ['Happy', 'Satisfied', 'Neutral', 'Unsatisfied'],
          onChanged: (value) => setState(() => _userSatisfaction = value),
        ),
      ],
    );
  }

  Widget _buildEconomicalAssessment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ECONOMICAL ASSESSMENT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            text: 'Please indicate that type of fuel being used',
            style: TextStyle(fontSize: 13, color: Colors.black87),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _fuelType,
          items: ['Wood', 'Charcoal', 'Exotic Wood', 'Other'],
          onChanged: (value) => setState(() => _fuelType = value),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            text: 'Indicate daily fuel usage in terms of costs',
            style: TextStyle(fontSize: 13, color: Colors.black87),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dailyFuelCostController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter daily fuel cost',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Daily fuel cost is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            text: 'Please indicate how much you have saved over 3 months of using the e-cookstoves (MK in Thousands)',
            style: TextStyle(fontSize: 13, color: Colors.black87),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _savings3MonthsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter savings amount',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Savings amount is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            text: 'Estimated fuel used for last 3 meals (KG)',
            style: TextStyle(fontSize: 13, color: Colors.black87),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _estFuelLast3mealsKgController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter estimated fuel in KG',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Estimated fuel is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTraining() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRAINING',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildToggle(
          'Does the HH need additional training?',
          _needsTraining,
          (value) => setState(() => _needsTraining = value),
        ),
        if (_needsTraining) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _trainingTypeController,
            decoration: InputDecoration(
              hintText: 'Specify training type',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildToggle(
            'Training performed?',
            _trainingPerformed,
            (value) => setState(() => _trainingPerformed = value),
          ),
        ],
        const SizedBox(height: 12),
        _buildToggle(
          'Does the HH need more frequent visits?',
          _needsMoreVisits,
          (value) => setState(() => _needsMoreVisits = value),
        ),
        if (_needsMoreVisits) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _moreVisitsReasonController,
            decoration: InputDecoration(
              hintText: 'Specify reason for more visits',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHealthAssessment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HEALTH ASSESSMENT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildToggle(
          'Have you been to the hospital less since you received the cookstove?',
          _healthHospitalLess,
          (value) => setState(() => _healthHospitalLess = value),
        ),
        const SizedBox(height: 12),
        _buildToggle(
          'Have you felt the benefits of breathing better air?',
          _healthBetterAir,
          (value) => setState(() => _healthBetterAir = value),
        ),
      ],
    );
  }

  Widget _buildOtherData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OTHER DATA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPS: ${_latitude != null && _longitude != null ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}' : '-----, -----'}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _captureGPS,
              icon: const Icon(Icons.my_location, color: Colors.white, size: 18),
              label: const Text('Capture GPS', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SimpleDropdown<String>(
      value: value,
      items: items,
      itemLabel: (item) => item,
      onChanged: onChanged,
      hint: 'Select option',
      isLoading: false,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isSaving ? null : _saveMonitoring,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            minimumSize: const Size(double.infinity, 50),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save Monitoring',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
}
