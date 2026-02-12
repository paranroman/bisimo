import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'providers/api_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/emotion_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/cimo_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/student_provider.dart';

/// Bisimo App Root Widget
class BisimoApp extends StatelessWidget {
  const BisimoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmotionProvider()),
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(
            chatService: context.read<ApiProvider>().chatService,
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => CimoProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone X design size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Bisimo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
            locale: const Locale('id', 'ID'),
          );
        },
      ),
    );
  }
}
