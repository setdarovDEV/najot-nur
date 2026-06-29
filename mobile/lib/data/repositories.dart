import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/learning_models.dart';
import '../models/observation_models.dart';
import '../models/practicum_models.dart';
import '../models/profile.dart';
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

  Future<String?> requestOtp(String phone) async {
    try {
      final r = await _api.dio.post('/auth/otp/request', data: {'phone': phone});
      return r.data['dev_code'] as String?; // present only in DEBUG
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
  static final _audioOptions = Options(
    sendTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
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
