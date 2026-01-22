import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/gamification_service.dart';

class GamificationScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  const GamificationScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _points = 0;
  int _dailyPoints = 0;
  int _level = 1;
  List<Map<String, dynamic>> _badges = [];
  List<Map<String, dynamic>> _leaderboard = [];
  int _selectedTab = 0; // 0: Overview, 1: Badges, 2: Leaderboard
  late TabController _tabController;

  // Badge definitions
  final List<Map<String, dynamic>> _allBadges = [
    {
      'id': 'first_steps',
      'name': 'First Steps',
      'description': 'Complete your first 1,000 steps',
      'icon': Icons.directions_walk,
      'color': Color(0xFF4CAF50),
      'requirement': 'steps >= 1000',
    },
    {
      'id': 'step_master',
      'name': 'Step Master',
      'description': 'Reach 10,000 steps in a day',
      'icon': Icons.directions_run,
      'color': Color(0xFF2196F3),
      'requirement': 'steps >= 10000',
    },
    {
      'id': 'marathon_walker',
      'name': 'Marathon Walker',
      'description': 'Walk 50,000 steps in a week',
      'icon': Icons.emoji_events,
      'color': Color(0xFFFF9800),
      'requirement': 'weekly_steps >= 50000',
    },
    {
      'id': 'sleep_champion',
      'name': 'Sleep Champion',
      'description': 'Get 8+ hours of sleep for 7 days',
      'icon': Icons.bedtime,
      'color': Color(0xFF9C27B0),
      'requirement': 'sleep_streak >= 7',
    },
    {
      'id': 'early_bird',
      'name': 'Early Bird',
      'description': 'Log activity before 7 AM',
      'icon': Icons.wb_sunny,
      'color': Color(0xFFFFEB3B),
      'requirement': 'early_activity',
    },
    {
      'id': 'calorie_crusher',
      'name': 'Calorie Crusher',
      'description': 'Burn 500+ calories in a day',
      'icon': Icons.local_fire_department,
      'color': Color(0xFFE91E63),
      'requirement': 'calories >= 500',
    },
    {
      'id': 'consistency_king',
      'name': 'Consistency King',
      'description': 'Log health data for 30 days straight',
      'icon': Icons.calendar_month,
      'color': Color(0xFF00BCD4),
      'requirement': 'streak >= 30',
    },
    {
      'id': 'heart_healthy',
      'name': 'Heart Healthy',
      'description': 'Maintain optimal heart rate for a week',
      'icon': Icons.favorite,
      'color': Color(0xFFF44336),
      'requirement': 'healthy_hr_week',
    },
    {
      'id': 'hydration_hero',
      'name': 'Hydration Hero',
      'description': 'Meet hydration goal for 5 days',
      'icon': Icons.water_drop,
      'color': Color(0xFF03A9F4),
      'requirement': 'hydration_streak >= 5',
    },
    {
      'id': 'social_butterfly',
      'name': 'Social Butterfly',
      'description': 'Share your progress with friends',
      'icon': Icons.share,
      'color': Color(0xFF8BC34A),
      'requirement': 'shared_progress',
    },
    {
      'id': 'level_5',
      'name': 'Rising Star',
      'description': 'Reach Level 5',
      'icon': Icons.star,
      'color': Color(0xFFFFC107),
      'requirement': 'level >= 5',
    },
    {
      'id': 'level_10',
      'name': 'Health Champion',
      'description': 'Reach Level 10',
      'icon': Icons.military_tech,
      'color': Color(0xFFFF5722),
      'requirement': 'level >= 10',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Sync gamification first
    await GamificationService.syncGamification();

    // Fetch profile and leaderboard in parallel
    final results = await Future.wait([
      GamificationService.getProfile(),
      GamificationService.getTodayLeaderboard(),
    ]);

    final profileResult = results[0];
    final leaderboardResult = results[1];

    if (profileResult['success'] == true) {
      final data = profileResult['data'];
      setState(() {
        _points = data['points'] ?? 0;
        _dailyPoints = data['dailyPoints'] ?? 0;
        _level = data['level'] ?? 1;
        _badges = List<Map<String, dynamic>>.from(data['badges'] ?? []);
      });
    }

    if (leaderboardResult['success'] == true) {
      setState(() {
        _leaderboard = List<Map<String, dynamic>>.from(
          leaderboardResult['data'] ?? [],
        );
      });
    }

    setState(() => _isLoading = false);
  }

  int _getPointsForNextLevel() {
    return _level * 100;
  }

  double _getLevelProgress() {
    final pointsInLevel = _points % 100;
    return pointsInLevel / 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF22262A)
          : const Color(0xFFF1F2F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF45A191),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(isDark),
                          _buildBadgesTab(isDark),
                          _buildLeaderboardTab(isDark),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Gamification',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF131615),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF45A191),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6C7F7C),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Badges'),
          Tab(text: 'Leaderboard'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLevelCard(isDark),
          const SizedBox(height: 16),
          _buildPointsCards(isDark),
          const SizedBox(height: 16),
          _buildDailyGoalsCard(isDark),
          const SizedBox(height: 16),
          _buildRecentBadges(isDark),
          const SizedBox(height: 16),
          _buildShareCard(isDark),
        ],
      ),
    );
  }

  Widget _buildLevelCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF45A191), Color(0xFF2D7A6D)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF45A191).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Level',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level $_level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: _getLevelProgress(),
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${(_getLevelProgress() * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _getLevelProgress(),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_points % 100} / 100 XP',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${100 - (_points % 100)} XP to Level ${_level + 1}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCards(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            title: 'Total Points',
            value: '$_points',
            icon: Icons.stars,
            color: const Color(0xFFFFA726),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            title: "Today's Points",
            value: '+$_dailyPoints',
            icon: Icons.today,
            color: const Color(0xFF42A5F5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : const Color(0xFF6C7F7C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalsCard(bool isDark) {
    final goals = [
      {'name': 'Log Activity', 'points': 10, 'completed': _dailyPoints >= 10},
      {'name': '8,000+ Steps', 'points': 20, 'completed': _dailyPoints >= 30},
      {'name': '12,000+ Steps', 'points': 10, 'completed': _dailyPoints >= 40},
      {'name': '400+ Calories', 'points': 20, 'completed': _dailyPoints >= 60},
      {'name': '7+ Hours Sleep', 'points': 20, 'completed': _dailyPoints >= 80},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF131615),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF45A191).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${goals.where((g) => g['completed'] == true).length}/${goals.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF45A191),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...goals.map(
            (goal) => _buildGoalItem(
              isDark: isDark,
              name: goal['name'] as String,
              points: goal['points'] as int,
              completed: goal['completed'] as bool,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem({
    required bool isDark,
    required String name,
    required int points,
    required bool completed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: completed
                  ? const Color(0xFF45A191)
                  : (isDark
                        ? const Color(0xFF3A3F45)
                        : const Color(0xFFE5E7EB)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check : Icons.circle_outlined,
              color: completed
                  ? Colors.white
                  : (isDark ? Colors.white30 : Colors.black26),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: completed
                    ? (isDark ? Colors.white : const Color(0xFF131615))
                    : (isDark ? Colors.white60 : const Color(0xFF6C7F7C)),
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: completed
                  ? const Color(0xFF45A191).withOpacity(0.1)
                  : (isDark
                        ? const Color(0xFF3A3F45)
                        : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$points XP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: completed
                    ? const Color(0xFF45A191)
                    : (isDark ? Colors.white60 : const Color(0xFF6C7F7C)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBadges(bool isDark) {
    // Show first 4 badges (earned or locked)
    final displayBadges = _allBadges.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Badges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF131615),
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF45A191),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: displayBadges.map((badge) {
              final isEarned = _badges.any((b) => b['id'] == badge['id']);
              return _buildBadgeIcon(
                icon: badge['icon'] as IconData,
                color: badge['color'] as Color,
                name: badge['name'] as String,
                isEarned: isEarned,
                isDark: isDark,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon({
    required IconData icon,
    required Color color,
    required String name,
    required bool isEarned,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isEarned
                ? color.withOpacity(0.15)
                : (isDark ? const Color(0xFF3A3F45) : const Color(0xFFF3F4F6)),
            shape: BoxShape.circle,
            border: isEarned
                ? Border.all(color: color.withOpacity(0.5), width: 2)
                : null,
          ),
          child: Icon(
            icon,
            color: isEarned
                ? color
                : (isDark ? Colors.white30 : Colors.black26),
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isEarned
                  ? (isDark ? Colors.white : const Color(0xFF131615))
                  : (isDark ? Colors.white60 : const Color(0xFF6C7F7C)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(isDark ? 0.3 : 0.1),
            const Color(0xFF8B5CF6).withOpacity(isDark ? 0.3 : 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.share, color: Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Your Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF131615),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Challenge friends and earn bonus XP!',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF6C7F7C),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _shareProgress,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _shareProgress() {
    // Show share dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C3035) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '🎮 My SwasthSetu Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF131615),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A3F45)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '🏆 Level $_level',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF131615),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_points Total XP • $_dailyPoints XP Today',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF6C7F7C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_badges.length} Badges Earned',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF45A191),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final text =
                            '🎮 My SwasthSetu Progress\n\n'
                            '🏆 Level $_level\n'
                            '⭐ $_points Total XP\n'
                            '💪 $_dailyPoints XP Today\n'
                            '🎖️ ${_badges.length} Badges Earned\n\n'
                            'Join me on SwasthSetu and start your health journey! 💪';
                        Clipboard.setData(ClipboardData(text: text));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Progress copied to clipboard!',
                            ),
                            backgroundColor: const Color(0xFF45A191),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF45A191),
                        side: const BorderSide(color: Color(0xFF45A191)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final text =
                            '🎮 My SwasthSetu Progress\n\n'
                            '🏆 Level $_level\n'
                            '⭐ $_points Total XP\n'
                            '💪 $_dailyPoints XP Today\n'
                            '🎖️ ${_badges.length} Badges Earned\n\n'
                            'Join me on SwasthSetu and start your health journey! 💪';
                        Navigator.pop(context);
                        Share.share(text, subject: 'My SwasthSetu Progress');
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF45A191),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgesTab(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Badges',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_badges.length} of ${_allBadges.length} earned',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : const Color(0xFF6C7F7C),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _allBadges.length,
            itemBuilder: (context, index) {
              final badge = _allBadges[index];
              final isEarned = _badges.any((b) => b['id'] == badge['id']);
              return _buildBadgeCard(
                isDark: isDark,
                badge: badge,
                isEarned: isEarned,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard({
    required bool isDark,
    required Map<String, dynamic> badge,
    required bool isEarned,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isEarned
            ? Border.all(
                color: (badge['color'] as Color).withOpacity(0.5),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isEarned
                  ? (badge['color'] as Color).withOpacity(0.15)
                  : (isDark
                        ? const Color(0xFF3A3F45)
                        : const Color(0xFFF3F4F6)),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  badge['icon'] as IconData,
                  color: isEarned
                      ? badge['color'] as Color
                      : (isDark ? Colors.white30 : Colors.black26),
                  size: 32,
                ),
                if (!isEarned)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3A3F45)
                            : const Color(0xFFE5E7EB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        size: 12,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge['name'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isEarned
                  ? (isDark ? Colors.white : const Color(0xFF131615))
                  : (isDark ? Colors.white60 : const Color(0xFF6C7F7C)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge['description'] as String,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : const Color(0xFF6C7F7C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeaderboardHeader(isDark),
          const SizedBox(height: 20),
          if (_leaderboard.isEmpty)
            _buildEmptyLeaderboard(isDark)
          else
            ..._leaderboard.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              return _buildLeaderboardItem(
                isDark: isDark,
                rank: index + 1,
                user: user,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLeaderboardHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.leaderboard, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Leaderboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Top performers of the day',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.emoji_events, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyLeaderboard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No leaderboard data yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : const Color(0xFF6C7F7C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete daily goals to appear on the leaderboard!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required bool isDark,
    required int rank,
    required Map<String, dynamic> user,
  }) {
    final isTopThree = rank <= 3;
    final rankColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    final userName = user['userId']?['name'] ?? 'Anonymous';
    final points = user['dailyPoints'] ?? 0;
    final level = user['level'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isTopThree
            ? Border.all(color: rankColors[rank]!.withOpacity(0.5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTopThree
                  ? rankColors[rank]!.withOpacity(0.2)
                  : (isDark
                        ? const Color(0xFF3A3F45)
                        : const Color(0xFFF3F4F6)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isTopThree
                  ? Icon(
                      rank == 1
                          ? Icons.looks_one
                          : (rank == 2 ? Icons.looks_two : Icons.looks_3),
                      color: rankColors[rank],
                      size: 24,
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF131615),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF131615),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Level $level',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF6C7F7C),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF45A191).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Color(0xFF45A191), size: 16),
                const SizedBox(width: 4),
                Text(
                  '$points XP',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF45A191),
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
