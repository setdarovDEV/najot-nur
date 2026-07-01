// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'NotiqAI';

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeSubtitle => 'Sign in with your phone number to continue';

  @override
  String get termsNotice => 'By continuing, you agree to the terms of use';

  @override
  String appVersion(String version) {
    return 'NotiqAI · v$version';
  }

  @override
  String get sessionExpired => 'Session expired. Please sign in again.';

  @override
  String get continueAction => 'Continue';

  @override
  String get login => 'Sign in';

  @override
  String get register => 'Sign up';

  @override
  String get registerAndLogin => 'Sign up and sign in';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get verificationCode => 'Verification code';

  @override
  String get stepPhone => 'Phone';

  @override
  String get stepVerification => 'Verify';

  @override
  String get stepInfo => 'Details';

  @override
  String get stepNewPassword => 'New password';

  @override
  String get enterPhoneTitle => 'Enter your phone number';

  @override
  String get enterPhoneSubtitle =>
      'A verification code will be sent to your phone';

  @override
  String get enterPhoneForLogin =>
      'Enter your phone number to sign in';

  @override
  String get enterPhoneForRegister =>
      'Enter your phone number to sign up';

  @override
  String get enterPhoneForReset =>
      'Enter your phone number to reset your password';

  @override
  String get invalidPhone => 'Enter a valid phone number';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get codeTooShort => 'Enter the full code';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get newPassword => 'New password';

  @override
  String get createNewPassword => 'Create a new password';

  @override
  String get createNewPasswordSubtitle =>
      'Set a new password for your account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get sendCode => 'Send code';

  @override
  String get saveAndLogin => 'Save and sign in';

  @override
  String get phoneAlreadyRegistered =>
      'This phone number is already registered. Please sign in.';

  @override
  String get phoneNotRegistered =>
      'This phone number is not registered.';

  @override
  String get resendCode => 'Resend code';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get loginSubtitle => 'Enter your phone number and password';

  @override
  String get noAccountRegister => 'Don\'t have an account? Sign up';

  @override
  String enterPasswordFor(String phone) {
    return 'Enter the password for $phone';
  }

  @override
  String enterCodeFor(String phone) {
    return 'Enter the code sent to $phone';
  }

  @override
  String get fillInfoTitle => 'Fill in your details';

  @override
  String get fillInfoSubtitle => 'Enter your details to sign up';

  @override
  String get enterFirstName => 'Enter your first name';

  @override
  String get enterLastName => 'Enter your last name';

  @override
  String get offerAcceptTitle => 'I accept the user agreement';

  @override
  String get offerAcceptSubtitle =>
      'I agree to the processing of personal data and the app terms of use.';

  @override
  String get offerRequired => 'Please accept the offer terms.';

  @override
  String get loginRequiredMessage => 'Please sign in first.';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get fullNameTooShort => 'Name is too short';

  @override
  String get invalidEmail => 'Invalid email format';

  @override
  String get saving => 'Saving...';

  @override
  String get save => 'Save';

  @override
  String get loginRequiredTitle => 'Sign in to see your result';

  @override
  String get loginRequiredSubtitle =>
      'Analysis results, history and personal recommendations are available to registered users only.';

  @override
  String meaningFluency(int meaning, int fluency) {
    return 'Meaning $meaning · Fluency $fluency';
  }

  @override
  String get historySpeech => 'Speech analysis';

  @override
  String get historyObservation => 'Observation test';

  @override
  String get noCertificates =>
      'No certificates yet. Complete the courses fully — your certificate will be issued automatically.';

  @override
  String get date => 'Date';

  @override
  String get grade => 'Grade';

  @override
  String get serial => 'Serial';

  @override
  String get noHistory =>
      'No analyses yet. Try the speech or observation module.';

  @override
  String get contactBannerTitle => 'Najot Nur';

  @override
  String get contactBannerSubtitle =>
      'The public speaking centre — always ready to help you.';

  @override
  String get quickContact => 'Quick contact';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactPhone => 'Phone';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactAddress => 'Address';

  @override
  String get telegramHandle => '@najotnur_support';

  @override
  String get supportPhone => '+998 71 200 00 00';

  @override
  String get supportEmail => 'support@najotnur.uz';

  @override
  String get supportAddress => '10 Mustaqillik St, Tashkent';

  @override
  String get faqTitle => 'Frequently asked questions';

  @override
  String get faq1Q => 'How does speech analysis work?';

  @override
  String get faq1A =>
      'You record a 2-minute speech. The AI analyses meaning, fluency and filler words, then returns a detailed result.';

  @override
  String get faq2Q => 'How do I get a certificate?';

  @override
  String get faq2A =>
      'Complete all lessons and pass the tests. Once the course is 100% complete, the certificate is issued automatically.';

  @override
  String get faq3Q => 'Where are my results stored?';

  @override
  String get faq3A =>
      'All analyses and results are stored in your profile. You can view them in the «Analysis history» section.';

  @override
  String get faq4Q => 'I forgot my password, what do I do?';

  @override
  String get faq4A =>
      'On the sign-in screen, tap «Forgot password». A recovery code will be sent to your phone number.';

  @override
  String get noNotifications => 'No notifications yet.';

  @override
  String get audiencePersonal => 'Personal';

  @override
  String get audienceCourse => 'Course';

  @override
  String get audienceAll => 'Everyone';

  @override
  String get onboarding1Title => 'Grow your speech with NotiqAI';

  @override
  String get onboarding1Body =>
      'Use AI to analyse your public speaking skills, spot mistakes and reach mastery.';

  @override
  String get onboarding2Title => 'Voice and diction';

  @override
  String get onboarding2Body =>
      'Read the text out loud and the AI analyses your voice. Mispronounced sounds are highlighted in red.';

  @override
  String get onboarding3Title => 'Observation and speech';

  @override
  String get onboarding3Body =>
      '10 tests, video lessons and audiobooks — everything you need to succeed.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCourses => 'Lessons';

  @override
  String get tabBooks => 'Books';

  @override
  String get tabProfile => 'Profile';

  @override
  String get logoutConfirmTitle => 'Sign out?';

  @override
  String get logoutConfirmMessage =>
      'After signing out, you will need to sign in again.';

  @override
  String get logoutConfirmYes => 'Yes, sign out';

  @override
  String get logoutConfirmNo => 'Cancel';

  @override
  String get exitConfirmMessage => 'Do you want to exit? Tap back once more.';

  @override
  String get noAudiobooks => 'No audiobooks yet.';

  @override
  String get noCourses => 'No courses yet.';

  @override
  String get buyConfirmTitle => 'Buy?';

  @override
  String lessonNumber(int n) {
    return 'Lesson $n';
  }

  @override
  String get fillersTitle => 'Filler words';

  @override
  String get scoreMeaning => 'Meaning';

  @override
  String get scoreFluency => 'Fluency';

  @override
  String get scoreOverall => 'Overall score';

  @override
  String get errorWord => 'Mistake';

  @override
  String get voiceRecorded => 'Recorded ✓';

  @override
  String get reselectText => 'Pick a text again';

  @override
  String get next => 'Next';

  @override
  String get prev => 'Back';

  @override
  String questionCounter(int current, int total) {
    return '$current / $total';
  }

  @override
  String get submit => 'Submit';

  @override
  String get testComplete => 'Test complete';

  @override
  String get weakAreas => 'Strengths and weak areas';

  @override
  String get selectAnOption => 'Select an option';

  @override
  String get lessonList => 'Lessons';

  @override
  String get welcomeBody =>
      'The official app of the Najot Nur public speaking centre. Grow your speech, voice and observation skills with AI.';

  @override
  String get homeGreeting => 'What shall we try today?';

  @override
  String get homeSubtitle => 'You can try it without signing up.';

  @override
  String get homeActionSpeech => 'Check your speech';

  @override
  String get homeActionSpeechSub => 'AI will analyse your speech and voice';

  @override
  String get homeActionObservation => 'Check your observation';

  @override
  String get homeActionObservationSub =>
      '10 tests: psychology and body language';

  @override
  String get homeFeatures => 'Features';

  @override
  String get free => 'Free';

  @override
  String get forSale => 'For sale';

  @override
  String lessonsShort(int count) {
    return '$count lessons';
  }

  @override
  String andMore(int n) {
    return '$n more';
  }

  @override
  String sumPrice(String price) {
    return '$price UZS';
  }

  @override
  String get user => 'User';

  @override
  String get guest => 'Guest';

  @override
  String get notRegistered => 'Not registered';

  @override
  String get historySubtitle => 'Speech and observation results';

  @override
  String get certificatesSubtitle => 'For completed courses';

  @override
  String get notificationsSubtitle => 'New messages and announcements';

  @override
  String get helpSubtitle => 'Telegram, phone, FAQ';

  @override
  String get speechHubPrompt => 'Which direction shall we try?';

  @override
  String get speechHubSub =>
      'Voice — your diction, Speech — your clarity of thought.';

  @override
  String get voiceCheckDesc =>
      'Read the suggested text — the AI highlights sound and word errors in red and rates your diction.';

  @override
  String get speechAnalysisDesc =>
      'Speak about yourself for 2 minutes. The AI analyses filler words, pauses and clarity of thought.';

  @override
  String get noReferences => 'No texts found.';

  @override
  String get taskLabel => 'Task';

  @override
  String get selfIntroPrompt => 'Speak about yourself for ~2 minutes';

  @override
  String get balanceTooLittle => 'Too little information — add more detail';

  @override
  String get balanceTooMuch => 'Too much information — keep it shorter';

  @override
  String get balanceGood => 'The amount of information is well balanced';

  @override
  String get strengthsTitle => 'Strengths';

  @override
  String get improvementsTitle => 'Areas to improve';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get scoreOverallLabel => 'overall score';

  @override
  String get textWithErrors => 'Text — errors are highlighted in red';

  @override
  String get overallAnalysis => 'Overall analysis';

  @override
  String get soundErrors => 'Sound errors';

  @override
  String accuracyLabel(int score) {
    return 'Accuracy: $score%';
  }

  @override
  String get noTests => 'No tests found.';

  @override
  String get finishAndAnalyze => 'Finish and analyse';

  @override
  String answeredCount(int count) {
    return '$count answered';
  }

  @override
  String get mediaPlaceholder => 'Image/video coming soon';

  @override
  String get catPsychology => 'Psychology';

  @override
  String get catBodyLanguage => 'Body language';

  @override
  String get catObservation => 'Observation';

  @override
  String testNumber(int n) {
    return 'Test $n';
  }

  @override
  String get noPage => 'No page available.';

  @override
  String get paymentComingSoon =>
      'Payment integration (Uzum/ATMOS) coming soon!';

  @override
  String get paidAudiobook => 'Paid audiobook';

  @override
  String get buyAudiobookPrompt => 'Buy this audiobook to read it';

  @override
  String get noAudioFile => 'Audio file unavailable.';

  @override
  String audioLoadError(String error) {
    return 'Failed to load audio: $error';
  }

  @override
  String pageOfTotal(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String get loadingAudio => 'Loading…';

  @override
  String get paymentLater => 'Payment integration (Uzum/ATMOS) is coming next';

  @override
  String get startCourse => 'Start the course';

  @override
  String get aiExercise => 'AI exercise';

  @override
  String get speedLabel => 'Speed';

  @override
  String get qualityLabel => 'Video quality';

  @override
  String qualityChanged(String q) {
    return 'Video quality changed to $q';
  }

  @override
  String get start => 'Get started';

  @override
  String get logout => 'Sign out';

  @override
  String get retry => 'Retry';

  @override
  String get phoneLogin => 'Sign in with phone number';

  @override
  String get telegramLogin => 'Sign in with Telegram';

  @override
  String get telegramLoginSubtitle =>
      'Use your Telegram account — no password needed';

  @override
  String get orUse => 'or';

  @override
  String get telegramNotConfigured =>
      'Telegram login is not available right now. Please use your phone number.';

  @override
  String get telegramVerifying => 'Verifying with Telegram…';

  @override
  String telegramLoginFailed(String error) {
    return 'Telegram sign-in failed: $error';
  }

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneHint => '+998 XX XXX XX XX';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => '••••••';

  @override
  String get createPassword => 'Create a password';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get fullName => 'Full name';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get languagePrompt => 'Which language would you like to continue in?';

  @override
  String get uzbekLang => 'Uzbek';

  @override
  String get russianLang => 'Russian';

  @override
  String get englishLang => 'English';

  @override
  String get edit => 'Edit';

  @override
  String get profile => 'Profile';

  @override
  String get registerLogin => 'Sign up / Sign in';

  @override
  String get openFromMenu => 'Open from the menu below';

  @override
  String get audiobooks => 'Audiobooks';

  @override
  String get videoLessons => 'Video lessons';

  @override
  String get buy => 'Buy';

  @override
  String lessonsCount(int count) {
    return 'Lessons ($count)';
  }

  @override
  String minutesShort(int mins) {
    return '$mins min';
  }

  @override
  String pageNotFound(String uri) {
    return 'Page not found: $uri';
  }

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get certificates => 'My certificates';

  @override
  String pdfUrl(String url) {
    return 'PDF: $url';
  }

  @override
  String get pdfDownload => 'Download PDF';

  @override
  String get certRequestNew => 'Request Certificate';

  @override
  String get certRequestSend => 'Send Request';

  @override
  String get certRequestSent =>
      'Your certificate request has been sent to the curator.';

  @override
  String get certRequestPending => 'Pending';

  @override
  String get certRequestRejected => 'Rejected';

  @override
  String get certFullName => 'Name on certificate';

  @override
  String get certFullNameHint => 'e.g. Ali Aliyev';

  @override
  String get certSelectCourse => 'Select a course';

  @override
  String get certSelectCourseRequired => 'Please select a course';

  @override
  String get certRejectionReason => 'Reason';

  @override
  String get analysisHistory => 'Analysis history';

  @override
  String get helpContact => 'Help & contact';

  @override
  String get notifications => 'Notifications';

  @override
  String get voiceCheck => 'Voice check';

  @override
  String get voiceAnalysis => 'Voice analysis';

  @override
  String get speechCheck => 'Speech check';

  @override
  String get speechAnalysis => 'Speech analysis';

  @override
  String get speechText => 'Your speech text (editable)';

  @override
  String get speechHint => 'Hello, my name is...';

  @override
  String get noFillers => 'No filler words detected. Great!';

  @override
  String fillerCount(String key, int value) {
    return '$key × $value';
  }

  @override
  String get selectText => 'Select a text';

  @override
  String get readText => 'Read the text below';

  @override
  String get recognizedText => 'Recognized text (editable)';

  @override
  String get readWordsHint => 'The words you read...';

  @override
  String get analyze => 'Analyze';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get recordingReady => 'Recording captured. Ready to analyze.';

  @override
  String get backToHome => 'Back to home';

  @override
  String wordAndSound(String word, String sound) {
    return '$word  ·  «$sound»';
  }

  @override
  String get observationTest => 'Observation test';

  @override
  String get observationAnalysis => 'Observation analysis';

  @override
  String get back => 'Back';

  @override
  String get cannotOpenVideo => 'Could not open the video.';

  @override
  String get byDirections => 'By directions';

  @override
  String get changeLanguageSubtitle => 'Uzbek · Russian · English';

  @override
  String get supportChatTitle => 'Chat with us';

  @override
  String get supportChatSubtitle =>
      'Send us a question — we\'ll reply as soon as possible';

  @override
  String get chatInputHint => 'Type a message...';

  @override
  String get chatSend => 'Send';

  @override
  String get chatLoginRequired => 'Sign in to use the chat';

  @override
  String get chatNoMessages => 'No messages yet. Ask your first question!';

  @override
  String get chatSupport => 'Support';

  @override
  String get chatSending => 'Sending...';

  @override
  String get orderSheetCourseTitle => 'Request course access';

  @override
  String get orderSheetAudiobookTitle => 'Buy audiobook';

  @override
  String get amountLabel => 'Amount';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get paymentProofHint => 'Payment confirmation link (optional)';

  @override
  String get orderSubmit => 'Submit request';

  @override
  String get orderSubmitted => 'Your request has been submitted!';

  @override
  String get orderSheetFooter =>
      'After payment confirmation, access will be granted automatically.';

  @override
  String get methodUzum => 'Uzum';

  @override
  String get methodUzumNasiya => 'Uzum Nasiya';

  @override
  String get methodCash => 'Cash';

  @override
  String get uzumRedirectHint =>
      'You will be redirected to Uzum to complete the payment.';

  @override
  String get uzumNasiyaRedirectHint =>
      'You will be redirected to Uzum Nasiya to pay in installments.';

  @override
  String get audiobookOrderPending =>
      'Your order is being reviewed. Please wait.';

  @override
  String get orderPending => 'Order pending';

  @override
  String get myOrders => 'My Orders';

  @override
  String get myOrdersSubtitle => 'Course and audiobook purchases';

  @override
  String get noOrders => 'No orders yet.';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusApproved => 'Approved';

  @override
  String get orderStatusRejected => 'Rejected';

  @override
  String get orderTypeCourse => 'Course';

  @override
  String get orderTypeAudiobook => 'Audiobook';

  @override
  String get chatActionSubtitle => 'Write us a question';

  @override
  String get faqActionSubtitle => 'Frequently asked questions';

  @override
  String get loginRequired => 'Login required to access this section';

  @override
  String get loginRequiredBtn => 'Log in';

  @override
  String get practiceSpeech => 'Speech Practice';

  @override
  String get practiceSpeechSub =>
      'AI generates text — read it and get analysis';

  @override
  String get psychologyTest => 'Psychology Test';

  @override
  String get psychologyTestSub => 'Answer the questions and get AI analysis';

  @override
  String get psychologyAnalysis => 'Psychology analysis';

  @override
  String get psychologyIntro =>
      'Answer the questions below — AI will analyze your psychological profile';

  @override
  String get psychologyAiTitle => 'Sign in for AI analysis';

  @override
  String get psychologyAiSubtitle =>
      'Detailed psychological analysis, strengths and recommendations are available only for registered users.';

  @override
  String get selectDifficulty => 'Select difficulty level';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get generateText => 'Generate text';

  @override
  String get generatingText => 'Generating text...';

  @override
  String get practiceReadText => 'Read the following text aloud';

  @override
  String get tabPracticums => 'Practice';

  @override
  String get practicumsTitle => 'Practicums';

  @override
  String get practicumsSubtitle => 'Practical exercises with expert voice';

  @override
  String get noPracticums => 'No practicums yet.';

  @override
  String get tabTests => 'Tests';

  @override
  String get testsTitle => 'Tests';

  @override
  String get testsSubtitle => 'All available tests';

  @override
  String get quizEasy => 'Easy';

  @override
  String get quizMedium => 'Medium';

  @override
  String get quizHard => 'Hard';

  @override
  String quizQuestions(Object count) {
    return '$count questions';
  }

  @override
  String get quizStart => 'Start test';

  @override
  String get quizResult => 'Test result';

  @override
  String quizScore(Object correct, Object total) {
    return '$correct/$total correct';
  }

  @override
  String get quizCorrect => 'Correct';

  @override
  String get quizWrong => 'Wrong';

  @override
  String get quizFinish => 'Finish';

  @override
  String get quizNext => 'Next';

  @override
  String get noQuizzes => 'No tests available yet.';

  @override
  String get quizDraft => 'Under review';

  @override
  String get uploadAudio => 'Upload audio file';

  @override
  String get fileSelected => 'File selected. Ready to analyze.';

  @override
  String get orDivider => 'or';

  @override
  String get listenExpert => 'Listen to the expert';

  @override
  String get playAudio => 'Play';

  @override
  String get stopAudio => 'Stop';

  @override
  String get continueCourse => 'Continue';

  @override
  String get courseInProgress => 'In progress';

  @override
  String get courseCompleted => 'Course completed';

  @override
  String lessonsCompleted(int completed, int total) {
    return '$completed/$total lessons done';
  }

  @override
  String get lesson => 'Lesson';

  @override
  String get lessonTabVideo => 'Video';

  @override
  String get lessonTabQuiz => 'Quiz';

  @override
  String get lessonTabHomework => 'Homework';

  @override
  String get tapToWatch => 'Tap to watch';

  @override
  String get noVideoForLesson => 'No video available for this lesson';

  @override
  String get noQuizForLesson => 'No quiz for this lesson';

  @override
  String get lessonDescription => 'LESSON DESCRIPTION';

  @override
  String get markAsComplete => 'Mark as complete';

  @override
  String get completed => 'Completed';

  @override
  String get lessonCompleted => 'Lesson completed!';

  @override
  String lessonCompletedWithScore(int score) {
    return 'Lesson completed! Score: $score%';
  }

  @override
  String get videoOpenError => 'Failed to open video';

  @override
  String get quizLessonTitle => 'Lesson quiz';

  @override
  String quizLessonSubtitle(int count) {
    return '$count questions';
  }

  @override
  String get quizAnswerAll => 'Please answer all questions';

  @override
  String get submitQuiz => 'Submit quiz';

  @override
  String get quizPassed => 'Quiz passed!';

  @override
  String get quizFailed => 'Quiz failed';

  @override
  String quizCorrectCount(int correct, int total) {
    return '$correct/$total correct';
  }

  @override
  String get homeworkTitle => 'Homework';

  @override
  String get homeworkSubtitle =>
      'Complete the homework and submit it to your curator. You will see the result after review.';

  @override
  String get homeworkHint => 'Write your answer here...';

  @override
  String get homeworkEmpty => 'Please write your answer';

  @override
  String get homeworkSend => 'Submit';

  @override
  String get homeworkSubmitted => 'Homework submitted successfully!';

  @override
  String get homeworkPending => 'Curator is reviewing...';

  @override
  String get homeworkReviewed => 'Reviewed';

  @override
  String get homeworkResubmit => 'Resubmit';

  @override
  String get yourAnswer => 'YOUR ANSWER';

  @override
  String get curatorFeedback => 'CURATOR FEEDBACK';

  @override
  String get sending => 'Sending...';

  @override
  String get cancel => 'Cancel';

  @override
  String get securityCaptureDetected => 'Screen capture detected';

  @override
  String get securityCaptureSubtitle =>
      'Your screen is being recorded. Sensitive content is hidden. Stop the recording to continue.';
}
