import 'package:flutter/material.dart';
import 'package:irise/data/repositories/training_site_repository.dart';
import 'dart:developer' as developer;

class ConductTrainingSheet extends StatefulWidget {
  final String siteName;
  final int trainingPointId;
  
  const ConductTrainingSheet({
    super.key,
    required this.siteName,
    required this.trainingPointId,
  });

  @override
  State<ConductTrainingSheet> createState() => _ConductTrainingSheetState();
}

class _ConductTrainingSheetState extends State<ConductTrainingSheet> {
  int _currentStep = 0;
  final _peopleController = TextEditingController();
  final _pageController = PageController();
  DateTime _selectedDate = DateTime.now(); // Auto-fill with current date
  bool _isNumberOfPeopleValid = false; // Track if number of people is entered

  final List<_StepData> _steps = [
    _StepData(
      stepLabel: 'STEP 1',
      title: 'Training Process',
      type: StepType.checklist,
      content: [
        'Explain what the e-Cookstove is;',
        'Describe the design features of the e-Cookstove;',
        'Explain the correct methods of storing the e-Cookstove;',
        'Explain the maintenance procedure in case of minor damages and how to replace the e-Cookstove if audited and deemed to be damaged;',
        'Demonstrate how to ignite the wood-fuel and cooking Method;',
        'Explain how to safely dispose the ash and burnt coal;',
        'Ensure that each beneficiary signs to acknowledge completion and acceptance of the training workshops.',
      ],
    ),
    _StepData(
      stepLabel: 'STEP 2',
      title: 'What Is An E-Cookstove',
      type: StepType.imageWithBullets,
      imageAsset: 'assets/steps/step2.png',
      description:
          'An efficient cookstove is a cookstove made from rich mineral clay blended with water and rice husk, to produce the best ceramic device that improves thermal efficiency, decreases cooking times and uses less wood fuel.',
      bullets: [
        'To protect the ceramic mould, a metallic jacket is wrapped and crimped around the device that increases durability and will last many years;',
        'The metallic jacket also acts as a heat conductor that keeps the heat within the device;',
      ],
    ),
    _StepData(
      stepLabel: 'STEP 3',
      title: 'Design Features',
      type: StepType.imageWithBullets,
      imageAsset: 'assets/steps/step3.png',
      description:
          'As depicted on the 3D model, the ceramic device boasts several features that make the cookstove truly unique and fit for its purpose.',
      bullets: [
        'A Base which is streamlined and flat to allow easy positioning on flat surfaces;',
        'A wide enough firebox which serves as an intake for oxygen to allow wood fuel ignition and combustion;',
        'A narrow throat which serves as a passage for the flame and hot gases from the fire;',
      ],
    ),
    _StepData(
      stepLabel: 'STEP 4',
      title: 'Maintenance',
      type: StepType.textWithBullets,
      description:
          'Crack Management: Add 2 cups (approximately 450ml each) of wet soil / clay to 1 cup of cow dung. Mix thoroughly to form a smooth paste. Spread the mixture as needed to fill the cracks on the device. Allow to dry for 24 hours to ensure it sets appropriately;',
      bullets: [
        'Avoid unnecessary shifting of the stove to minimize accidental tipping that can lead to damaging the stove and minimizing burn incidents;',
        'Keep the stove on flat surfaces;',
        'Remaining coals from fires can be reused for other cooking needs or to keep the surrounding areas / home warm;',
        'Remove excess ash as it begins to accumulate inside the firebox;',
      ],
    ),
    _StepData(
      stepLabel: 'STEP 5',
      title: 'How The E-Cookstove Works',
      type: StepType.imageWithBullets,
      imageAsset: 'assets/steps/step5.png',
      description:
          'Place the cookstove on a flat surface with room for oxygen flow to necessitate the ignition;',
      bullets: [
        'Place small dry twigs in the firebox opening that is at the base of the device;',
        'Elevate the firewood so that air can accelerate the ignition of the wood fuel;',
        'Once the wood is burning, place your pot or pan directly on top of the cookstove;',
      ],
    ),
    _StepData(
      stepLabel: 'STEP 6',
      title: 'Safety Methods Of Ash Disposal',
      type: StepType.textWithBullets,
      description:
          'For the effective use of the device, ensure that the Fire box is not overloaded with ash and coal.',
      bullets: [
        'Dig a small pit beneath the device to allow for easy removal once it has cooled down.',
        'Burnt coal or ash can be kept and used to create or amend soil mixture for maintenance of the device.',
        'It can also be a useful additive to compost heaping or can be applied to bare ground and dug in.',
        'Ash from wood fires can be a natural source of potassium and has a liming effect.',
        'This can help to remedy excessively acidic soils.',
      ],
    ),
    _StepData(
      stepLabel: 'STEP 7',
      title: 'Finalising The Training Session',
      type: StepType.finalStep,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Add listener to track changes in the number of people field
    _peopleController.addListener(_validateNumberOfPeople);
  }

  void _validateNumberOfPeople() {
    final text = _peopleController.text.trim();
    final number = int.tryParse(text);
    setState(() {
      _isNumberOfPeopleValid = text.isNotEmpty && number != null && number > 0;
    });
  }

  @override
  void dispose() {
    _peopleController.removeListener(_validateNumberOfPeople);
    _peopleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Only allow past or current date
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _handleUpdateDetails() async {
    // Validate input
    if (_peopleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the number of people present'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final numberOfPeople = int.tryParse(_peopleController.text.trim());
    if (numberOfPeople == null || numberOfPeople <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4CAF50),
        ),
      ),
    );

    try {
      // Format date as YYYY-MM-DD
      final formattedDate = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      
      developer.log('========================================', name: 'ConductTrainingSheet');
      developer.log('Updating training details in local database', name: 'ConductTrainingSheet');
      developer.log('Training Point ID: ${widget.trainingPointId}', name: 'ConductTrainingSheet');
      developer.log('Conduct Training Date: $formattedDate', name: 'ConductTrainingSheet');
      developer.log('Number of People Present: $numberOfPeople', name: 'ConductTrainingSheet');
      developer.log('========================================', name: 'ConductTrainingSheet');

      // Update local database only (no API call)
      final repository = TrainingSiteRepository();
      final trainingSite = await repository.getById(widget.trainingPointId);
      
      if (trainingSite != null) {
        final updatedSite = trainingSite.copyWith(
          conductTrainingDate: formattedDate,
          numberOfPeoplePresent: numberOfPeople,
          trainingStatus: 'completed',
          modifiedDate: DateTime.now().toUtc().toIso8601String(),
          sIsSync: 0, // Mark as unsynced since we updated locally
        );
        
        await repository.update(updatedSite);
        developer.log('Local database updated successfully', name: 'ConductTrainingSheet');
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Training details saved locally! Use "Tap to sync" to upload to server.'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 3),
        ),
      );

      // Close the bottom sheet and return true to indicate success
      Navigator.of(context).pop(true);
    } catch (e) {
      developer.log('Error updating training details: $e', name: 'ConductTrainingSheet');
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.80,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF4EA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag handle ──
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          const SizedBox(height: 6),

          // ── Training site label ──
          Text(
            'Training Site: ${widget.siteName}',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 10),

          // ── Step indicator ──
          _StepIndicator(currentStep: _currentStep, totalSteps: _steps.length),
          const SizedBox(height: 12),

          // ── Page content ──
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                return _StepContent(
                  step: _steps[index],
                  siteName: widget.siteName,
                  peopleController: _peopleController,
                  selectedDate: _selectedDate,
                  onDateTap: _selectDate,
                  formatDate: _formatDate,
                );
              },
            ),
          ),

          // ── Bottom buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: _currentStep > 0 ? 2 : 1,
                  child: ElevatedButton(
                    onPressed: _currentStep == _steps.length - 1
                        ? (_isNumberOfPeopleValid ? _handleUpdateDetails : null)
                        : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep == _steps.length - 1 && !_isNumberOfPeopleValid
                          ? Colors.grey
                          : const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentStep == _steps.length - 1
                          ? 'Update Details'
                          : 'Next Step',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Indicator
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return Row(
          children: [
            // Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isCompleted || isCurrent
                        ? Colors.white
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            // Connector line
            if (index < totalSteps - 1)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 20,
                height: 2,
                color: isCompleted
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade300,
              ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Data Model
// ─────────────────────────────────────────────────────────────────────────────

enum StepType { checklist, imageWithBullets, textWithBullets, finalStep }

class _StepData {
  final String stepLabel;
  final String title;
  final StepType type;
  final List<String> content;
  final String? imageAsset;
  final String? description;
  final List<String> bullets;

  _StepData({
    required this.stepLabel,
    required this.title,
    required this.type,
    this.content = const [],
    this.imageAsset,
    this.description,
    this.bullets = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Content Widget
// ─────────────────────────────────────────────────────────────────────────────

class _StepContent extends StatelessWidget {
  final _StepData step;
  final String siteName;
  final TextEditingController peopleController;
  final DateTime selectedDate;
  final VoidCallback onDateTap;
  final String Function(DateTime) formatDate;

  const _StepContent({
    required this.step,
    required this.siteName,
    required this.peopleController,
    required this.selectedDate,
    required this.onDateTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step label + title
              Center(
                child: Text(
                  step.stepLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content based on type
              if (step.type == StepType.checklist) ...[
                ...step.content.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF4CAF50), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (step.type == StepType.imageWithBullets ||
                  step.type == StepType.textWithBullets) ...[
                // Image (if available)
                if (step.imageAsset != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      step.imageAsset!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              color: Color(0xFF4CAF50), size: 48),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Description
                if (step.description != null)
                  Text(
                    step.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 12),

                // Bullets
                ...step.bullets.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_forward,
                            color: Color(0xFF4CAF50), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bullet,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (step.type == StepType.finalStep) ...[
                // Training site
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Color(0xFF4CAF50), size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRAINING SITE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          siteName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date - Now clickable with date picker
                GestureDetector(
                  onTap: onDateTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Color(0xFF4CAF50), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DATE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black45,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatDate(selectedDate),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_outlined,
                            color: Color(0xFF4CAF50), size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap to change the training date if needed.',
                  style: TextStyle(fontSize: 11, color: Colors.black38),
                ),
                const SizedBox(height: 20),

                // Number of people
                const Text(
                  'Number Of People Present',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: peopleController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter Number Of People',
                    hintStyle:
                        const TextStyle(color: Colors.black38, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
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
                      borderSide: const BorderSide(
                          color: Color(0xFF4CAF50), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter the total count of attendees verified during this session.',
                  style: TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
