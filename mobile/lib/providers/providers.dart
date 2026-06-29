import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/auth_events.dart';
import '../core/network/api_client.dart';
import '../core/network/token_store.dart';
import '../data/repositories.dart';
import '../features/audiobooks/audio_handler.dart';
import '../features/profile/support_chat_service.dart';
import '../models/app_language.dart';
import '../models/profile.dart';
import '../models/user.dart';
import '../services/push_service.dart';

/// Overridden in main() once SharedPreferences is loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);

/// Overridden in main() after AudioService.init().
final audioHandlerProvider = Provider<AudioPlayerHandler>(
  (_) => throw UnimplementedError('AudioPlayerHandler not initialized'),
);

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(ref.watch(sharedPreferencesProvider)),
);

/// Active app locale. Persisted in SharedPreferences via [TokenStore.setLanguage].
final localeProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) => LocaleController(ref));

class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._ref) : super(_initial(_ref));

  final Ref _ref;

  static Locale _initial(Ref ref) {
    final code = ref.read(tokenStoreProvider).language.code;
    return Locale(code);
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _ref.read(tokenStoreProvider).setLanguage(language);
    state = Locale(language.code);
  }
}

/// Global notifier for cross-cutting auth events (session expired, …). The
/// Dio client and the router both wire into this singleton so a 401 from the
/// API bounces the user back to the login screen automatically.
final authEventsProvider = Provider<AuthEvents>((ref) => AuthEvents());

final apiClientProvider = Provider<ApiClient>((ref) {
  final events = ref.watch(authEventsProvider);
  return ApiClient(
    ref.watch(tokenStoreProvider),
    onSessionExpired: events.notifySessionExpired,
  );
});

final authRepositoryProvider =
    Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final speechRepositoryProvider =
    Provider((ref) => SpeechRepository(ref.watch(apiClientProvider)));
final observationRepositoryProvider =
    Provider((ref) => ObservationRepository(ref.watch(apiClientProvider)));
final practiceRepositoryProvider =
    Provider((ref) => PracticeRepository(ref.watch(apiClientProvider)));
final quizRepositoryProvider =
    Provider((ref) => QuizRepository(ref.watch(apiClientProvider)));
final learningRepositoryProvider =
    Provider((ref) => LearningRepository(ref.watch(apiClientProvider)));
final profileRepositoryProvider =
    Provider((ref) => ProfileRepository(ref.watch(apiClientProvider)));
final supportRepositoryProvider =
    Provider((ref) => SupportRepository(ref.watch(apiClientProvider)));

/// Long-lived support chat WebSocket. Auto-disposed when the app exits.
final supportChatServiceProvider = Provider<SupportChatService>((ref) {
  final service = SupportChatService(ref.watch(tokenStoreProvider));
  ref.onDispose(service.dispose);
  return service;
});

// ───────────────────── Auth state ─────────────────────
class AuthState {
  const AuthState({this.isLoggedIn = false, this.user});
  final bool isLoggedIn;
  final AppUser? user;

  AuthState copyWith({bool? isLoggedIn, AppUser? user}) =>
      AuthState(isLoggedIn: isLoggedIn ?? this.isLoggedIn, user: user ?? this.user);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref)
      : super(AuthState(
          isLoggedIn: _ref.read(tokenStoreProvider).isLoggedIn,
        )) {
    if (state.isLoggedIn) loadMe();
  }

  final Ref _ref;

  Future<void> onAuthenticated(String access, String refresh) async {
    await _ref.read(tokenStoreProvider).saveTokens(access, refresh);
    // Re-arm the 401 handler so a future expiry can fire again.
    _ref.read(apiClientProvider).resetSessionExpiredFlag();
    state = const AuthState(isLoggedIn: true);
    await loadMe();
  }

  Future<void> loadMe() async {
    try {
      final user = await _ref.read(authRepositoryProvider).me();
      state = AuthState(isLoggedIn: true, user: user);
    } catch (_) {
      // token invalid -> sign out
      await logout();
    }
  }

  void updateUser(AppUser user) {
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    await _ref.read(tokenStoreProvider).clear();
    state = const AuthState(isLoggedIn: false);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));

/// Singleton PushService. Initialised lazily on first use; init() is idempotent
/// and safe to call on a device without Firebase configured.
final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(ref.watch(apiClientProvider));
});

// ───────────────────── Data providers ─────────────────────
final coursesProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(learningRepositoryProvider).courses());

final courseDetailProvider = FutureProvider.autoDispose.family(
    (ref, String id) => ref.watch(learningRepositoryProvider).course(id));

final courseProgressProvider = FutureProvider.autoDispose.family(
    (ref, String id) => ref.watch(learningRepositoryProvider).courseProgress(id));

final lessonDetailProvider = FutureProvider.autoDispose.family(
    (ref, String id) => ref.watch(learningRepositoryProvider).lessonDetail(id));

final lessonHomeworkProvider = FutureProvider.autoDispose.family(
    (ref, String id) => ref.watch(learningRepositoryProvider).myHomework(id));

final audiobooksProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(learningRepositoryProvider).audiobooks());

final audiobookDetailProvider = FutureProvider.autoDispose.family(
    (ref, String id) => ref.watch(learningRepositoryProvider).audiobook(id));

final audiobookAccessProvider = FutureProvider.autoDispose.family(
    (ref, String id) => ref.watch(learningRepositoryProvider).audiobookAccess(id));

final myOrdersProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(learningRepositoryProvider).myOrders());

final referencesProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(speechRepositoryProvider).references());

final observationTestsProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(observationRepositoryProvider).tests());

// ───────────────────── Profile providers ─────────────────────
final certificatesProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(profileRepositoryProvider).certificates());

final certificateRequestsProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(profileRepositoryProvider).certificateRequests());

final notificationsProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(profileRepositoryProvider).notifications());

/// Combined feed of speech + voice + observation analyses, newest first.
final historyProvider = FutureProvider.autoDispose<List<HistoryItem>>((ref) async {
  final speech = ref.watch(speechRepositoryProvider);
  final obs = ref.watch(observationRepositoryProvider);
  final speechList = await speech.history();
  final attemptsList = await obs.attempts();
  final items = <HistoryItem>[
    for (final s in speechList)
      HistoryItem(
        id: s.id,
        kind: HistoryKind.speech,
        meaningScore: s.meaningScore,
        fluencyScore: s.fluencyScore,
        score: s.overallScore,
        createdAt: s.createdAt,
      ),
    for (final a in attemptsList)
      HistoryItem(
        id: a.id,
        kind: HistoryKind.observation,
        subtitle: a.summary,
        score: a.score,
        createdAt: a.createdAt,
      ),
  ];
  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
});

final practicumRepositoryProvider =
    Provider((ref) => PracticumRepository(ref.watch(apiClientProvider)));

final practicumsProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(practicumRepositoryProvider).list());

final practicumDetailProvider = FutureProvider.autoDispose.family(
    (ref, String id) => ref.watch(practicumRepositoryProvider).get(id));

final myPracticumSubmissionProvider = FutureProvider.autoDispose.family(
  (ref, String id) => ref.watch(practicumRepositoryProvider).mySubmission(id),
);

final quizzesProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(quizRepositoryProvider).listQuizzes());
