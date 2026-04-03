import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:irise/data/services/data_service.dart';
import 'package:irise/data/models/district.dart';
import 'package:irise/data/models/authority.dart';
import 'package:irise/data/models/training_site.dart';
import 'package:irise/data/repositories/training_site_repository.dart';
import 'package:irise/view/widgets/searchable_dropdown.dart';
import 'package:irise/route/app_routes.dart';
import 'dart:developer' as developer;

class TrainingPointIdentificationScreen extends StatefulWidget {
  final String? trainingPointId; // Can be training_point_id or offline_id
  
  const TrainingPointIdentificationScreen({
    super.key,
    this.trainingPointId,
  });

  @override
  State<TrainingPointIdentificationScreen> createState() =>
      _TrainingPointIdentificationScreenState();
}

class _TrainingPointIdentificationScreenState
    extends State<TrainingPointIdentificationScreen> {
  final DataService _dataService = DataService();
  final TrainingSiteRepository _trainingSiteRepository = TrainingSiteRepository();
  
  District? _selectedDistrict;
  Authority? _selectedAuthority;
  bool _roadAccess = false;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _hasServerData = false; // Track if server data exists
  bool _isCheckingServerData = true; // Track if we're checking for server data
  bool _isEditMode = false; // Track if we're editing an existing training site
  TrainingSite? _existingTrainingSite; // Store the existing training site being edited
  
  List<District> _districts = [];
  List<Authority> _authorities = [];
  bool _isLoadingDistricts = false;
  bool _isLoadingAuthorities = false;

  final _trainingSiteNameController = TextEditingController();
  final _villageHeadController = TextEditingController();
  final _groupVillageController = TextEditingController();
  final _householdCountController = TextEditingController();
  final _cookstoveCountController = TextEditingController();
  final _householdRadiusController = TextEditingController();
  final _totalPopulationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkServerDataAvailability();
    _loadDistricts();
    _loadAuthorities();
    
    // Load existing training site if trainingPointId is provided
    if (widget.trainingPointId != null) {
      _loadExistingTrainingSite();
    }
  }

  Future<void> _loadExistingTrainingSite() async {
    try {
      final id = int.tryParse(widget.trainingPointId!);
      if (id == null) return;
      
      // Try to find by training_point_id first
      TrainingSite? site = await _trainingSiteRepository.getById(id);
      
      // If not found, try to find by offline_id
      if (site == null) {
        final allSites = await _trainingSiteRepository.getAll();
        try {
          site = allSites.firstWhere(
            (s) => s.offlineId == id,
            orElse: () => allSites.firstWhere(
              (s) => s.trainingPointId == id,
            ),
          );
        } catch (e) {
          developer.log('Training site not found with id: $id', name: 'TrainingPointIdentification');
          return;
        }
      }
      
      // Pre-fill form fields
      setState(() {
        _isEditMode = true;
        _existingTrainingSite = site;
        
        _trainingSiteNameController.text = site?.trainingSite ?? '';
        _villageHeadController.text = site?.villageHeadName ?? '';
        _groupVillageController.text = site?.gvhName ?? '';
        _householdCountController.text = site?.houseHoldsCount?.toString() ?? '';
        _cookstoveCountController.text = site?.cookstovesCount?.toString() ?? '';
        _householdRadiusController.text = site?.houseHoldRadius?.toString() ?? '';
        _totalPopulationController.text = site?.totalPeople?.toString() ?? '';
        _latitudeController.text = site?.latitude?.toString() ?? '';
        _longitudeController.text = site?.longitude?.toString() ?? '';
        _roadAccess = site?.roadAccess == 'yes';
      });
      
      // Set district and authority after they're loaded
      _setDistrictAndAuthority(site);
    } catch (e) {
      developer.log('Error loading existing training site: $e', name: 'TrainingPointIdentification');
      _showErrorSnackBar('Failed to load training site data');
    }
  }

  void _setDistrictAndAuthority(TrainingSite site) {
    // Find and set district
    if (site.district != null && _districts.isNotEmpty) {
      final district = _districts.firstWhere(
        (d) => d.districtName == site.district,
        orElse: () => _districts.first,
      );
      setState(() {
        _selectedDistrict = district;
      });
    }
    
    // Find and set authority
    if (site.traditionalAuthority != null && _authorities.isNotEmpty) {
      final authority = _authorities.firstWhere(
        (a) => a.authorityName == site.traditionalAuthority,
        orElse: () => _authorities.first,
      );
      setState(() {
        _selectedAuthority = authority;
      });
    }
  }

  Future<void> _checkServerDataAvailability() async {
    setState(() {
      _isCheckingServerData = true;
    });

    try {
      final verificationResult = await _dataService.verifyDataPersistence();
      setState(() {
        _hasServerData = verificationResult.success && verificationResult.data == true;
        _isCheckingServerData = false;
      });
    } catch (e) {
      setState(() {
        _hasServerData = false;
        _isCheckingServerData = false;
      });
    }
  }

  Future<void> _loadDistricts() async {
    setState(() {
      _isLoadingDistricts = true;
    });

    try {
      // Load districts from local database (already synced on dashboard load)
      final response = await _dataService.getDistrictsFromLocal();
      if (response.success && response.data != null) {
        setState(() {
          _districts = response.data!;
        });
        developer.log('Loaded ${_districts.length} districts from local database', name: 'TrainingPointIdentification');
        
        // Set district if in edit mode
        if (_isEditMode && _existingTrainingSite != null) {
          _setDistrictAndAuthority(_existingTrainingSite!);
        }
      } else {
        _showErrorSnackBar('Failed to load districts: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading districts: $e');
    } finally {
      setState(() {
        _isLoadingDistricts = false;
      });
    }
  }

  Future<void> _loadAuthorities() async {
    setState(() {
      _isLoadingAuthorities = true;
    });

    try {
      // Load authorities from local database (already synced on dashboard load)
      final response = await _dataService.getAuthoritiesFromLocal();
      if (response.success && response.data != null) {
        setState(() {
          _authorities = response.data!;
        });
        developer.log('Loaded ${_authorities.length} authorities from local database', name: 'TrainingPointIdentification');
        
        // Set authority if in edit mode
        if (_isEditMode && _existingTrainingSite != null) {
          _setDistrictAndAuthority(_existingTrainingSite!);
        }
      } else {
        _showErrorSnackBar('Failed to load authorities: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading authorities: $e');
    } finally {
      setState(() {
        _isLoadingAuthorities = false;
      });
    }
  }

  void _onDistrictChanged(District? district) {
    setState(() {
      _selectedDistrict = district;
      // Don't clear authority selection since we're loading all authorities
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permission permanently denied. Please enable in settings.');
        return;
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled. Please enable location services.');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(8);
        _longitudeController.text = position.longitude.toStringAsFixed(8);
      });

      _showSuccessSnackBar('Location fetched successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to get location: $e');
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  bool _validateForm() {
    if (_trainingSiteNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Training site name is required');
      return false;
    }

    if (_selectedDistrict == null) {
      _showErrorSnackBar('District selection is required');
      return false;
    }

    if (_villageHeadController.text.trim().isEmpty) {
      _showErrorSnackBar('Village head name is required');
      return false;
    }

    if (_groupVillageController.text.trim().isEmpty) {
      _showErrorSnackBar('Group village head name is required');
      return false;
    }

    if (_selectedAuthority == null) {
      _showErrorSnackBar('Traditional authority selection is required');
      return false;
    }

    if (_householdCountController.text.trim().isEmpty || 
        int.tryParse(_householdCountController.text.trim()) == null) {
      _showErrorSnackBar('Valid household count is required');
      return false;
    }

    if (_cookstoveCountController.text.trim().isEmpty || 
        int.tryParse(_cookstoveCountController.text.trim()) == null) {
      _showErrorSnackBar('Valid cookstove count is required');
      return false;
    }

    if (_householdRadiusController.text.trim().isEmpty || 
        int.tryParse(_householdRadiusController.text.trim()) == null) {
      _showErrorSnackBar('Valid household radius is required');
      return false;
    }

    if (_totalPopulationController.text.trim().isEmpty || 
        int.tryParse(_totalPopulationController.text.trim()) == null) {
      _showErrorSnackBar('Valid total population is required');
      return false;
    }

    if (_latitudeController.text.trim().isEmpty || 
        double.tryParse(_latitudeController.text.trim()) == null) {
      _showErrorSnackBar('Please capture GPS location');
      return false;
    }

    if (_longitudeController.text.trim().isEmpty || 
        double.tryParse(_longitudeController.text.trim()) == null) {
      _showErrorSnackBar('Please capture GPS location');
      return false;
    }

    return true;
  }

  Future<void> _saveTrainingSite() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // CRITICAL: Verify that data has been synced from server before allowing save
      final verificationResult = await _dataService.verifyDataPersistence();
      
      if (!verificationResult.success || verificationResult.data != true) {
        if (!mounted) return;
        
        // Show dialog explaining that sync is required first
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.sync_problem, color: Color(0xFFFF9800), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Sync Required',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You must sync data from the server before creating training sites.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFB74D)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To sync data:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Go to the Dashboard',
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '2. Tap the Sync button',
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '3. Wait for sync to complete',
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '4. Return here to create training sites',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to dashboard
                    context.go(AppRoutes.dashboard);
                  },
                  child: const Text(
                    'Go to Dashboard',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            );
          },
        );
        
        return;
      }
      
      // Data is synced, proceed with save or update
      // Get current time in UTC
      final now = DateTime.now().toUtc().toIso8601String();
      
      if (_isEditMode && _existingTrainingSite != null) {
        // UPDATE existing training site
        final existingSite = _existingTrainingSite!;
        final updatedSite = existingSite.copyWith(
          trainingSite: _trainingSiteNameController.text.trim(),
          district: _selectedDistrict!.districtName,
          villageHeadName: _villageHeadController.text.trim(),
          gvhName: _groupVillageController.text.trim(),
          traditionalAuthority: _selectedAuthority!.authorityName,
          houseHoldsCount: int.parse(_householdCountController.text.trim()),
          cookstovesCount: int.parse(_cookstoveCountController.text.trim()),
          houseHoldRadius: int.parse(_householdRadiusController.text.trim()),
          totalPeople: int.parse(_totalPopulationController.text.trim()),
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
          roadAccess: _roadAccess ? 'yes' : 'no',
          modifiedDate: now,
          sIsSync: 0, // Mark as unsynced since it was updated
        );

        await _trainingSiteRepository.update(updatedSite);

        if (!mounted) return;
        
        // Show success message
        _showSuccessSnackBar('Training site updated successfully');
        
        // Wait a moment for the snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate back to conduct training screen
        if (!mounted) return;
        context.go(AppRoutes.conduct_training_list);
      } else {
        // CREATE new training site
        // Generate simple sequential offline_id
        final offlineId = await _trainingSiteRepository.getNextOfflineId();

        final trainingSite = TrainingSite(
          trainingSite: _trainingSiteNameController.text.trim(),
          district: _selectedDistrict!.districtName,
          villageHeadName: _villageHeadController.text.trim(),
          gvhName: _groupVillageController.text.trim(),
          traditionalAuthority: _selectedAuthority!.authorityName,
          houseHoldsCount: int.parse(_householdCountController.text.trim()),
          cookstovesCount: int.parse(_cookstoveCountController.text.trim()),
          houseHoldRadius: int.parse(_householdRadiusController.text.trim()),
          totalPeople: int.parse(_totalPopulationController.text.trim()),
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
          roadAccess: _roadAccess ? 'yes' : 'no',
          createdDate: now,
          modifiedDate: now,
          offlineId: offlineId,
          sIsSync: 0, // Not synced yet
          status: 'active',
        );

        await _trainingSiteRepository.insert(trainingSite);

        if (!mounted) return;
        
        // Show success message
        _showSuccessSnackBar('Training site saved successfully');
        
        // Wait a moment for the snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate to modules screen
        if (!mounted) return;
        context.go(AppRoutes.modules);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save training site: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  void dispose() {
    _trainingSiteNameController.dispose();
    _villageHeadController.dispose();
    _groupVillageController.dispose();
    _householdCountController.dispose();
    _cookstoveCountController.dispose();
    _householdRadiusController.dispose();
    _totalPopulationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4EA),
      body: Stack(
        children: [
          // ── Green quarter-circle top-right ──
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
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.black87, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          _isEditMode ? 'Edit Training Site' : 'Training Point Identification',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
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

                // ── Form ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── WARNING BANNER (if no server data) ──
                        if (!_isCheckingServerData && !_hasServerData)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFB74D),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFFF9800),
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Sync Required',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE65100),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'You must sync data from the server before creating training sites. Please go to the Dashboard and tap the Sync button.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5D4037),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      context.go(AppRoutes.dashboard);
                                    },
                                    icon: const Icon(Icons.sync, size: 18),
                                    label: const Text(
                                      'Go to Dashboard',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF9800),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        _buildLabel('TRAINING SITE NAME'),
                        const SizedBox(height: 4),
                        _buildTextField(
                          controller: _trainingSiteNameController,
                          hint: 'Enter Training site name',
                          // Allow alphabets, numbers, and basic symbols (default behavior)
                        ),
                        const SizedBox(height: 8),
                        // ── DISTRICT ──
                        _buildLabel('DISTRICT'),
                        const SizedBox(height: 8),
                        _buildDistrictDropdown(),
                        const SizedBox(height: 16),

                        // ── VILLAGE HEAD NAME & GROUP VILLAGE HEAD ──
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('VILLAGE HEAD NAME'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _villageHeadController,
                                    hint: 'Enter Head Name',
                                    allowNumbers: false, // Don't allow numbers
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('GROUP VILLAGE HEAD'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _groupVillageController,
                                    hint: 'Enter Group Name',
                                    allowNumbers: false, // Don't allow numbers
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── TRADITIONAL AUTHORITY ──
                        _buildLabel('TRADITIONAL AUTHORITY'),
                        const SizedBox(height: 8),
                        _buildAuthorityDropdown(),
                        const SizedBox(height: 16),

                        // ── HOUSEHOLD COUNT & COOKSTOVE COUNT ──
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('HOUSEHOLD COUNT'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _householdCountController,
                                    keyboardType: TextInputType.number,
                                    hint: 'Enter count',
                                    numbersOnly: true, // Only positive numbers
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('COOKSTOVE COUNT'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _cookstoveCountController,
                                    keyboardType: TextInputType.number,
                                    hint: 'Enter count',
                                    numbersOnly: true, // Only positive numbers
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── HOUSEHOLD RADIUS & TOTAL POPULATION ──
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('HOUSEHOLD RADIUS'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _householdRadiusController,
                                    keyboardType: TextInputType.number,
                                    hint: 'Enter radius',
                                    numbersOnly: true, // Only positive numbers
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('TOTAL POPULATION'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _totalPopulationController,
                                    keyboardType: TextInputType.number,
                                    hint: 'Enter population',
                                    numbersOnly: true, // Only positive numbers
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── ROAD ACCESS ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.directions_car_outlined,
                                  color: Color(0xFF4CAF50),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ROAD ACCESS',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Accessible by vehicle',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _roadAccess,
                                onChanged: (val) =>
                                    setState(() => _roadAccess = val),
                                activeThumbColor: const Color(0xFF4CAF50),
                                inactiveThumbColor: Colors.grey.shade400,
                                inactiveTrackColor: Colors.grey.shade200,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── LOCATION COORDINATES ──
                        const Row(
                          children: [
                            Icon(Icons.my_location,
                                color: Color(0xFF4CAF50), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'LOCATION COORDINATES',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Get Current Location button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isGettingLocation ? null : _getCurrentLocation,
                            icon: _isGettingLocation 
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.my_location, size: 18),
                            label: Text(
                              _isGettingLocation ? 'Getting Location...' : 'Get Current Location',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── LATITUDE & LONGITUDE ──
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('LATITUDE'),
                                  const SizedBox(height: 8),
                                  _buildUnderlineTextField(
                                      controller: _latitudeController),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('LONGITUDE'),
                                  const SizedBox(height: 8),
                                  _buildUnderlineTextField(
                                      controller: _longitudeController),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── SAVE BUTTON ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveTrainingSite,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isEditMode ? 'Update' : 'Save',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                      ],
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool allowNumbers = true,
    bool numbersOnly = false,
  }) {
    List<TextInputFormatter>? formatters;
    
    if (numbersOnly) {
      // Only positive numbers allowed
      formatters = [
        FilteringTextInputFormatter.digitsOnly, // Only digits
      ];
    } else if (!allowNumbers) {
      // Only alphabets and spaces (for names)
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
      ];
    }
    
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      cursorColor: const Color(0xFF4CAF50),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      inputFormatters: formatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return SearchableDropdown<District>(
      value: _selectedDistrict,
      items: _districts,
      itemLabel: (district) => district.districtName ?? 'Unknown District',
      onChanged: _onDistrictChanged,
      hint: _isLoadingDistricts ? 'Loading districts...' : 'Select District',
      isLoading: _isLoadingDistricts,
    );
  }

  Widget _buildAuthorityDropdown() {
    return SearchableDropdown<Authority>(
      value: _selectedAuthority,
      items: _authorities,
      itemLabel: (authority) => authority.authorityName ?? 'Unknown Authority',
      onChanged: (Authority? authority) {
        setState(() {
          _selectedAuthority = authority;
        });
      },
      hint: _isLoadingAuthorities ? 'Loading authorities...' : 'Select Authority',
      isLoading: _isLoadingAuthorities,
    );
  }

  Widget _buildUnderlineTextField({
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      readOnly: true, // Make read-only - can only be filled by GPS
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.only(bottom: 6),
        isDense: true,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFBDBDBD)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
      ),
    );
  }
}