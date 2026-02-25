import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/navigation/app_drawer.dart';
import '../../auth/services/profile_service.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/typing_text_bubble.dart';
import '../widgets/emotion_button.dart';

/// Home Screen - Main dashboard with Cimo greeting
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileService = ProfileService();
  String _namaPanggilan = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // If logged in as student, use displayName from AuthProvider
    if (authProvider.isStudentMode) {
      if (mounted) {
        setState(() {
          _namaPanggilan = authProvider.displayName;
        });
      }
      return;
    }
    
    // Otherwise, load from profile service (for Wali/Guru)
    final profile = await _profileService.getProfile();
    if (mounted && profile != null) {
      setState(() {
        _namaPanggilan = profile.namaPanggilan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Halaman Beranda',
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.home),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              AssetPaths.homeBackground,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.white);
              },
            ),
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;

                // Responsive values based on screen size
                final cimoSize = screenWidth * 0.55; // 55% of screen width (bigger)
                final cimoLeft = screenWidth * -0.03; // -3% from left
                final cimoBottom = screenHeight * -0.15; // -15% from bottom of section
                final bubbleLeft = screenWidth * 0.22; // 22% from left (closer to Cimo)
                final bubbleTop = screenHeight * 0.02; // 2% from top
                final sectionHeight = screenHeight * 0.38; // 38% of screen height

                return Column(
                  children: [
                    SizedBox(height: screenHeight * 0.02),

                    // Cimo and Chat Bubble Section - Responsive positioning
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      child: SizedBox(
                        height: sectionHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Cimo Image - positioned bottom-left
                            Positioned(
                              left: cimoLeft,
                              bottom: cimoBottom,
                              child: SizedBox(
                                width: cimoSize,
                                height: cimoSize,
                                child: Image.asset(
                                  AssetPaths.cimoJoy,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.emoji_emotions,
                                        size: 80,
                                        color: AppColors.primary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Chat Bubble - positioned top-right of Cimo
                            Positioned(
                              left: bubbleLeft,
                              top: bubbleTop,
                              right: screenWidth * 0.02,
                              child: TypingTextBubble(
                                userName: _namaPanggilan.isNotEmpty ? _namaPanggilan : 'Teman',
                                greetingPrefix: 'Halo, ',
                                greetingSuffix: '!\n',
                                bodyText: 'Cimo ingin mendengarmu di sini,\n',
                                questionText: 'bagaimana perasaanmu?',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Emotion Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
                      child: EmotionButton(
                        onPressed: () {
                          context.push(AppRoutes.camera);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceM),

                    // Text Story Link
                    GestureDetector(
                      onTap: () {
                        context.push(AppRoutes.chat);
                      },
                      child: const Text(
                        'Bercerita dengan teks.',
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const Spacer(flex: 1),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

