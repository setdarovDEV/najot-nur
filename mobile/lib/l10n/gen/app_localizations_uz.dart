// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'NotiqAI';

  @override
  String get welcome => 'Xush kelibsiz';

  @override
  String get welcomeSubtitle =>
      'Davom etish uchun telefon raqamingiz orqali kiring';

  @override
  String get termsNotice =>
      'Davom etish orqali siz foydalanish shartlariga rozilik bildirasiz';

  @override
  String appVersion(String version) {
    return 'NotiqAI · v$version';
  }

  @override
  String get sessionExpired => 'Sessiya tugadi. Qayta kiring.';

  @override
  String get continueAction => 'Davom etish';

  @override
  String get login => 'Kirish';

  @override
  String get register => 'Ro\'yxatdan o\'tish';

  @override
  String get registerAndLogin => 'Ro\'yxatdan o\'tish va kirish';

  @override
  String get enterPassword => 'Parolni kiriting';

  @override
  String get verificationCode => 'Tasdiqlash kodi';

  @override
  String get stepPhone => 'Telefon';

  @override
  String get stepVerification => 'Tasdiqlash';

  @override
  String get stepInfo => 'Ma\'lumot';

  @override
  String get stepNewPassword => 'Yangi parol';

  @override
  String get enterPhoneTitle => 'Telefon raqamingizni kiriting';

  @override
  String get enterPhoneSubtitle =>
      'Sizning raqamingizga tasdiqlash kodi yuboriladi';

  @override
  String get enterPhoneForLogin =>
      'Tizimga kirish uchun telefon raqamingizni kiriting';

  @override
  String get enterPhoneForRegister =>
      'Ro\'yxatdan o\'tish uchun telefon raqamingizni kiriting';

  @override
  String get enterPhoneForReset =>
      'Parolni tiklash uchun telefon raqamingizni kiriting';

  @override
  String get invalidPhone => 'To\'g\'ri telefon raqam kiriting';

  @override
  String get passwordTooShort => 'Parol kamida 6 ta belgidan iborat bo\'lsin';

  @override
  String get codeTooShort => 'Kodni to\'liq kiriting';

  @override
  String get confirmPassword => 'Parolni tasdiqlang';

  @override
  String get confirmPasswordRequired => 'Parolni tasdiqlang';

  @override
  String get passwordsDoNotMatch => 'Parollar mos kelmadi';

  @override
  String get newPassword => 'Yangi parol';

  @override
  String get createNewPassword => 'Yangi parol yarating';

  @override
  String get createNewPasswordSubtitle =>
      'Hisobingizga kirish uchun yangi parol belgilang';

  @override
  String get forgotPassword => 'Parolni unutdingizmi?';

  @override
  String get sendCode => 'Kod yuborish';

  @override
  String get saveAndLogin => 'Saqlash va kirish';

  @override
  String get phoneAlreadyRegistered =>
      'Bu telefon raqam allaqachon ro\'yxatdan o\'tgan. Iltimos, kirish uchun o\'ting.';

  @override
  String get phoneNotRegistered => 'Bu telefon raqam ro\'yxatdan o\'tmagan.';

  @override
  String get resendCode => 'Kodni qayta yuborish';

  @override
  String get welcomeBack => 'Xush kelibsiz!';

  @override
  String get loginSubtitle => 'Telefon raqamingiz va parolingizni kiriting';

  @override
  String get noAccountRegister => 'Hisobingiz yo\'qmi? Ro\'yxatdan o\'ting';

  @override
  String enterPasswordFor(String phone) {
    return '$phone raqami uchun parolni kiriting';
  }

  @override
  String enterCodeFor(String phone) {
    return '$phone raqamiga yuborilgan kodni kiriting';
  }

  @override
  String get fillInfoTitle => 'Ma\'lumotlarni to\'ldiring';

  @override
  String get fillInfoSubtitle =>
      'Ro\'yxatdan o\'tish uchun quyidagilarni kiriting';

  @override
  String get enterFirstName => 'Ismni kiriting';

  @override
  String get enterLastName => 'Familiyani kiriting';

  @override
  String get offerAcceptTitle => 'Foydalanuvchi ofertasi shartlariga roziman';

  @override
  String get offerAcceptSubtitle =>
      'Shaxsiy ma\'lumotlarni qayta ishlashga va ilovadan foydalanish qoidalariga rozilik bildiraman.';

  @override
  String get offerRequired => 'Oferta shartlariga rozilik bildiring.';

  @override
  String get loginRequiredMessage => 'Avval tizimga kiring.';

  @override
  String get fullNameRequired => 'Ism familiya kiritilishi shart';

  @override
  String get fullNameTooShort => 'Ism juda qisqa';

  @override
  String get invalidEmail => 'Email formati noto\'g\'ri';

  @override
  String get saving => 'Saqlanmoqda...';

  @override
  String get save => 'Saqlash';

  @override
  String get loginRequiredTitle =>
      'Natijani ko\'rish uchun ro\'yxatdan o\'ting';

  @override
  String get loginRequiredSubtitle =>
      'Tahlil natijalari, tarix va shaxsiy tavsiyalar faqat ro\'yxatdan o\'tgan foydalanuvchilar uchun.';

  @override
  String meaningFluency(int meaning, int fluency) {
    return 'Mazmun $meaning · Ravonlik $fluency';
  }

  @override
  String get historySpeech => 'Nutq tahlili';

  @override
  String get historyObservation => 'Kuzatuv testi';

  @override
  String get noCertificates =>
      'Hali sertifikat yo\'q. Kurslarni to\'liq tugating — sertifikat avtomatik beriladi.';

  @override
  String get date => 'Sana';

  @override
  String get grade => 'Baho';

  @override
  String get serial => 'Serial';

  @override
  String get noHistory =>
      'Hozircha tahlillar yo\'q. Nutq yoki kuzatuv modulini sinab ko\'ring.';

  @override
  String get contactBannerTitle => 'Najot Nur';

  @override
  String get contactBannerSubtitle =>
      'Notiqlik mahorati markazi — sizning yordamingizga doimo tayyor.';

  @override
  String get quickContact => 'Tezkor aloqa';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactPhone => 'Telefon';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactAddress => 'Manzil';

  @override
  String get telegramHandle => '@najotnur_support';

  @override
  String get supportPhone => '+998 71 200 00 00';

  @override
  String get supportEmail => 'support@najotnur.uz';

  @override
  String get supportAddress => 'Toshkent sh., Mustaqillik ko\'chasi 10';

  @override
  String get faqTitle => 'Tez-tez beriladigan savollar';

  @override
  String get faq1Q => 'Nutq tahlili qanday ishlaydi?';

  @override
  String get faq1A =>
      'Siz 2 daqiqalik nutq yozib berasiz. AI mazmun, ravonlik va to\'ldiruvchi so\'zlarni tahlil qilib, batafsil natija qaytaradi.';

  @override
  String get faq2Q => 'Sertifikatni qanday olish mumkin?';

  @override
  String get faq2A =>
      'Kursdagi barcha darslarni tugating va testlardan o\'ting. Kurs 100% tugatilganda sertifikat avtomatik chiqariladi.';

  @override
  String get faq3Q => 'Natijalarim qayerda saqlanadi?';

  @override
  String get faq3A =>
      'Barcha tahlillar va natijalar profilingizda saqlanadi. \"Tahlillar tarixi\" bo\'limida ularni ko\'rishingiz mumkin.';

  @override
  String get faq4Q => 'Parolni unutdim, nima qilaman?';

  @override
  String get faq4A =>
      'Login sahifasida \"Parolni unutdim\" tugmasini bosing. Telefon raqamingizga tiklash kodi yuboriladi.';

  @override
  String get noNotifications => 'Hozircha bildirishnomalar yo\'q.';

  @override
  String get audiencePersonal => 'Shaxsiy';

  @override
  String get audienceCourse => 'Kurs';

  @override
  String get audienceAll => 'Hammaga';

  @override
  String get onboarding1Title => 'NotiqAI bilan nutqingizni rivojlantiring';

  @override
  String get onboarding1Body =>
      'Sun\'iy intellekt yordamida notiqlik mahoratingizni tahlil qiling, xatolarni aniqlang va ustunlikka erishing.';

  @override
  String get onboarding2Title => 'Ovoz va diktsiya';

  @override
  String get onboarding2Body =>
      'Matn o\'qing, ovozingiz AI tomonidan tahlil qilinadi. Xato tovushlar qizil rangda belgilanadi.';

  @override
  String get onboarding3Title => 'Kuzatuvchanlik va nutq';

  @override
  String get onboarding3Body =>
      '10 ta test, video darslar va audiokitoblar — barchasi sizning muvaffaqiyatingiz uchun.';

  @override
  String get onboardingNext => 'Keyingi';

  @override
  String get onboardingSkip => 'O\'tkazib yuborish';

  @override
  String get tabHome => 'Asosiy';

  @override
  String get tabCourses => 'Darslar';

  @override
  String get tabBooks => 'Kitoblar';

  @override
  String get tabProfile => 'Profil';

  @override
  String get logoutConfirmTitle => 'Tizimdan chiqmoqchimisiz?';

  @override
  String get logoutConfirmMessage =>
      'Tizimdan chiqsangiz, qayta kirishingiz kerak bo\'ladi.';

  @override
  String get logoutConfirmYes => 'Ha, chiqish';

  @override
  String get logoutConfirmNo => 'Bekor qilish';

  @override
  String get exitConfirmMessage =>
      'Chiqishni xohlaysizmi? Yana bir marta bosing.';

  @override
  String get noAudiobooks => 'Hozircha audiokitoblar yo\'q.';

  @override
  String get noCourses => 'Hozircha kurslar yo\'q.';

  @override
  String get buyConfirmTitle => 'Sotib olasizmi?';

  @override
  String lessonNumber(int n) {
    return 'Dars $n';
  }

  @override
  String get fillersTitle => 'Parazit so\'zlar';

  @override
  String get scoreMeaning => 'Mazmun';

  @override
  String get scoreFluency => 'Ravonlik';

  @override
  String get scoreOverall => 'Umumiy ball';

  @override
  String get errorWord => 'Xato so\'z';

  @override
  String get voiceRecorded => 'Yozib olindi ✓';

  @override
  String get reselectText => 'Matnni qayta tanlash';

  @override
  String get next => 'Keyingi';

  @override
  String get prev => 'Oldingi';

  @override
  String questionCounter(int current, int total) {
    return '$current / $total';
  }

  @override
  String get submit => 'Yuborish';

  @override
  String get testComplete => 'Test yakunlandi';

  @override
  String get weakAreas => 'Kuchli tomonlaringiz va kamchiliklaringiz';

  @override
  String get selectAnOption => 'Variantni tanlang';

  @override
  String get lessonList => 'Darslar';

  @override
  String get welcomeBody =>
      'Najot Nur notiqlik mahorati markazining rasmiy ilovasi. Nutq, ovoz va kuzatuvchanlikni sun\'iy intellekt yordamida rivojlantiring.';

  @override
  String get homeGreeting => 'Bugun nimani sinab ko\'ramiz?';

  @override
  String get homeSubtitle =>
      'Ro\'yxatdan o\'tmasdan ham sinab ko\'rishingiz mumkin.';

  @override
  String get homeActionSpeech => 'Nutqni tekshirish';

  @override
  String get homeActionSpeechSub => 'Nutq va ovozingizni AI tahlil qiladi';

  @override
  String get homeActionObservation => 'Kuzatuvchanlikni tekshirish';

  @override
  String get homeActionObservationSub => '10 ta test: psixologiya va tana tili';

  @override
  String get homeFeatures => 'Imkoniyatlar';

  @override
  String get homeRecommended => 'Tavsiya etamiz';

  @override
  String get free => 'Bepul';

  @override
  String get demoLabel => 'Demo';

  @override
  String get forSale => 'Sotuvda';

  @override
  String lessonsShort(int count) {
    return '$count dars';
  }

  @override
  String andMore(int n) {
    return 'Yana $n ta dars';
  }

  @override
  String sumPrice(String price) {
    return '$price so\'m';
  }

  @override
  String get user => 'Foydalanuvchi';

  @override
  String get guest => 'Mehmon';

  @override
  String get notRegistered => 'Ro\'yxatdan o\'tmagan';

  @override
  String get historySubtitle => 'Nutq va kuzatuv natijalari';

  @override
  String get certificatesSubtitle => 'Tugatgan kurslari bo\'yicha';

  @override
  String get notificationsSubtitle => 'Yangi xabarlar va e\'lonlar';

  @override
  String get helpSubtitle => 'Telegram, telefon, FAQ';

  @override
  String get speechHubPrompt => 'Qaysi yo\'nalishni sinab ko\'ramiz?';

  @override
  String get speechHubSub =>
      'Ovoz — talaffuzingizni, Nutq — fikr bayoningizni baholaydi.';

  @override
  String get voiceCheckDesc =>
      'Berilgan matnni o\'qing — AI xato tovush va so\'zlarni qizil rangda ko\'rsatib, talaffuzga baho beradi.';

  @override
  String get speechAnalysisDesc =>
      'O\'zingiz haqingizda 2 daqiqa gapiring. AI parazit so\'z, pauza va ma\'no yetkazilishini tahlil qiladi.';

  @override
  String get noReferences => 'Matnlar topilmadi.';

  @override
  String get taskLabel => 'Topshiriq';

  @override
  String get selfIntroPrompt => 'O\'zingiz haqingizda ~2 daqiqa gapirib bering';

  @override
  String get balanceTooLittle => 'Ma\'lumot kam — ko\'proq tafsilot bering';

  @override
  String get balanceTooMuch => 'Ma\'lumot ortiqcha — qisqaroq bayon eting';

  @override
  String get balanceGood => 'Ma\'lumot hajmi muvozanatli';

  @override
  String get strengthsTitle => 'Kuchli tomonlar';

  @override
  String get improvementsTitle => 'Yaxshilash uchun';

  @override
  String get summaryTitle => 'Umumiy xulosa';

  @override
  String get scoreOverallLabel => 'umumiy ball';

  @override
  String get textWithErrors => 'Matn — xatolar qizil rangda';

  @override
  String get overallAnalysis => 'Umumiy tahlil';

  @override
  String get soundErrors => 'Tovush xatolari';

  @override
  String accuracyLabel(int score) {
    return 'Aniqlik: $score%';
  }

  @override
  String get noTests => 'Testlar topilmadi.';

  @override
  String get finishAndAnalyze => 'Yakunlash va tahlil';

  @override
  String answeredCount(int count) {
    return '$count ta javob berildi';
  }

  @override
  String get mediaPlaceholder => 'Rasm/video tez kunda';

  @override
  String get catPsychology => 'Psixologiya';

  @override
  String get catBodyLanguage => 'Tana tili';

  @override
  String get catObservation => 'Kuzatuvchanlik';

  @override
  String testNumber(int n) {
    return 'Test $n';
  }

  @override
  String get noPage => 'Sahifa mavjud emas.';

  @override
  String get paymentComingSoon =>
      'To\'lov integratsiyasi (Uzum/ATMOS) tez kunda!';

  @override
  String get paidAudiobook => 'Pullik audiokitob';

  @override
  String get buyAudiobookPrompt => 'Bu audiokitobni o\'qish uchun sotib oling';

  @override
  String get noAudioFile => 'Audio fayl mavjud emas.';

  @override
  String audioLoadError(String error) {
    return 'Audio yuklanmadi: $error';
  }

  @override
  String pageOfTotal(int current, int total) {
    return '$current / $total sahifa';
  }

  @override
  String get loadingAudio => 'Yuklanmoqda…';

  @override
  String get paymentLater =>
      'To\'lov integratsiyasi (Uzum/ATMOS) keyingi bosqichda';

  @override
  String get startCourse => 'Kursni boshlash';

  @override
  String get aiExercise => 'AI mashq';

  @override
  String get speedLabel => 'Tezlik';

  @override
  String get qualityLabel => 'Video sifati';

  @override
  String qualityChanged(String q) {
    return 'Video sifati: $q ga o\'zgartirildi';
  }

  @override
  String get start => 'Boshlash';

  @override
  String get logout => 'Chiqish';

  @override
  String get retry => 'Qayta urinish';

  @override
  String get phoneLogin => 'Telefon raqam orqali kirish';

  @override
  String get orUse => 'yoki';

  @override
  String get phoneNumber => 'Telefon raqam';

  @override
  String get phoneHint => '+998 XX XXX XX XX';

  @override
  String get password => 'Parol';

  @override
  String get passwordHint => '••••••';

  @override
  String get createPassword => 'Parol yarating';

  @override
  String get firstName => 'Ism';

  @override
  String get lastName => 'Familiya';

  @override
  String get fullName => 'Ism familiya';

  @override
  String get emailOptional => 'Email (ixtiyoriy)';

  @override
  String get language => 'Til';

  @override
  String get selectLanguage => 'Tilni tanlash';

  @override
  String get languagePrompt => 'Ilovada qaysi tilda davom etmoqchisiz?';

  @override
  String get uzbekLang => 'O\'zbekcha';

  @override
  String get russianLang => 'Русский';

  @override
  String get englishLang => 'English';

  @override
  String get edit => 'Tahrirlash';

  @override
  String get profile => 'Profil';

  @override
  String get registerLogin => 'Ro\'yxatdan o\'tish / Kirish';

  @override
  String get openFromMenu => 'Pastdagi menyudan oching';

  @override
  String get audiobooks => 'Audiokitoblar';

  @override
  String get videoLessons => 'Video darslar';

  @override
  String get buy => 'Sotib olish';

  @override
  String lessonsCount(int count) {
    return 'Darslar ($count)';
  }

  @override
  String minutesShort(int mins) {
    return '$mins daqiqa';
  }

  @override
  String pageNotFound(String uri) {
    return 'Sahifa topilmadi: $uri';
  }

  @override
  String errorPrefix(String message) {
    return 'Xatolik: $message';
  }

  @override
  String get profileUpdated => 'Profil yangilandi.';

  @override
  String get profileEdit => 'Profilni tahrirlash';

  @override
  String get certificates => 'Sertifikatlarim';

  @override
  String pdfUrl(String url) {
    return 'PDF: $url';
  }

  @override
  String get pdfDownload => 'PDF yuklab olish';

  @override
  String get certRequestNew => 'Sertifikat so\'rash';

  @override
  String get certRequestSend => 'So\'rov yuborish';

  @override
  String get certRequestSent =>
      'Sertifikat so\'rovingiz curator(ga) yuborildi.';

  @override
  String get certRequestPending => 'Kutilmoqda';

  @override
  String get certRequestRejected => 'Rad etilgan';

  @override
  String get certFullName => 'Sertifikatdagi ism';

  @override
  String get certFullNameHint => 'Masalan: Aliyev Ali';

  @override
  String get certSelectCourse => 'Kursni tanlang';

  @override
  String get certSelectCourseRequired => 'Kurs tanlanishi shart';

  @override
  String get certRejectionReason => 'Sabab';

  @override
  String get analysisHistory => 'Tahlillar tarixi';

  @override
  String get helpContact => 'Yordam va aloqa';

  @override
  String get notifications => 'Bildirishnomalar';

  @override
  String get voiceCheck => 'Ovozni tekshirish';

  @override
  String get voiceAnalysis => 'Ovoz tahlili';

  @override
  String get speechCheck => 'Nutqni tekshirish';

  @override
  String get speechAnalysis => 'Nutq tahlili';

  @override
  String get speechText => 'Nutqingiz matni (tahrirlash mumkin)';

  @override
  String get speechHint => 'Assalomu alaykum, mening ismim...';

  @override
  String get noFillers => 'Parazit so\'zlar aniqlanmadi. Ajoyib!';

  @override
  String fillerCount(String key, int value) {
    return '$key × $value';
  }

  @override
  String get selectText => 'Matnni tanlang';

  @override
  String get readText => 'Quyidagi matnni o\'qing';

  @override
  String get recognizedText => 'Aniqlangan matn (tahrirlash mumkin)';

  @override
  String get readWordsHint => 'O\'qigan so\'zlaringiz...';

  @override
  String get analyze => 'Tahlil qilish';

  @override
  String get analyzing => 'Tahlil qilinmoqda...';

  @override
  String get recordingReady => 'Ovoz yozildi. Tahlil qilishga tayyor.';

  @override
  String get backToHome => 'Bosh sahifaga';

  @override
  String wordAndSound(String word, String sound) {
    return '$word  ·  «$sound»';
  }

  @override
  String get observationTest => 'Kuzatuvchanlik testi';

  @override
  String get observationAnalysis => 'Kuzatuvchanlik tahlili';

  @override
  String get back => 'Orqaga';

  @override
  String get cannotOpenVideo => 'Videoni ochib bo\'lmadi.';

  @override
  String get byDirections => 'Yo\'nalishlar bo\'yicha';

  @override
  String get changeLanguageSubtitle => 'O\'zbek · Русский · English';

  @override
  String get supportChatTitle => 'Bizga yozing';

  @override
  String get supportChatSubtitle =>
      'Savollaringizni yuboring — tez javob beramiz';

  @override
  String get chatInputHint => 'Xabaringizni yozing...';

  @override
  String get chatSend => 'Yuborish';

  @override
  String get chatLoginRequired => 'Chat uchun tizimga kirish kerak';

  @override
  String get chatNoMessages =>
      'Hozircha xabar yo\'q. Birinchi savolingizni yuboring!';

  @override
  String get chatSupport => 'Qo\'llab-quvvatlash';

  @override
  String get chatSending => 'Yuborilmoqda...';

  @override
  String get orderSheetCourseTitle => 'Kursga kirish so\'rovi';

  @override
  String get orderSheetAudiobookTitle => 'Audiokitob sotib olish';

  @override
  String get amountLabel => 'Narx';

  @override
  String get paymentMethod => 'To\'lov usuli';

  @override
  String get paymentProofHint => 'To\'lov tasdig\'i havolasi (ixtiyoriy)';

  @override
  String get orderSubmit => 'So\'rov yuborish';

  @override
  String get orderSubmitted => 'So\'rovingiz qabul qilindi!';

  @override
  String get orderSheetFooter =>
      'To\'lov tasdiqlanganidan so\'ng kirish avtomatik beriladi.';

  @override
  String get methodUzum => 'Uzum';

  @override
  String get methodUzumNasiya => 'Uzum Nasiya';

  @override
  String get methodCash => 'Naqd';

  @override
  String get uzumRedirectHint =>
      'To\'lovni yakunlash uchun Uzum saytiga yo\'naltirilasiz.';

  @override
  String get uzumNasiyaRedirectHint =>
      'Bo\'lib to\'lash uchun Uzum Nasiya saytiga yo\'naltirilasiz.';

  @override
  String get audiobookOrderPending =>
      'Buyurtmangiz ko\'rib chiqilmoqda. Iltimos, kuting.';

  @override
  String get orderPending => 'Buyurtma kutilmoqda';

  @override
  String get myOrders => 'Mening buyurtmalarim';

  @override
  String get myOrdersSubtitle => 'Kurs va audiokitob buyurtmalari';

  @override
  String get noOrders => 'Hozircha buyurtmalar yo\'q.';

  @override
  String get orderStatusPending => 'Kutilmoqda';

  @override
  String get orderStatusApproved => 'Tasdiqlangan';

  @override
  String get orderStatusRejected => 'Rad etilgan';

  @override
  String get orderTypeCourse => 'Kurs';

  @override
  String get orderTypeAudiobook => 'Audiokitob';

  @override
  String get chatActionSubtitle => 'Savolingizni yozing';

  @override
  String get faqActionSubtitle => 'Ko\'p so\'raladigan savollar';

  @override
  String get loginRequired => 'Bu bo\'lim uchun tizimga kirish kerak';

  @override
  String get loginRequiredBtn => 'Kirish';

  @override
  String get practiceSpeech => 'Talaffuz mashqi';

  @override
  String get practiceSpeechSub =>
      'AI matn generatsiya qiladi — o\'qing va tahlil oling';

  @override
  String get psychologyTest => 'Psixologik test';

  @override
  String get psychologyTestSub => 'Savollarga javob bering va AI tahlil oling';

  @override
  String get psychologyAnalysis => 'Psixologik tahlil';

  @override
  String get psychologyIntro =>
      'Quyidagi savollarga javob bering — AI sizning psixologik profilingizni tahlil qiladi';

  @override
  String get psychologyAiTitle => 'AI tahlil uchun tizimga kiring';

  @override
  String get psychologyAiSubtitle =>
      'Batafsil psixologik tahlil, kuchli tomonlar va tavsiyalar faqat ro\'yxatdan o\'tgan foydalanuvchilar uchun.';

  @override
  String get selectDifficulty => 'Qiyinlik darajasini tanlang';

  @override
  String get difficultyEasy => 'Oson';

  @override
  String get difficultyMedium => 'O\'rta';

  @override
  String get difficultyHard => 'Qiyin';

  @override
  String get generateText => 'Matn generatsiya qilish';

  @override
  String get generatingText => 'Matn yaratilmoqda...';

  @override
  String get practiceReadText => 'Quyidagi matnni ovoz chiqarib o\'qing';

  @override
  String get tabPracticums => 'Praktikum';

  @override
  String get practicumsTitle => 'Praktikumlar';

  @override
  String get practicumsSubtitle => 'Ekspert ovozi bilan amaliy mashqlar';

  @override
  String get noPracticums => 'Hozircha praktikumlar yo\'q.';

  @override
  String get tabTests => 'Testlar';

  @override
  String get testsTitle => 'Testlar';

  @override
  String get testsSubtitle => 'Barcha mavjud testlar';

  @override
  String get quizEasy => 'Oson';

  @override
  String get quizMedium => 'O\'rta';

  @override
  String get quizHard => 'Qiyin';

  @override
  String quizQuestions(Object count) {
    return '$count ta savol';
  }

  @override
  String get quizStart => 'Testni boshlash';

  @override
  String get quizResult => 'Test natijasi';

  @override
  String quizScore(Object correct, Object total) {
    return '$correct/$total to\'g\'ri';
  }

  @override
  String get quizCorrect => 'To\'g\'ri';

  @override
  String get quizWrong => 'Noto\'g\'ri';

  @override
  String get quizFinish => 'Yakunlash';

  @override
  String get quizNext => 'Keyingi';

  @override
  String get noQuizzes => 'Hozircha testlar yo\'q.';

  @override
  String get quizDraft => 'Tekshirilmoqda';

  @override
  String get uploadAudio => 'Audio fayl yuklash';

  @override
  String get fileSelected => 'Fayl tanlandi. Tahlil qilishga tayyor.';

  @override
  String get orDivider => 'yoki';

  @override
  String get listenExpert => 'Ekspert ovozini tinglang';

  @override
  String get playAudio => 'Tinglash';

  @override
  String get stopAudio => 'To\'xtatish';

  @override
  String get continueCourse => 'Davom ettirish';

  @override
  String get courseInProgress => 'O\'rganilmoqda';

  @override
  String get courseCompleted => 'Kurs yakunlangan';

  @override
  String lessonsCompleted(int completed, int total) {
    return '$completed/$total dars bajarildi';
  }

  @override
  String get lesson => 'Dars';

  @override
  String get lessonTabVideo => 'Video';

  @override
  String get lessonTabQuiz => 'Test';

  @override
  String get lessonTabHomework => 'Vazifa';

  @override
  String get tapToWatch => 'Ko\'rish uchun bosing';

  @override
  String get noVideoForLesson => 'Bu dars uchun video mavjud emas';

  @override
  String get noQuizForLesson => 'Bu dars uchun test mavjud emas';

  @override
  String get lessonDescription => 'DARS TAVSIFI';

  @override
  String get markAsComplete => 'Bajarildi deb belgilash';

  @override
  String get completed => 'Bajarildi';

  @override
  String get lessonCompleted => 'Dars yakunlandi!';

  @override
  String lessonCompletedWithScore(int score) {
    return 'Dars yakunlandi! Ball: $score%';
  }

  @override
  String get videoOpenError => 'Videoni ochib bo\'lmadi';

  @override
  String get quizLessonTitle => 'Dars testi';

  @override
  String quizLessonSubtitle(int count) {
    return '$count ta savol';
  }

  @override
  String get quizAnswerAll => 'Barcha savollarga javob bering';

  @override
  String get submitQuiz => 'Testni yuborish';

  @override
  String get quizPassed => 'Test muvaffaqiyatli o\'tildi!';

  @override
  String get quizFailed => 'Test o\'tilmadi';

  @override
  String quizCorrectCount(int correct, int total) {
    return '$correct/$total to\'g\'ri';
  }

  @override
  String get homeworkTitle => 'Uy vazifasi';

  @override
  String get homeworkSubtitle =>
      'Uy vazifasini bajaring va kuratoga yuboring. Kurator ko\'rib chiqqach, natijani ko\'rasiz.';

  @override
  String get homeworkHint => 'Javobingizni bu yerga yozing...';

  @override
  String get homeworkEmpty => 'Iltimos, javobingizni yozing';

  @override
  String get homeworkSend => 'Yuborish';

  @override
  String get homeworkSubmitted => 'Uy vazifasi muvaffaqiyatli yuborildi!';

  @override
  String get homeworkPending => 'Kurator tekshirmoqda...';

  @override
  String get homeworkReviewed => 'Baholandi';

  @override
  String get homeworkResubmit => 'Qayta yuborish';

  @override
  String get yourAnswer => 'SIZNING JAVOBINGIZ';

  @override
  String get curatorFeedback => 'KURATOR IZOHI';

  @override
  String get sending => 'Yuborilmoqda...';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get securityCaptureDetected => 'Ekran yozilayotgani aniqlandi';

  @override
  String get securityCaptureSubtitle =>
      'Sizning ekraningiz yozib olinmoqda. Maxfiy kontent yashirilgan. Davom etish uchun yozishni to\'xtating.';

  @override
  String get updateRequiredTitle => 'Yangilash talab qilinadi';

  @override
  String get updateRequiredMessage =>
      'NotiqAI ning yangi versiyasi chiqdi. Davom etish uchun ilovani yangilang.';

  @override
  String get updateNow => 'Yangilash';

  @override
  String get updateLater => 'Keyinroq';

  @override
  String get permissionGateTitle => 'Ruxsatlar kerak';

  @override
  String get permissionGateMessage =>
      'Ilova to\'liq ishlashi uchun quyidagi ruxsatlarni bering:';

  @override
  String get permissionMicrophone => 'Mikrofon';

  @override
  String get permissionLocation => 'Joylashuv';

  @override
  String get permissionNotification => 'Bildirishnomalar';

  @override
  String get permissionGrant => 'Ruxsat berish';

  @override
  String get permissionOpenSettings => 'Sozlamalarga o\'tish';

  @override
  String get permissionLater => 'Keyinroq';

  @override
  String get gradeTitleExcellent => 'A\'lo darajadagi natija!';

  @override
  String get gradeTitleGood => 'Yaxshi natija!';

  @override
  String get gradeTitleAverage => 'O\'rtacha natija';

  @override
  String get gradeTitleWeak => 'Kuchsiz natija';

  @override
  String get analysisMetrics => 'Ko\'rsatkichlar';

  @override
  String get metricVoiceConfidence => 'Ovoz ishonchliligi';

  @override
  String get metricPauseBalance => 'Pauzalar balansi';

  @override
  String get metricFillerWords => 'Parazit so\'zlar';

  @override
  String get metricThoughtFlow => 'Fikr izchilligi';

  @override
  String get metricPronunciationAccuracy => 'Talaffuz aniqligi';

  @override
  String get metricWordAccuracy => 'So\'z to\'g\'riligi';

  @override
  String get metricAvgWordScore => 'O\'rtacha ball';

  @override
  String get metricPhonemeErrors => 'Fonema aniqligi';

  @override
  String get gradePronunciationPerfect =>
      'Barcha so\'zlar to\'g\'ri talaffuz qilindi!';

  @override
  String get gradePronunciationMinor => 'Bir nechta kichik xatolik aniqlandi.';

  @override
  String gradePronunciationNeedsWork(int count) {
    return '$count ta so\'zda xatolik topildi.';
  }

  @override
  String get perfectPronunciation =>
      'A\'lo! Barcha so\'zlar to\'g\'ri aytildi.';

  @override
  String get charLevelAnalysis => 'Harf darajasidagi tahlil';

  @override
  String get psychologyScoreLabel => 'Psixologik ball';

  @override
  String get quizGradeTitle => 'Test natijasi';

  @override
  String get quizGoodSubtitle => 'Ajoyib! Natijangiz yaxshi.';

  @override
  String get quizBadSubtitle => 'Qayta urinib ko\'ring, siz qila olasiz!';

  @override
  String get quizMetricScore => 'Umumiy ball';

  @override
  String get quizMetricCorrect => 'To\'g\'ri javoblar';

  @override
  String get tryAgain => 'Qayta urinish';

  @override
  String get levelBeginner => 'Boshlang\'ich';

  @override
  String get levelIntermediate => 'O\'rta';

  @override
  String get levelAdvanced => 'Yuqori';

  @override
  String get filterAll => 'Barchasi';

  @override
  String get searchCoursesHint => 'Kurs qidirish…';

  @override
  String coursesCount(int count) {
    return '$count ta kurs';
  }

  @override
  String get priceLabel => 'Narx';
}
