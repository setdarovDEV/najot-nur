import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audiobooks/reader_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/language_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/telegram_login_screen.dart';
import '../../features/courses/course_detail_screen.dart';
import '../../features/courses/course_learning_screen.dart';
import '../../features/courses/lesson_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/observation/observation_result_screen.dart';
import '../../features/observation/observation_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/analysis_history_screen.dart';
import '../../features/profile/certificates_screen.dart';
import '../../features/profile/faq_screen.dart';
import '../../features/profile/help_contact_screen.dart';
import '../../features/profile/notifications_screen.dart';
import '../../features/profile/orders_screen.dart';
import '../../features/profile/profile_edit_screen.dart';
import '../../features/profile/support_chat_screen.dart';
import '../../features/practicums/practicum_detail_screen.dart';
import '../../features/psychology/psychology_result_screen.dart';
import '../../features/psychology/psychology_screen.dart';
import '../../features/quizzes/quiz_screen.dart';
import '../../features/speech/practice_screen.dart';
import '../../features/speech/speech_hub_screen.dart';
import '../../features/speech/talk_result_screen.dart';
import '../../features/speech/talk_screen.dart';
import '../../features/speech/voice_result_screen.dart';
import '../../features/speech/voice_screen.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/observation_models.dart';
import '../../models/psychology_models.dart';
import '../../models/speech_models.dart';
import '../../providers/providers.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(tokenStoreProvider);
  final events = ref.watch(authEventsProvider);

  return GoRouter(
    initialLocation: prefs.onboardingSeen ? '/home' : '/onboarding',
    refreshListenable: events,
    redirect: (context, state) {
      final isLoggedIn = prefs.accessToken != null;
      final loc = state.matchedLocation;

      // Already logged in → don't show the auth screens. If a gated flow
      // has stashed a post-auth return path (e.g. psychology AI analysis),
      // honour it so the user lands back where they came from.
      if (isLoggedIn &&
          (loc == '/auth' ||
              loc == '/auth/register' ||
              loc == '/auth/login' ||
              loc == '/auth/telegram')) {
        final pending = ref.read(pendingReturnPathProvider);
        if (pending != null) {
          ref.read(pendingReturnPathProvider.notifier).state = null;
          return pending;
        }
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(
        path: '/language',
        builder: (_, state) =>
            LanguageScreen(fromContext: state.extra as String?),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/telegram',
        builder: (_, __) => const TelegramLoginScreen(),
      ),

      // ───── Speech ─────
      GoRoute(path: '/speech', builder: (_, __) => const SpeechHubScreen()),
      GoRoute(path: '/speech/voice', builder: (_, __) => const VoiceScreen()),
      GoRoute(
        path: '/speech/voice/result',
        builder: (_, state) =>
            VoiceResultScreen(analysis: state.extra as VoiceAnalysis),
      ),
      GoRoute(path: '/speech/talk', builder: (_, __) => const TalkScreen()),
      GoRoute(
        path: '/speech/talk/result',
        builder: (_, state) =>
            TalkResultScreen(analysis: state.extra as SpeechAnalysis),
      ),
      GoRoute(
        path: '/speech/practice',
        builder: (_, __) => const PracticeScreen(),
      ),

      // ───── Psychology ─────
      GoRoute(
        path: '/psychology',
        builder: (_, __) => const PsychologyScreen(),
      ),
      GoRoute(
        path: '/psychology/result',
        builder: (_, state) =>
            PsychologyResultScreen(attempt: state.extra as PsychologyAttempt),
      ),

      // ───── Practicums ─────
      GoRoute(
        path: '/practicums/:id',
        builder: (_, state) =>
            PracticumDetailScreen(practicumId: state.pathParameters['id']!),
      ),

      // ───── Quizzes (tests) ─────
      GoRoute(
        path: '/quizzes/:id',
        builder: (_, state) =>
            QuizScreen(quizId: state.pathParameters['id']!),
      ),

      // ───── Observation ─────
      GoRoute(
        path: '/observation',
        builder: (_, __) => const ObservationScreen(),
      ),
      GoRoute(
        path: '/observation/result',
        builder: (_, state) =>
            ObservationResultScreen(attempt: state.extra as ObservationAttempt),
      ),

      // ───── Learning ─────
      GoRoute(
        path: '/courses/:id',
        builder: (_, state) =>
            CourseDetailScreen(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/courses/:id/learn',
        builder: (_, state) =>
            CourseLearningScreen(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/courses/:id/lessons/:lessonId',
        builder: (_, state) => LessonScreen(
          courseId: state.pathParameters['id']!,
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        path: '/audiobooks/:id',
        builder: (_, state) =>
            ReaderScreen(audiobookId: state.pathParameters['id']!),
      ),

      // ───── Profile ─────
      GoRoute(path: '/profile/edit', builder: (_, __) => const ProfileEditScreen()),
      GoRoute(
        path: '/profile/history',
        builder: (_, __) => const AnalysisHistoryScreen(),
      ),
      GoRoute(
        path: '/profile/certificates',
        builder: (_, __) => const CertificatesScreen(),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (_, __) => const HelpContactScreen(),
      ),
      GoRoute(
        path: '/profile/chat',
        builder: (_, __) => const SupportChatScreen(),
      ),
      GoRoute(
        path: '/profile/faq',
        builder: (_, __) => const FaqScreen(),
      ),
      GoRoute(
        path: '/profile/orders',
        builder: (_, __) => const OrdersScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Builder(
        builder: (ctx) => Center(
          child: Text(
            AppLocalizations.of(ctx).pageNotFound(state.uri.toString()),
          ),
        ),
      ),
    ),
  );
});
