import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/auth_config.dart';
import '../models/learning_models.dart';
import '../models/observation_models.dart';
import '../models/practicum_models.dart';
import '../models/profile.dart';
import '../models/psychology_models.dart';
import '../models/quiz_models.dart';
import '../models/speech_models.dart';
import '../models/support_models.dart';
import '../models/user.dart';

/// Result of an auth call: tokens + whether the account was just created.
class AuthResult {
  AuthResult({required this.access, required this.refresh, required this.isNew});
  final String access;
  final String refresh;
  final bool isNew;
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<void> requestOtp(String phone) async {
    try {
      await _api.dio.post('/auth/otp/request', data: {'phone': phone});
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  /// Step 2 of registration: validate the OTP without consuming it.
  /// Throws [ApiException] when the code is wrong or expired.
  Future<void> checkOtp({required String phone, required String code}) async {
    try {
      await _api.dio.post(
        '/auth/otp/check',
        data: {'phone': phone, 'code': code},
      );
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  /// Returns `(exists, hasPassword)` for the given phone.
  Future<PhoneExists> phoneExists(String phone) async {
    try {
      final r = await _api.dio
          .post('/auth/phone/exists', data: {'phone': phone});
      return PhoneExists(
        exists: r.data['exists'] as bool? ?? false,
        hasPassword: r.data['has_password'] as bool? ?? false,
      );
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<AuthResult> phoneLogin(String phone, String password) async {
    try {
      final r = await _api.dio.post('/auth/phone/login', data: {
        'phone': phone,
        'password': password,
      });
      return AuthResult(
        access: r.data['access_token'] as String,
        refresh: r.data['refresh_token'] as String,
        isNew: false,
      );
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<AuthResult> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    try {
      final r = await _api.dio.post('/auth/password/reset', data: {
        'phone': phone,
        'code': code,
        'new_password': newPassword,
      });
      return AuthResult(
        access: r.data['access_token'] as String,
        refresh: r.data['refresh_token'] as String,
        isNew: false,
      );
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  /// Verifies the OTP and, for a brand-new account, also creates the
  /// password-provider identity and stores the offer agreement.
  Future<AuthResult> verifyOtp({
    required String phone,
    required String code,
    String? fullName,
    String? firstName,
    String? lastName,
    String? password,
    bool offerAccepted = false,
  }) async {
    try {
      final r = await _api.dio.post('/auth/otp/verify', data: {
        'phone': phone,
        'code': code,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        if (password != null && password.isNotEmpty) 'password': password,
        'offer_accepted': offerAccepted,
      });
      return AuthResult(
        access: r.data['tokens']['access_token'] as String,
        refresh: r.data['tokens']['refresh_token'] as String,
        isNew: r.data['is_new_user'] as bool? ?? false,
      );
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<AppUser> me() async {
    try {
      final r = await _api.dio.get('/users/me');
      return AppUser.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<AppUser> updateMe({
    String? fullName,
    String? email,
    String? locale,
  }) async {
    try {
      final r = await _api.dio.patch('/users/me', data: {
        if (fullName != null) 'full_name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (locale != null) 'locale': locale,
      });
      return AppUser.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  /// Public, anonymous — returns which OAuth providers are configured.
  /// The mobile client uses this to decide whether to show the "Sign in
  /// with Telegram" / "Sign in with Google" buttons.
  Future<AuthConfig> authConfig() async {
    try {
      final r = await _api.dio.get('/auth/config');
      return AuthConfig.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

}

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<List<Certificate>> certificates() async {
    try {
      final r = await _api.dio.get('/users/me/certificates');
      return (r.data as List)
          .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<List<AppNotification>> notifications() async {
    try {
      final r = await _api.dio.get('/users/me/notifications');
      return (r.data as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<List<CertificateRequest>> certificateRequests() async {
    try {
      final r = await _api.dio.get('/certificates/my-requests');
      return (r.data as List)
          .map((e) => CertificateRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<void> submitCertificateRequest({
    required String courseId,
    required String fullName,
  }) async {
    try {
      await _api.dio.post('/certificates/request', data: {
        'course_id': courseId,
        'full_name': fullName,
      });
    } catch (e) {
      throw _api.toApiException(e);
    }
  }
}

class PhoneExists {
  const PhoneExists({required this.exists, required this.hasPassword});
  final bool exists;
  final bool hasPassword;
}

class SpeechRepository {
  SpeechRepository(this._api);
  final ApiClient _api;

  Future<List<PronunciationReference>> references() async {
    try {
      final r = await _api.dio.get('/speech/references');
      return (r.data as List)
          .map((e) => PronunciationReference.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<List<SpeechAnalysis>> history() async {
    try {
      final r = await _api.dio.get('/speech/history');
      return (r.data as List)
          .map((e) => SpeechAnalysis.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<VoiceAnalysis> analyzeVoice({
    required String referenceText,
    required String transcript,
    String? referenceId,
  }) async {
    try {
      final r = await _api.dio.post('/speech/voice/analyze', data: {
        'reference_text': referenceText,
        'transcript': transcript,
        if (referenceId != null) 'reference_id': referenceId,
      });
      return VoiceAnalysis.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<SpeechAnalysis> analyzeSpeech({
    required String transcript,
    int durationSec = 0,
  }) async {
    try {
      final r = await _api.dio.post('/speech/analyze', data: {
        'transcript': transcript,
        'duration_sec': durationSec,
      });
      return SpeechAnalysis.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  // STT + AI take a few seconds; allow more headroom than the default 30s.
  // Worst case (long audio + LLM provider fallback chain) can pass 90s, and a
  // client-side cut wastes the whole upload — give the server room to finish.
  static final _audioOptions = Options(
    sendTimeout: const Duration(seconds: 150),
    receiveTimeout: const Duration(seconds: 150),
  );

  /// Upload a read-aloud recording: server transcribes (Groq Whisper) and runs
  /// word- + char-level pronunciation analysis (TZ §4.2).
  Future<VoiceAnalysis> analyzeVoiceAudio({
    required String referenceText,
    required String filePath,
    String? referenceId,
    String? language,
  }) async {
    try {
      final form = FormData.fromMap({
        'reference_text': referenceText,
        if (referenceId != null) 'reference_id': referenceId,
        if (language != null) 'language': language,
        'file': await MultipartFile.fromFile(filePath, filename: 'voice.m4a'),
      });
      final r = await _api.dio.post(
        '/speech/voice/analyze-audio',
        data: form,
        options: _audioOptions,
      );
      return VoiceAnalysis.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  /// Upload a free-talk recording: server transcribes and analyzes it without a
  /// reference text (TZ §4.2).
  Future<SpeechAnalysis> freeTalkAudio({
    required String filePath,
    String? language,
  }) async {
    try {
      final form = FormData.fromMap({
        if (language != null) 'language': language,
        'file': await MultipartFile.fromFile(filePath, filename: 'speech.m4a'),
      });
      final r = await _api.dio.post(
        '/speech/free-talk',
        data: form,
        options: _audioOptions,
      );
      return SpeechAnalysis.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }
}

class ObservationRepository {
  ObservationRepository(this._api);
  final ApiClient _api;

  Future<List<ObservationTest>> tests() async {
    try {
      final r = await _api.dio.get('/observation/tests');
      return (r.data as List)
          .map((e) => ObservationTest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<List<ObservationAttempt>> attempts() async {
    try {
      final r = await _api.dio.get('/observation/attempts');
      return (r.data as List)
          .map((e) => ObservationAttempt.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<ObservationAttempt> submit(List<Map<String, dynamic>> answers) async {
    try {
      final r =
          await _api.dio.post('/observation/submit', data: {'answers': answers});
      return ObservationAttempt.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<ObservationAttempt> submitGuest(
      List<Map<String, dynamic>> answers) async {
    try {
      final r = await _api.dio
          .post('/observation/submit-guest', data: {'answers': answers});
      return ObservationAttempt.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<({String sessionId, List<ObservationTest> tests})> generateTests(
      String difficulty) async {
    try {
      final r = await _api.dio.post(
        '/observation/generate',
        data: {'difficulty': difficulty},
      );
      final data = r.data as Map<String, dynamic>;
      final sessionId = data['session_id'] as String;
      final tests = (data['tests'] as List)
          .map((e) => ObservationTest.fromJson(e as Map<String, dynamic>))
          .toList();
      return (sessionId: sessionId, tests: tests);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<ObservationAttempt> submitAi({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final r = await _api.dio.post(
        '/observation/submit-ai',
        data: {'session_id': sessionId, 'answers': answers},
      );
      return ObservationAttempt.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }
}

class LearningRepository {
  LearningRepository(this._api);
  final ApiClient _api;

  Future<List<Course>> courses() async {
    try {
      final r = await _api.dio.get('/courses');
      return (r.data as List)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<Course> course(String id) async {
    try {
      final r = await _api.dio.get('/courses/$id');
      return Course.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<List<Audiobook>> audiobooks() async {
    try {
      final r = await _api.dio.get('/audiobooks');
      return (r.data as List)
          .map((e) => Audiobook.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<Audiobook> audiobook(String id) async {
    try {
      final r = await _api.dio.get('/audiobooks/$id');
      return Audiobook.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<AudiobookAccessStatus> audiobookAccess(String id) async {
    try {
      final r = await _api.dio.get('/audiobooks/$id/access');
      return AudiobookAccessStatus.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<OrderRequest> submitOrder({
    required OrderPurpose purpose,
    String? courseId,
    String? audiobookId,
    required num amount,
    required OrderPaymentMethod method,
    String? paymentProofUrl,
  }) async {
    try {
      final r = await _api.dio.post('/orders/', data: {
        'purpose': purpose.apiValue,
        if (courseId != null) 'course_id': courseId,
        if (audiobookId != null) 'audiobook_id': audiobookId,
        'amount': amount,
        'payment_method': method.apiValue,
        if (paymentProofUrl != null && paymentProofUrl.isNotEmpty)
          'payment_proof_url': paymentProofUrl,
      });
      return OrderRequest.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<PaymentRedirect> initiatePayment({
    required String provider,
    required String purpose,
    required num amount,
    String? courseId,
    String? audiobookId,
    String? returnUrl,
  }) async {
    try {
      final r = await _api.dio.post('/payments/initiate', data: {
        'provider': provider,
        'purpose': purpose,
        'amount': amount,
        if (courseId != null) 'reference_id': courseId,
        if (audiobookId != null) 'reference_id': audiobookId,
        if (returnUrl != null) 'return_url': returnUrl,
      });
      return PaymentRedirect.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<CourseProgress> courseProgress(String courseId) async {
    try {
      final r = await _api.dio.get('/courses/$courseId/my-progress');
      return CourseProgress.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<LessonDetail> lessonDetail(String lessonId) async {
    try {
      final r = await _api.dio.get('/courses/lessons/$lessonId');
      return LessonDetail.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<void> completeLesson(String lessonId) async {
    try {
      await _api.dio.post('/courses/lessons/$lessonId/complete');
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<Map<String, int>?> submitLessonQuiz({
    required String lessonId,
    required Map<String, int> answers,
  }) async {
    try {
      final r = await _api.dio.post(
        '/courses/lessons/$lessonId/quiz',
        data: {
          'lesson_id': lessonId,
          'answers': answers,
        },
      );
      final d = r.data as Map<String, dynamic>;
      return {
        'score': d['score'] as int,
        'correct': d['correct'] as int,
        'total': d['total'] as int,
        'passed': (d['passed'] as bool) ? 1 : 0,
      };
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<HomeworkSubmission?> myHomework(String lessonId) async {
    try {
      final r = await _api.dio.get('/courses/lessons/$lessonId/my-homework');
      if (r.data == null) return null;
      return HomeworkSubmission.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  /// Upload a recorded voice file for homework and return the server URL
  /// that should be sent in ``submitHomework(submissionUrl: ...)``.
  Future<String> uploadHomeworkAudio({
    required String lessonId,
    required String filePath,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: 'homework_${DateTime.now().millisecondsSinceEpoch}.m4a',
        ),
      });
      final r = await _api.dio.post(
        '/courses/lessons/$lessonId/homework/audio',
        data: form,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final url = (r.data as Map<String, dynamic>)['audio_url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Server audio URL qaytarmadi.');
      }
      return url;
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  /// Submit (or update) homework for a lesson. Text and voice are merged
  /// into a single Homework row on the server: passing only the voice URL
  /// preserves the previously submitted text, and vice versa.
  Future<void> submitHomework({
    required String lessonId,
    String? submissionText,
    String? submissionUrl,
  }) async {
    try {
      await _api.dio.post(
        '/courses/lessons/$lessonId/homework',
        data: {
          if (submissionText != null && submissionText.isNotEmpty)
            'submission_text': submissionText,
          if (submissionUrl != null && submissionUrl.isNotEmpty)
            'submission_url': submissionUrl,
        },
      );
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<List<OrderRequest>> myOrders({int page = 1, int size = 50}) async {
    try {
      final r = await _api.dio.get(
        '/orders/my',
        queryParameters: {'page': page, 'size': size},
      );
      final items = (r.data['items'] as List).cast<Map<String, dynamic>>();
      return items.map(OrderRequest.fromJson).toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }
}

class SupportRepository {
  SupportRepository(this._api);
  final ApiClient _api;

  Future<List<SupportMessage>> messages() async {
    try {
      final r = await _api.dio.get('/support/messages');
      return (r.data as List)
          .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<SupportMessage> send(String text) async {
    try {
      final r = await _api.dio.post('/support/messages', data: {'text': text});
      return SupportMessage.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }
}

class PracticeRepository {
  PracticeRepository(this._api);
  final ApiClient _api;

  static final _genOptions = Options(
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  );

  Future<PracticeText> generateText(String difficulty) async {
    try {
      final form = FormData.fromMap({'difficulty': difficulty});
      final r = await _api.dio.post(
        '/speech/practice/generate',
        data: form,
        options: _genOptions,
      );
      return PracticeText.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }
}

class PracticumRepository {
  PracticumRepository(this._api);
  final ApiClient _api;

  Future<List<Practicum>> list() async {
    try {
      final r = await _api.dio.get('/practicums');
      return (r.data as List)
          .map((e) => Practicum.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<Practicum> get(String id) async {
    try {
      final r = await _api.dio.get('/practicums/$id');
      return Practicum.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<PracticumSubmission> submitVoice(String practicumId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'recording.m4a'),
        'language': 'uz',
      });
      final r = await _api.dio.post(
        '/practicums/$practicumId/submit',
        data: formData,
        options: Options(sendTimeout: const Duration(seconds: 120)),
      );
      return PracticumSubmission.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<PracticumSubmission?> mySubmission(String practicumId) async {
    try {
      final r = await _api.dio.get('/practicums/$practicumId/my-submission');
      return PracticumSubmission.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _api.toApiException(e);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }
}

class QuizRepository {
  QuizRepository(this._api);
  final ApiClient _api;

  Future<List<QuizSummary>> listQuizzes() async {
    try {
      final r = await _api.dio.get('/quizzes');
      return (r.data as List)
          .map((e) => QuizSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<QuizDetail> getQuiz(String quizId) async {
    try {
      final r = await _api.dio.get('/quizzes/$quizId');
      return QuizDetail.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<QuizAttemptResult> submitAttempt(String quizId, List<int> answers) async {
    try {
      final r = await _api.dio.post(
        '/quizzes/$quizId/attempt',
        data: {'answers': answers},
      );
      return QuizAttemptResult.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }
}

/// Security session repository. Maps the `/security/...` backend endpoints.
class SecurityRepository {
  SecurityRepository(this._api);
  final ApiClient _api;

  /// Open a new tracked session for the current user.
  Future<SecuritySessionStart> startSession({
    required String platform,
    String? osVersion,
    String? appVersion,
    String? deviceModel,
    String? deviceId,
    String? locale,
  }) async {
    try {
      final r = await _api.dio.post('/security/sessions/start', data: {
        'platform': platform,
        if (osVersion != null) 'os_version': osVersion,
        if (appVersion != null) 'app_version': appVersion,
        if (deviceModel != null) 'device_model': deviceModel,
        if (deviceId != null) 'device_id': deviceId,
        if (locale != null) 'locale': locale,
      });
      return SecuritySessionStart.fromJson(
        r.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<String> heartbeat({
    required String sessionId,
    String? watermarkText,
  }) async {
    try {
      final r = await _api.dio.post(
        '/security/sessions/$sessionId/heartbeat',
        data: {
          if (watermarkText != null) 'watermark_text': watermarkText,
        },
      );
      return (r.data['watermark_text'] as String?) ?? '';
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<void> endSession(String sessionId, {String? reason}) async {
    try {
      await _api.dio.post(
        '/security/sessions/$sessionId/end',
        data: {if (reason != null) 'reason': reason},
      );
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<void> reportEvent({
    required String sessionId,
    required String type,
    Map<String, dynamic>? payload,
    String? note,
  }) async {
    try {
      await _api.dio.post(
        '/security/sessions/$sessionId/events',
        data: {
          'type': type,
          'payload': payload ?? const <String, dynamic>{},
          if (note != null) 'note': note,
        },
      );
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  Future<void> uploadRecording({
    required String sessionId,
    required String filePath,
    String kind = 'audio',
    int durationSec = 0,
    String? note,
  }) async {
    try {
      final formData = FormData.fromMap({
        'kind': kind,
        'duration_sec': durationSec,
        if (note != null) 'note': note,
        'file': await MultipartFile.fromFile(filePath, filename: 'login.m4a'),
      });
      await _api.dio.post(
        '/security/sessions/$sessionId/recording',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
    } catch (e) {
      throw _api.toApiException(e);
    }
  }
}

class PsychologyRepository {
  PsychologyRepository(this._api);
  final ApiClient _api;

  /// Returns the list of psychology tests for the given difficulty. When
  /// [difficulty] is null the server picks a default curated set.
  Future<List<PsychologyTest>> tests({String? difficulty}) async {
    try {
      final r = await _api.dio.get(
        '/psychology/tests',
        queryParameters: difficulty == null ? null : {'difficulty': difficulty},
      );
      return (r.data as List)
          .map((e) => PsychologyTest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  /// Submit answers for a psychology test. Works for both authenticated and
  /// guest users; the response is the same shape (a [PsychologyAttempt]).
  Future<PsychologyAttempt> submit(List<PsychologyAnswer> answers) async {
    try {
      final r = await _api.dio.post(
        '/psychology/submit',
        data: {
          'answers': answers.map((a) => a.toJson()).toList(),
        },
      );
      return PsychologyAttempt.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  /// Get the caller's own attempts (history).
  Future<List<PsychologyAttempt>> attempts() async {
    try {
      final r = await _api.dio.get('/psychology/attempts');
      return (r.data as List)
          .map((e) => PsychologyAttempt.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _api.toApiException(e);
    }
  }

  /// Request a detailed AI analysis for a guest attempt. The caller must be
  /// authenticated; the backend re-runs the analysis with the user's profile
  /// and returns the same [PsychologyAttempt] shape but populated with the
  /// `ai_analysis` text.
  Future<PsychologyAttempt> requestAi(String attemptId) async {
    try {
      final r = await _api.dio.post('/psychology/attempts/$attemptId/ai');
      return PsychologyAttempt.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw _api.toApiException(e);
    }
  }
}

class SecuritySessionStart {
  SecuritySessionStart({
    required this.sessionId,
    required this.watermarkText,
    required this.serverTime,
  });
  final String sessionId;
  final String watermarkText;
  final DateTime serverTime;

  factory SecuritySessionStart.fromJson(Map<String, dynamic> j) {
    final sess = (j['session'] as Map).cast<String, dynamic>();
    return SecuritySessionStart(
      sessionId: sess['id'] as String,
      watermarkText: j['watermark_text'] as String? ?? '',
      serverTime: DateTime.tryParse(j['server_time'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
