import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audiobooks/reader_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/language_screen.dart';
import '../../features/courses/course_detail_screen.dart';
import '../../features/courses/course_learning_screen.dart';
import '../../features/courses/lesson_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/observation/observation_result_screen.dart';
import '../../features/observation/observation_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/payments/nasiya_checkout_screen.dart';
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

      // Token expired / not logged in → send to auth (except public routes).
      if (!isLoggedIn) {
        final isPublic = loc == '/onboarding' ||
            loc == '/auth' ||
            loc.startsWith('/auth/') ||
            loc == '/language' ||
            // Course details and lesson playback stay reachable while
            // logged out so demo lessons can be viewed without an account;
            // the API itself still gates non-demo lesson content.
            RegExp(r'^/courses/[^/]+(/lessons/[^/]+)?$').hasMatch(loc);
        if (!isPublic) return '/auth';
      }

      // Already logged in → don't show the auth screens. If a gated flow
      // has stashed a post-auth return path (e.g. psychology AI analysis),
      // honour it so the user lands back where they came from.
      if (isLoggedIn && (loc == '/auth' || loc.startsWith('/auth/'))) {
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
        path: '/auth/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (_, state) =>
            LanguageScreen(fromContext: state.extra as String?),
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
        builder: (context, state) {
          final attempt = state.extra as PsychologyAttempt? ??
              ProviderScope.containerOf(context)
                  .read(pendingPsychologyAttemptProvider);
          if (attempt == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text("Ma'lumot topilmadi")),
            );
          }
          return PsychologyResultScreen(attempt: attempt);
        },
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
        path: '/payments/nasiya',
        builder: (_, state) {
          final args = state.extra as NasiyaCheckoutArgs;
          return NasiyaCheckoutScreen(
            purpose: args.purpose,
            targetId: args.targetId,
            targetTitle: args.targetTitle,
            amount: args.amount,
          );
        },
      ),
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
