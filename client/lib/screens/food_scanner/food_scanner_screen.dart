import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../services/api_service.dart';

class FoodScannerScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  const FoodScannerScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _nutritionData;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _nutritionData = null;
          _error = null;
        });
        await _analyzeImage();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await ApiService.analyzeFoodImage(base64Image);

      if (result['success']) {
        setState(() {
          _nutritionData = result['data'];
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to analyze image';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error analyzing image: $e';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF45A191);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF22262A)
          : const Color(0xFFF1F2F4),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF22262A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : const Color(0xFF131615),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Food Scanner',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF131615),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Card
            _buildImagePreviewCard(isDark, primaryColor),
            const SizedBox(height: 16),

            // Action Buttons
            if (_selectedImage == null) ...[
              _buildActionButton(
                isDark: isDark,
                icon: Icons.camera_alt,
                label: 'Take Photo',
                color: primaryColor,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                isDark: isDark,
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                color: const Color(0xFF6366F1),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],

            // Loading Indicator
            if (_isAnalyzing) ...[
              const SizedBox(height: 24),
              _buildAnalyzingCard(isDark),
            ],

            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(isDark),
            ],

            // Nutrition Results
            if (_nutritionData != null && !_isAnalyzing) ...[
              const SizedBox(height: 16),
              _buildNutritionResults(isDark, primaryColor),
            ],

            // Scan Again Button
            if (_selectedImage != null && !_isAnalyzing) ...[
              const SizedBox(height: 16),
              _buildActionButton(
                isDark: isDark,
                icon: Icons.refresh,
                label: 'Scan Another Food',
                color: primaryColor,
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                    _nutritionData = null;
                    _error = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewCard(bool isDark, Color primaryColor) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_selectedImage!, fit: BoxFit.cover),
                  if (_isAnalyzing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan Your Food',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF131615),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a photo or choose from gallery\nto get instant calorie information',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : const Color(0xFF6C7F7C),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF45A191)),
          const SizedBox(height: 16),
          Text(
            'Analyzing your food...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is identifying food items and calculating nutrition',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : const Color(0xFF6C7F7C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53935)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFE53935), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionResults(bool isDark, Color primaryColor) {
    final data = _nutritionData!;
    final identified = data['identified'] ?? false;

    if (!identified) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C3035) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.help_outline, size: 48, color: Color(0xFFFFA726)),
            const SizedBox(height: 16),
            Text(
              'Could Not Identify Food',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF131615),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['error'] ?? 'Please try with a clearer image of the food',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : const Color(0xFF6C7F7C),
              ),
            ),
          ],
        ),
      );
    }

    final foodItems = data['foodItems'] as List? ?? [];
    final totalCalories = data['totalCalories'] ?? 0;
    final healthScore = data['healthScore'] ?? 5;
    final healthTip = data['healthTip'] ?? '';
    final warnings = data['warnings'] as List? ?? [];
    final mealType = data['mealType'] ?? 'meal';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Calories Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Total Calories',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '$totalCalories',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'kcal',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${mealType[0].toUpperCase()}${mealType.substring(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Macro Nutrients
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C3035) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Macronutrients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF131615),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMacroItem(
                    isDark: isDark,
                    label: 'Protein',
                    value: '${data['totalProtein'] ?? 0}g',
                    color: const Color(0xFF6366F1),
                    icon: Icons.fitness_center,
                  ),
                  _buildMacroItem(
                    isDark: isDark,
                    label: 'Carbs',
                    value: '${data['totalCarbs'] ?? 0}g',
                    color: const Color(0xFFFFA726),
                    icon: Icons.grain,
                  ),
                  _buildMacroItem(
                    isDark: isDark,
                    label: 'Fat',
                    value: '${data['totalFat'] ?? 0}g',
                    color: const Color(0xFFE53935),
                    icon: Icons.water_drop,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Food Items
        if (foodItems.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C3035) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identified Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF131615),
                  ),
                ),
                const SizedBox(height: 12),
                ...foodItems.map((item) => _buildFoodItem(isDark, item)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Health Score
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C3035) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getHealthScoreColor(healthScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$healthScore',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _getHealthScoreColor(healthScore),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Score',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF6C7F7C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getHealthScoreLabel(healthScore),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getHealthScoreColor(healthScore),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Health Tip
        if (healthTip.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    healthTip,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF131615),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Warnings
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFA726).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Color(0xFFFFA726),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dietary Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF131615),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...warnings.map(
                  (warning) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(
                          child: Text(
                            warning.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF6C7F7C),
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
      ],
    );
  }

  Widget _buildMacroItem({
    required bool isDark,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF6C7F7C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(bool isDark, Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.restaurant, size: 20, color: Color(0xFF45A191)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF131615),
                  ),
                ),
                Text(
                  item['portion'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF6C7F7C),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item['calories'] ?? 0} kcal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 8) return const Color(0xFF4CAF50);
    if (score >= 6) return const Color(0xFF45A191);
    if (score >= 4) return const Color(0xFFFFA726);
    return const Color(0xFFE53935);
  }

  String _getHealthScoreLabel(int score) {
    if (score >= 8) return 'Excellent Choice!';
    if (score >= 6) return 'Good Choice';
    if (score >= 4) return 'Moderate';
    return 'Consider Healthier Options';
  }
}
