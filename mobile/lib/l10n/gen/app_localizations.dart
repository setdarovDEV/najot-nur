import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz')
  ];

  /// No description provided for @appName.
  ///
  /// In uz, this message translates to:
  /// **'NotiqAI'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In uz, this message translates to:
  /// **'Xush kelibsiz'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish uchun telefon raqamingiz orqali kiring'**
  String get welcomeSubtitle;

  /// No description provided for @termsNotice.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish orqali siz foydalanish shartlariga rozilik bildirasiz'**
  String get termsNotice;

  /// No description provided for @appVersion.
  ///
  /// In uz, this message translates to:
  /// **'NotiqAI · v{version}'**
  String appVersion(String version);

  /// No description provided for @sessionExpired.
  ///
  /// In uz, this message translates to:
  /// **'Sessiya tugadi. Qayta kiring.'**
  String get sessionExpired;

  /// No description provided for @continueAction.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueAction;

  /// No description provided for @login.
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get login;

  /// No description provided for @register.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish'**
  String get register;

  /// No description provided for @registerAndLogin.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish va kirish'**
  String get registerAndLogin;

  /// No description provided for @enterPassword.
  ///
  /// In uz, this message translates to:
  /// **'Parolni kiriting'**
  String get enterPassword;

  /// No description provided for @verificationCode.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash kodi'**
  String get verificationCode;

  /// No description provided for @stepPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon'**
  String get stepPhone;

  /// No description provided for @stepVerification.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get stepVerification;

  /// No description provided for @stepInfo.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumot'**
  String get stepInfo;

  /// No description provided for @stepNewPassword.
  ///
  /// In uz, this message translates to:
  /// **'Yangi parol'**
  String get stepNewPassword;

  /// No description provided for @enterPhoneTitle.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamingizni kiriting'**
  String get enterPhoneTitle;

  /// No description provided for @enterPhoneSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Sizning raqamingizga tasdiqlash kodi yuboriladi'**
  String get enterPhoneSubtitle;

  /// No description provided for @enterPhoneForLogin.
  ///
  /// In uz, this message translates to:
  /// **'Tizimga kirish uchun telefon raqamingizni kiriting'**
  String get enterPhoneForLogin;

  /// No description provided for @enterPhoneForRegister.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish uchun telefon raqamingizni kiriting'**
  String get enterPhoneForRegister;

  /// No description provided for @enterPhoneForReset.
  ///
  /// In uz, this message translates to:
  /// **'Parolni tiklash uchun telefon raqamingizni kiriting'**
  String get enterPhoneForReset;

  /// No description provided for @invalidPhone.
  ///
  /// In uz, this message translates to:
  /// **'To\'g\'ri telefon raqam kiriting'**
  String get invalidPhone;

  /// No description provided for @passwordTooShort.
  ///
  /// In uz, this message translates to:
  /// **'Parol kamida 6 ta belgidan iborat bo\'lsin'**
  String get passwordTooShort;

  /// No description provided for @codeTooShort.
  ///
  /// In uz, this message translates to:
  /// **'Kodni to\'liq kiriting'**
  String get codeTooShort;

  /// No description provided for @confirmPassword.
  ///
  /// In uz, this message translates to:
  /// **'Parolni tasdiqlang'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In uz, this message translates to:
  /// **'Parolni tasdiqlang'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In uz, this message translates to:
  /// **'Parollar mos kelmadi'**
  String get passwordsDoNotMatch;

  /// No description provided for @newPassword.
  ///
  /// In uz, this message translates to:
  /// **'Yangi parol'**
  String get newPassword;

  /// No description provided for @createNewPassword.
  ///
  /// In uz, this message translates to:
  /// **'Yangi parol yarating'**
  String get createNewPassword;

  /// No description provided for @createNewPasswordSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingizga kirish uchun yangi parol belgilang'**
  String get createNewPasswordSubtitle;

  /// No description provided for @forgotPassword.
  ///
  /// In uz, this message translates to:
  /// **'Parolni unutdingizmi?'**
  String get forgotPassword;

  /// No description provided for @sendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod yuborish'**
  String get sendCode;

  /// No description provided for @saveAndLogin.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash va kirish'**
  String get saveAndLogin;

  /// No description provided for @phoneAlreadyRegistered.
  ///
  /// In uz, this message translates to:
  /// **'Bu telefon raqam allaqachon ro\'yxatdan o\'tgan. Iltimos, kirish uchun o\'ting.'**
  String get phoneAlreadyRegistered;

  /// No description provided for @phoneNotRegistered.
  ///
  /// In uz, this message translates to:
  /// **'Bu telefon raqam ro\'yxatdan o\'tmagan.'**
  String get phoneNotRegistered;

  /// No description provided for @resendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qayta yuborish'**
  String get resendCode;

  /// No description provided for @welcomeBack.
  ///
  /// In uz, this message translates to:
  /// **'Xush kelibsiz!'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamingiz va parolingizni kiriting'**
  String get loginSubtitle;

  /// No description provided for @noAccountRegister.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingiz yo\'qmi? Ro\'yxatdan o\'ting'**
  String get noAccountRegister;

  /// No description provided for @enterPasswordFor.
  ///
  /// In uz, this message translates to:
  /// **'{phone} raqami uchun parolni kiriting'**
  String enterPasswordFor(String phone);

  /// No description provided for @enterCodeFor.
  ///
  /// In uz, this message translates to:
  /// **'{phone} raqamiga yuborilgan kodni kiriting'**
  String enterCodeFor(String phone);

  /// No description provided for @fillInfoTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarni to\'ldiring'**
  String get fillInfoTitle;

  /// No description provided for @fillInfoSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish uchun quyidagilarni kiriting'**
  String get fillInfoSubtitle;

  /// No description provided for @enterFirstName.
  ///
  /// In uz, this message translates to:
  /// **'Ismni kiriting'**
  String get enterFirstName;

  /// No description provided for @enterLastName.
  ///
  /// In uz, this message translates to:
  /// **'Familiyani kiriting'**
  String get enterLastName;

  /// No description provided for @offerAcceptTitle.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi ofertasi shartlariga roziman'**
  String get offerAcceptTitle;

  /// No description provided for @offerAcceptSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Shaxsiy ma\'lumotlarni qayta ishlashga va ilovadan foydalanish qoidalariga rozilik bildiraman.'**
  String get offerAcceptSubtitle;

  /// No description provided for @offerRequired.
  ///
  /// In uz, this message translates to:
  /// **'Oferta shartlariga rozilik bildiring.'**
  String get offerRequired;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In uz, this message translates to:
  /// **'Avval tizimga kiring.'**
  String get loginRequiredMessage;

  /// No description provided for @fullNameRequired.
  ///
  /// In uz, this message translates to:
  /// **'Ism familiya kiritilishi shart'**
  String get fullNameRequired;

  /// No description provided for @fullNameTooShort.
  ///
  /// In uz, this message translates to:
  /// **'Ism juda qisqa'**
  String get fullNameTooShort;

  /// No description provided for @invalidEmail.
  ///
  /// In uz, this message translates to:
  /// **'Email formati noto\'g\'ri'**
  String get invalidEmail;

  /// No description provided for @saving.
  ///
  /// In uz, this message translates to:
  /// **'Saqlanmoqda...'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get save;

  /// No description provided for @loginRequiredTitle.
  ///
  /// In uz, this message translates to:
  /// **'Natijani ko\'rish uchun ro\'yxatdan o\'ting'**
  String get loginRequiredTitle;

  /// No description provided for @loginRequiredSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil natijalari, tarix va shaxsiy tavsiyalar faqat ro\'yxatdan o\'tgan foydalanuvchilar uchun.'**
  String get loginRequiredSubtitle;

  /// No description provided for @meaningFluency.
  ///
  /// In uz, this message translates to:
  /// **'Mazmun {meaning} · Ravonlik {fluency}'**
  String meaningFluency(int meaning, int fluency);

  /// No description provided for @historySpeech.
  ///
  /// In uz, this message translates to:
  /// **'Nutq tahlili'**
  String get historySpeech;

  /// No description provided for @historyObservation.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuv testi'**
  String get historyObservation;

  /// No description provided for @noCertificates.
  ///
  /// In uz, this message translates to:
  /// **'Hali sertifikat yo\'q. Kurslarni to\'liq tugating — sertifikat avtomatik beriladi.'**
  String get noCertificates;

  /// No description provided for @date.
  ///
  /// In uz, this message translates to:
  /// **'Sana'**
  String get date;

  /// No description provided for @grade.
  ///
  /// In uz, this message translates to:
  /// **'Baho'**
  String get grade;

  /// No description provided for @serial.
  ///
  /// In uz, this message translates to:
  /// **'Serial'**
  String get serial;

  /// No description provided for @noHistory.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha tahlillar yo\'q. Nutq yoki kuzatuv modulini sinab ko\'ring.'**
  String get noHistory;

  /// No description provided for @contactBannerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Najot Nur'**
  String get contactBannerTitle;

  /// No description provided for @contactBannerSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Notiqlik mahorati markazi — sizning yordamingizga doimo tayyor.'**
  String get contactBannerSubtitle;

  /// No description provided for @quickContact.
  ///
  /// In uz, this message translates to:
  /// **'Tezkor aloqa'**
  String get quickContact;

  /// No description provided for @contactTelegram.
  ///
  /// In uz, this message translates to:
  /// **'Telegram'**
  String get contactTelegram;

  /// No description provided for @contactPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon'**
  String get contactPhone;

  /// No description provided for @contactEmail.
  ///
  /// In uz, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @contactAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get contactAddress;

  /// No description provided for @telegramHandle.
  ///
  /// In uz, this message translates to:
  /// **'@najotnur_support'**
  String get telegramHandle;

  /// No description provided for @supportPhone.
  ///
  /// In uz, this message translates to:
  /// **'+998 71 200 00 00'**
  String get supportPhone;

  /// No description provided for @supportEmail.
  ///
  /// In uz, this message translates to:
  /// **'support@najotnur.uz'**
  String get supportEmail;

  /// No description provided for @supportAddress.
  ///
  /// In uz, this message translates to:
  /// **'Toshkent sh., Mustaqillik ko\'chasi 10'**
  String get supportAddress;

  /// No description provided for @faqTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tez-tez beriladigan savollar'**
  String get faqTitle;

  /// No description provided for @faq1Q.
  ///
  /// In uz, this message translates to:
  /// **'Nutq tahlili qanday ishlaydi?'**
  String get faq1Q;

  /// No description provided for @faq1A.
  ///
  /// In uz, this message translates to:
  /// **'Siz 2 daqiqalik nutq yozib berasiz. AI mazmun, ravonlik va to\'ldiruvchi so\'zlarni tahlil qilib, batafsil natija qaytaradi.'**
  String get faq1A;

  /// No description provided for @faq2Q.
  ///
  /// In uz, this message translates to:
  /// **'Sertifikatni qanday olish mumkin?'**
  String get faq2Q;

  /// No description provided for @faq2A.
  ///
  /// In uz, this message translates to:
  /// **'Kursdagi barcha darslarni tugating va testlardan o\'ting. Kurs 100% tugatilganda sertifikat avtomatik chiqariladi.'**
  String get faq2A;

  /// No description provided for @faq3Q.
  ///
  /// In uz, this message translates to:
  /// **'Natijalarim qayerda saqlanadi?'**
  String get faq3Q;

  /// No description provided for @faq3A.
  ///
  /// In uz, this message translates to:
  /// **'Barcha tahlillar va natijalar profilingizda saqlanadi. \"Tahlillar tarixi\" bo\'limida ularni ko\'rishingiz mumkin.'**
  String get faq3A;

  /// No description provided for @faq4Q.
  ///
  /// In uz, this message translates to:
  /// **'Parolni unutdim, nima qilaman?'**
  String get faq4Q;

  /// No description provided for @faq4A.
  ///
  /// In uz, this message translates to:
  /// **'Login sahifasida \"Parolni unutdim\" tugmasini bosing. Telefon raqamingizga tiklash kodi yuboriladi.'**
  String get faq4A;

  /// No description provided for @noNotifications.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha bildirishnomalar yo\'q.'**
  String get noNotifications;

  /// No description provided for @audiencePersonal.
  ///
  /// In uz, this message translates to:
  /// **'Shaxsiy'**
  String get audiencePersonal;

  /// No description provided for @audienceCourse.
  ///
  /// In uz, this message translates to:
  /// **'Kurs'**
  String get audienceCourse;

  /// No description provided for @audienceAll.
  ///
  /// In uz, this message translates to:
  /// **'Hammaga'**
  String get audienceAll;

  /// No description provided for @onboarding1Title.
  ///
  /// In uz, this message translates to:
  /// **'NotiqAI bilan nutqingizni rivojlantiring'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In uz, this message translates to:
  /// **'Sun\'iy intellekt yordamida notiqlik mahoratingizni tahlil qiling, xatolarni aniqlang va ustunlikka erishing.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In uz, this message translates to:
  /// **'Ovoz va diktsiya'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In uz, this message translates to:
  /// **'Matn o\'qing, ovozingiz AI tomonidan tahlil qilinadi. Xato tovushlar qizil rangda belgilanadi.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvchanlik va nutq'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In uz, this message translates to:
  /// **'10 ta test, video darslar va audiokitoblar — barchasi sizning muvaffaqiyatingiz uchun.'**
  String get onboarding3Body;

  /// No description provided for @onboardingNext.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In uz, this message translates to:
  /// **'O\'tkazib yuborish'**
  String get onboardingSkip;

  /// No description provided for @tabHome.
  ///
  /// In uz, this message translates to:
  /// **'Asosiy'**
  String get tabHome;

  /// No description provided for @tabCourses.
  ///
  /// In uz, this message translates to:
  /// **'Darslar'**
  String get tabCourses;

  /// No description provided for @tabBooks.
  ///
  /// In uz, this message translates to:
  /// **'Kitoblar'**
  String get tabBooks;

  /// No description provided for @tabProfile.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tizimdan chiqmoqchimisiz?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In uz, this message translates to:
  /// **'Tizimdan chiqsangiz, qayta kirishingiz kerak bo\'ladi.'**
  String get logoutConfirmMessage;

  /// No description provided for @logoutConfirmYes.
  ///
  /// In uz, this message translates to:
  /// **'Ha, chiqish'**
  String get logoutConfirmYes;

  /// No description provided for @logoutConfirmNo.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get logoutConfirmNo;

  /// No description provided for @exitConfirmMessage.
  ///
  /// In uz, this message translates to:
  /// **'Chiqishni xohlaysizmi? Yana bir marta bosing.'**
  String get exitConfirmMessage;

  /// No description provided for @noAudiobooks.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha audiokitoblar yo\'q.'**
  String get noAudiobooks;

  /// No description provided for @noCourses.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha kurslar yo\'q.'**
  String get noCourses;

  /// No description provided for @buyConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sotib olasizmi?'**
  String get buyConfirmTitle;

  /// No description provided for @lessonNumber.
  ///
  /// In uz, this message translates to:
  /// **'Dars {n}'**
  String lessonNumber(int n);

  /// No description provided for @fillersTitle.
  ///
  /// In uz, this message translates to:
  /// **'Parazit so\'zlar'**
  String get fillersTitle;

  /// No description provided for @scoreMeaning.
  ///
  /// In uz, this message translates to:
  /// **'Mazmun'**
  String get scoreMeaning;

  /// No description provided for @scoreFluency.
  ///
  /// In uz, this message translates to:
  /// **'Ravonlik'**
  String get scoreFluency;

  /// No description provided for @scoreOverall.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy ball'**
  String get scoreOverall;

  /// No description provided for @errorWord.
  ///
  /// In uz, this message translates to:
  /// **'Xato so\'z'**
  String get errorWord;

  /// No description provided for @voiceRecorded.
  ///
  /// In uz, this message translates to:
  /// **'Yozib olindi ✓'**
  String get voiceRecorded;

  /// No description provided for @reselectText.
  ///
  /// In uz, this message translates to:
  /// **'Matnni qayta tanlash'**
  String get reselectText;

  /// No description provided for @next.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi'**
  String get next;

  /// No description provided for @prev.
  ///
  /// In uz, this message translates to:
  /// **'Oldingi'**
  String get prev;

  /// No description provided for @questionCounter.
  ///
  /// In uz, this message translates to:
  /// **'{current} / {total}'**
  String questionCounter(int current, int total);

  /// No description provided for @submit.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get submit;

  /// No description provided for @testComplete.
  ///
  /// In uz, this message translates to:
  /// **'Test yakunlandi'**
  String get testComplete;

  /// No description provided for @weakAreas.
  ///
  /// In uz, this message translates to:
  /// **'Kuchli tomonlaringiz va kamchiliklaringiz'**
  String get weakAreas;

  /// No description provided for @selectAnOption.
  ///
  /// In uz, this message translates to:
  /// **'Variantni tanlang'**
  String get selectAnOption;

  /// No description provided for @lessonList.
  ///
  /// In uz, this message translates to:
  /// **'Darslar'**
  String get lessonList;

  /// No description provided for @welcomeBody.
  ///
  /// In uz, this message translates to:
  /// **'Najot Nur notiqlik mahorati markazining rasmiy ilovasi. Nutq, ovoz va kuzatuvchanlikni sun\'iy intellekt yordamida rivojlantiring.'**
  String get welcomeBody;

  /// No description provided for @homeGreeting.
  ///
  /// In uz, this message translates to:
  /// **'Bugun nimani sinab ko\'ramiz?'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tmasdan ham sinab ko\'rishingiz mumkin.'**
  String get homeSubtitle;

  /// No description provided for @homeActionSpeech.
  ///
  /// In uz, this message translates to:
  /// **'Nutqni tekshirish'**
  String get homeActionSpeech;

  /// No description provided for @homeActionSpeechSub.
  ///
  /// In uz, this message translates to:
  /// **'Nutq va ovozingizni AI tahlil qiladi'**
  String get homeActionSpeechSub;

  /// No description provided for @homeActionObservation.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvchanlikni tekshirish'**
  String get homeActionObservation;

  /// No description provided for @homeActionObservationSub.
  ///
  /// In uz, this message translates to:
  /// **'10 ta test: psixologiya va tana tili'**
  String get homeActionObservationSub;

  /// No description provided for @homeFeatures.
  ///
  /// In uz, this message translates to:
  /// **'Imkoniyatlar'**
  String get homeFeatures;

  /// No description provided for @homeRecommended.
  ///
  /// In uz, this message translates to:
  /// **'Tavsiya etamiz'**
  String get homeRecommended;

  /// No description provided for @free.
  ///
  /// In uz, this message translates to:
  /// **'Bepul'**
  String get free;

  /// No description provided for @forSale.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvda'**
  String get forSale;

  /// No description provided for @lessonsShort.
  ///
  /// In uz, this message translates to:
  /// **'{count} dars'**
  String lessonsShort(int count);

  /// No description provided for @andMore.
  ///
  /// In uz, this message translates to:
  /// **'Yana {n} ta dars'**
  String andMore(int n);

  /// No description provided for @sumPrice.
  ///
  /// In uz, this message translates to:
  /// **'{price} so\'m'**
  String sumPrice(String price);

  /// No description provided for @user.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi'**
  String get user;

  /// No description provided for @guest.
  ///
  /// In uz, this message translates to:
  /// **'Mehmon'**
  String get guest;

  /// No description provided for @notRegistered.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tmagan'**
  String get notRegistered;

  /// No description provided for @historySubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Nutq va kuzatuv natijalari'**
  String get historySubtitle;

  /// No description provided for @certificatesSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Tugatgan kurslari bo\'yicha'**
  String get certificatesSubtitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi xabarlar va e\'lonlar'**
  String get notificationsSubtitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Telegram, telefon, FAQ'**
  String get helpSubtitle;

  /// No description provided for @speechHubPrompt.
  ///
  /// In uz, this message translates to:
  /// **'Qaysi yo\'nalishni sinab ko\'ramiz?'**
  String get speechHubPrompt;

  /// No description provided for @speechHubSub.
  ///
  /// In uz, this message translates to:
  /// **'Ovoz — talaffuzingizni, Nutq — fikr bayoningizni baholaydi.'**
  String get speechHubSub;

  /// No description provided for @voiceCheckDesc.
  ///
  /// In uz, this message translates to:
  /// **'Berilgan matnni o\'qing — AI xato tovush va so\'zlarni qizil rangda ko\'rsatib, talaffuzga baho beradi.'**
  String get voiceCheckDesc;

  /// No description provided for @speechAnalysisDesc.
  ///
  /// In uz, this message translates to:
  /// **'O\'zingiz haqingizda 2 daqiqa gapiring. AI parazit so\'z, pauza va ma\'no yetkazilishini tahlil qiladi.'**
  String get speechAnalysisDesc;

  /// No description provided for @noReferences.
  ///
  /// In uz, this message translates to:
  /// **'Matnlar topilmadi.'**
  String get noReferences;

  /// No description provided for @taskLabel.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriq'**
  String get taskLabel;

  /// No description provided for @selfIntroPrompt.
  ///
  /// In uz, this message translates to:
  /// **'O\'zingiz haqingizda ~2 daqiqa gapirib bering'**
  String get selfIntroPrompt;

  /// No description provided for @balanceTooLittle.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumot kam — ko\'proq tafsilot bering'**
  String get balanceTooLittle;

  /// No description provided for @balanceTooMuch.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumot ortiqcha — qisqaroq bayon eting'**
  String get balanceTooMuch;

  /// No description provided for @balanceGood.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumot hajmi muvozanatli'**
  String get balanceGood;

  /// No description provided for @strengthsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kuchli tomonlar'**
  String get strengthsTitle;

  /// No description provided for @improvementsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yaxshilash uchun'**
  String get improvementsTitle;

  /// No description provided for @summaryTitle.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy xulosa'**
  String get summaryTitle;

  /// No description provided for @scoreOverallLabel.
  ///
  /// In uz, this message translates to:
  /// **'umumiy ball'**
  String get scoreOverallLabel;

  /// No description provided for @textWithErrors.
  ///
  /// In uz, this message translates to:
  /// **'Matn — xatolar qizil rangda'**
  String get textWithErrors;

  /// No description provided for @overallAnalysis.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy tahlil'**
  String get overallAnalysis;

  /// No description provided for @soundErrors.
  ///
  /// In uz, this message translates to:
  /// **'Tovush xatolari'**
  String get soundErrors;

  /// No description provided for @accuracyLabel.
  ///
  /// In uz, this message translates to:
  /// **'Aniqlik: {score}%'**
  String accuracyLabel(int score);

  /// No description provided for @noTests.
  ///
  /// In uz, this message translates to:
  /// **'Testlar topilmadi.'**
  String get noTests;

  /// No description provided for @finishAndAnalyze.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlash va tahlil'**
  String get finishAndAnalyze;

  /// No description provided for @answeredCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta javob berildi'**
  String answeredCount(int count);

  /// No description provided for @mediaPlaceholder.
  ///
  /// In uz, this message translates to:
  /// **'Rasm/video tez kunda'**
  String get mediaPlaceholder;

  /// No description provided for @catPsychology.
  ///
  /// In uz, this message translates to:
  /// **'Psixologiya'**
  String get catPsychology;

  /// No description provided for @catBodyLanguage.
  ///
  /// In uz, this message translates to:
  /// **'Tana tili'**
  String get catBodyLanguage;

  /// No description provided for @catObservation.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvchanlik'**
  String get catObservation;

  /// No description provided for @testNumber.
  ///
  /// In uz, this message translates to:
  /// **'Test {n}'**
  String testNumber(int n);

  /// No description provided for @noPage.
  ///
  /// In uz, this message translates to:
  /// **'Sahifa mavjud emas.'**
  String get noPage;

  /// No description provided for @paymentComingSoon.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov integratsiyasi (Uzum/ATMOS) tez kunda!'**
  String get paymentComingSoon;

  /// No description provided for @paidAudiobook.
  ///
  /// In uz, this message translates to:
  /// **'Pullik audiokitob'**
  String get paidAudiobook;

  /// No description provided for @buyAudiobookPrompt.
  ///
  /// In uz, this message translates to:
  /// **'Bu audiokitobni o\'qish uchun sotib oling'**
  String get buyAudiobookPrompt;

  /// No description provided for @noAudioFile.
  ///
  /// In uz, this message translates to:
  /// **'Audio fayl mavjud emas.'**
  String get noAudioFile;

  /// No description provided for @audioLoadError.
  ///
  /// In uz, this message translates to:
  /// **'Audio yuklanmadi: {error}'**
  String audioLoadError(String error);

  /// No description provided for @pageOfTotal.
  ///
  /// In uz, this message translates to:
  /// **'{current} / {total} sahifa'**
  String pageOfTotal(int current, int total);

  /// No description provided for @loadingAudio.
  ///
  /// In uz, this message translates to:
  /// **'Yuklanmoqda…'**
  String get loadingAudio;

  /// No description provided for @paymentLater.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov integratsiyasi (Uzum/ATMOS) keyingi bosqichda'**
  String get paymentLater;

  /// No description provided for @startCourse.
  ///
  /// In uz, this message translates to:
  /// **'Kursni boshlash'**
  String get startCourse;

  /// No description provided for @aiExercise.
  ///
  /// In uz, this message translates to:
  /// **'AI mashq'**
  String get aiExercise;

  /// No description provided for @speedLabel.
  ///
  /// In uz, this message translates to:
  /// **'Tezlik'**
  String get speedLabel;

  /// No description provided for @qualityLabel.
  ///
  /// In uz, this message translates to:
  /// **'Video sifati'**
  String get qualityLabel;

  /// No description provided for @qualityChanged.
  ///
  /// In uz, this message translates to:
  /// **'Video sifati: {q} ga o\'zgartirildi'**
  String qualityChanged(String q);

  /// No description provided for @start.
  ///
  /// In uz, this message translates to:
  /// **'Boshlash'**
  String get start;

  /// No description provided for @logout.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get logout;

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retry;

  /// No description provided for @phoneLogin.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqam orqali kirish'**
  String get phoneLogin;

  /// No description provided for @orUse.
  ///
  /// In uz, this message translates to:
  /// **'yoki'**
  String get orUse;

  /// No description provided for @phoneNumber.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqam'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In uz, this message translates to:
  /// **'+998 XX XXX XX XX'**
  String get phoneHint;

  /// No description provided for @password.
  ///
  /// In uz, this message translates to:
  /// **'Parol'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In uz, this message translates to:
  /// **'••••••'**
  String get passwordHint;

  /// No description provided for @createPassword.
  ///
  /// In uz, this message translates to:
  /// **'Parol yarating'**
  String get createPassword;

  /// No description provided for @firstName.
  ///
  /// In uz, this message translates to:
  /// **'Ism'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In uz, this message translates to:
  /// **'Familiya'**
  String get lastName;

  /// No description provided for @fullName.
  ///
  /// In uz, this message translates to:
  /// **'Ism familiya'**
  String get fullName;

  /// No description provided for @emailOptional.
  ///
  /// In uz, this message translates to:
  /// **'Email (ixtiyoriy)'**
  String get emailOptional;

  /// No description provided for @language.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In uz, this message translates to:
  /// **'Tilni tanlash'**
  String get selectLanguage;

  /// No description provided for @languagePrompt.
  ///
  /// In uz, this message translates to:
  /// **'Ilovada qaysi tilda davom etmoqchisiz?'**
  String get languagePrompt;

  /// No description provided for @uzbekLang.
  ///
  /// In uz, this message translates to:
  /// **'O\'zbekcha'**
  String get uzbekLang;

  /// No description provided for @russianLang.
  ///
  /// In uz, this message translates to:
  /// **'Русский'**
  String get russianLang;

  /// No description provided for @englishLang.
  ///
  /// In uz, this message translates to:
  /// **'English'**
  String get englishLang;

  /// No description provided for @edit.
  ///
  /// In uz, this message translates to:
  /// **'Tahrirlash'**
  String get edit;

  /// No description provided for @profile.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @registerLogin.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish / Kirish'**
  String get registerLogin;

  /// No description provided for @openFromMenu.
  ///
  /// In uz, this message translates to:
  /// **'Pastdagi menyudan oching'**
  String get openFromMenu;

  /// No description provided for @audiobooks.
  ///
  /// In uz, this message translates to:
  /// **'Audiokitoblar'**
  String get audiobooks;

  /// No description provided for @videoLessons.
  ///
  /// In uz, this message translates to:
  /// **'Video darslar'**
  String get videoLessons;

  /// No description provided for @buy.
  ///
  /// In uz, this message translates to:
  /// **'Sotib olish'**
  String get buy;

  /// No description provided for @lessonsCount.
  ///
  /// In uz, this message translates to:
  /// **'Darslar ({count})'**
  String lessonsCount(int count);

  /// No description provided for @minutesShort.
  ///
  /// In uz, this message translates to:
  /// **'{mins} daqiqa'**
  String minutesShort(int mins);

  /// No description provided for @pageNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Sahifa topilmadi: {uri}'**
  String pageNotFound(String uri);

  /// No description provided for @errorPrefix.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik: {message}'**
  String errorPrefix(String message);

  /// No description provided for @profileUpdated.
  ///
  /// In uz, this message translates to:
  /// **'Profil yangilandi.'**
  String get profileUpdated;

  /// No description provided for @profileEdit.
  ///
  /// In uz, this message translates to:
  /// **'Profilni tahrirlash'**
  String get profileEdit;

  /// No description provided for @certificates.
  ///
  /// In uz, this message translates to:
  /// **'Sertifikatlarim'**
  String get certificates;

  /// No description provided for @pdfUrl.
  ///
  /// In uz, this message translates to:
  /// **'PDF: {url}'**
  String pdfUrl(String url);

  /// No description provided for @pdfDownload.
  ///
  /// In uz, this message translates to:
  /// **'PDF yuklab olish'**
  String get pdfDownload;

  /// No description provided for @certRequestNew.
  ///
  /// In uz, this message translates to:
  /// **'Sertifikat so\'rash'**
  String get certRequestNew;

  /// No description provided for @certRequestSend.
  ///
  /// In uz, this message translates to:
  /// **'So\'rov yuborish'**
  String get certRequestSend;

  /// No description provided for @certRequestSent.
  ///
  /// In uz, this message translates to:
  /// **'Sertifikat so\'rovingiz curator(ga) yuborildi.'**
  String get certRequestSent;

  /// No description provided for @certRequestPending.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda'**
  String get certRequestPending;

  /// No description provided for @certRequestRejected.
  ///
  /// In uz, this message translates to:
  /// **'Rad etilgan'**
  String get certRequestRejected;

  /// No description provided for @certFullName.
  ///
  /// In uz, this message translates to:
  /// **'Sertifikatdagi ism'**
  String get certFullName;

  /// No description provided for @certFullNameHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Aliyev Ali'**
  String get certFullNameHint;

  /// No description provided for @certSelectCourse.
  ///
  /// In uz, this message translates to:
  /// **'Kursni tanlang'**
  String get certSelectCourse;

  /// No description provided for @certSelectCourseRequired.
  ///
  /// In uz, this message translates to:
  /// **'Kurs tanlanishi shart'**
  String get certSelectCourseRequired;

  /// No description provided for @certRejectionReason.
  ///
  /// In uz, this message translates to:
  /// **'Sabab'**
  String get certRejectionReason;

  /// No description provided for @analysisHistory.
  ///
  /// In uz, this message translates to:
  /// **'Tahlillar tarixi'**
  String get analysisHistory;

  /// No description provided for @helpContact.
  ///
  /// In uz, this message translates to:
  /// **'Yordam va aloqa'**
  String get helpContact;

  /// No description provided for @notifications.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get notifications;

  /// No description provided for @voiceCheck.
  ///
  /// In uz, this message translates to:
  /// **'Ovozni tekshirish'**
  String get voiceCheck;

  /// No description provided for @voiceAnalysis.
  ///
  /// In uz, this message translates to:
  /// **'Ovoz tahlili'**
  String get voiceAnalysis;

  /// No description provided for @speechCheck.
  ///
  /// In uz, this message translates to:
  /// **'Nutqni tekshirish'**
  String get speechCheck;

  /// No description provided for @speechAnalysis.
  ///
  /// In uz, this message translates to:
  /// **'Nutq tahlili'**
  String get speechAnalysis;

  /// No description provided for @speechText.
  ///
  /// In uz, this message translates to:
  /// **'Nutqingiz matni (tahrirlash mumkin)'**
  String get speechText;

  /// No description provided for @speechHint.
  ///
  /// In uz, this message translates to:
  /// **'Assalomu alaykum, mening ismim...'**
  String get speechHint;

  /// No description provided for @noFillers.
  ///
  /// In uz, this message translates to:
  /// **'Parazit so\'zlar aniqlanmadi. Ajoyib!'**
  String get noFillers;

  /// No description provided for @fillerCount.
  ///
  /// In uz, this message translates to:
  /// **'{key} × {value}'**
  String fillerCount(String key, int value);

  /// No description provided for @selectText.
  ///
  /// In uz, this message translates to:
  /// **'Matnni tanlang'**
  String get selectText;

  /// No description provided for @readText.
  ///
  /// In uz, this message translates to:
  /// **'Quyidagi matnni o\'qing'**
  String get readText;

  /// No description provided for @recognizedText.
  ///
  /// In uz, this message translates to:
  /// **'Aniqlangan matn (tahrirlash mumkin)'**
  String get recognizedText;

  /// No description provided for @readWordsHint.
  ///
  /// In uz, this message translates to:
  /// **'O\'qigan so\'zlaringiz...'**
  String get readWordsHint;

  /// No description provided for @analyze.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil qilish'**
  String get analyze;

  /// No description provided for @analyzing.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil qilinmoqda...'**
  String get analyzing;

  /// No description provided for @recordingReady.
  ///
  /// In uz, this message translates to:
  /// **'Ovoz yozildi. Tahlil qilishga tayyor.'**
  String get recordingReady;

  /// No description provided for @backToHome.
  ///
  /// In uz, this message translates to:
  /// **'Bosh sahifaga'**
  String get backToHome;

  /// No description provided for @wordAndSound.
  ///
  /// In uz, this message translates to:
  /// **'{word}  ·  «{sound}»'**
  String wordAndSound(String word, String sound);

  /// No description provided for @observationTest.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvchanlik testi'**
  String get observationTest;

  /// No description provided for @observationAnalysis.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvchanlik tahlili'**
  String get observationAnalysis;

  /// No description provided for @back.
  ///
  /// In uz, this message translates to:
  /// **'Orqaga'**
  String get back;

  /// No description provided for @cannotOpenVideo.
  ///
  /// In uz, this message translates to:
  /// **'Videoni ochib bo\'lmadi.'**
  String get cannotOpenVideo;

  /// No description provided for @byDirections.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'nalishlar bo\'yicha'**
  String get byDirections;

  /// No description provided for @changeLanguageSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'O\'zbek · Русский · English'**
  String get changeLanguageSubtitle;

  /// No description provided for @supportChatTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bizga yozing'**
  String get supportChatTitle;

  /// No description provided for @supportChatSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Savollaringizni yuboring — tez javob beramiz'**
  String get supportChatSubtitle;

  /// No description provided for @chatInputHint.
  ///
  /// In uz, this message translates to:
  /// **'Xabaringizni yozing...'**
  String get chatInputHint;

  /// No description provided for @chatSend.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get chatSend;

  /// No description provided for @chatLoginRequired.
  ///
  /// In uz, this message translates to:
  /// **'Chat uchun tizimga kirish kerak'**
  String get chatLoginRequired;

  /// No description provided for @chatNoMessages.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha xabar yo\'q. Birinchi savolingizni yuboring!'**
  String get chatNoMessages;

  /// No description provided for @chatSupport.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'llab-quvvatlash'**
  String get chatSupport;

  /// No description provided for @chatSending.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilmoqda...'**
  String get chatSending;

  /// No description provided for @orderSheetCourseTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kursga kirish so\'rovi'**
  String get orderSheetCourseTitle;

  /// No description provided for @orderSheetAudiobookTitle.
  ///
  /// In uz, this message translates to:
  /// **'Audiokitob sotib olish'**
  String get orderSheetAudiobookTitle;

  /// No description provided for @amountLabel.
  ///
  /// In uz, this message translates to:
  /// **'Narx'**
  String get amountLabel;

  /// No description provided for @paymentMethod.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov usuli'**
  String get paymentMethod;

  /// No description provided for @paymentProofHint.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov tasdig\'i havolasi (ixtiyoriy)'**
  String get paymentProofHint;

  /// No description provided for @orderSubmit.
  ///
  /// In uz, this message translates to:
  /// **'So\'rov yuborish'**
  String get orderSubmit;

  /// No description provided for @orderSubmitted.
  ///
  /// In uz, this message translates to:
  /// **'So\'rovingiz qabul qilindi!'**
  String get orderSubmitted;

  /// No description provided for @orderSheetFooter.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov tasdiqlanganidan so\'ng kirish avtomatik beriladi.'**
  String get orderSheetFooter;

  /// No description provided for @methodUzum.
  ///
  /// In uz, this message translates to:
  /// **'Uzum'**
  String get methodUzum;

  /// No description provided for @methodUzumNasiya.
  ///
  /// In uz, this message translates to:
  /// **'Uzum Nasiya'**
  String get methodUzumNasiya;

  /// No description provided for @methodCash.
  ///
  /// In uz, this message translates to:
  /// **'Naqd'**
  String get methodCash;

  /// No description provided for @uzumRedirectHint.
  ///
  /// In uz, this message translates to:
  /// **'To\'lovni yakunlash uchun Uzum saytiga yo\'naltirilasiz.'**
  String get uzumRedirectHint;

  /// No description provided for @uzumNasiyaRedirectHint.
  ///
  /// In uz, this message translates to:
  /// **'Bo\'lib to\'lash uchun Uzum Nasiya saytiga yo\'naltirilasiz.'**
  String get uzumNasiyaRedirectHint;

  /// No description provided for @audiobookOrderPending.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmangiz ko\'rib chiqilmoqda. Iltimos, kuting.'**
  String get audiobookOrderPending;

  /// No description provided for @orderPending.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma kutilmoqda'**
  String get orderPending;

  /// No description provided for @myOrders.
  ///
  /// In uz, this message translates to:
  /// **'Mening buyurtmalarim'**
  String get myOrders;

  /// No description provided for @myOrdersSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Kurs va audiokitob buyurtmalari'**
  String get myOrdersSubtitle;

  /// No description provided for @noOrders.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha buyurtmalar yo\'q.'**
  String get noOrders;

  /// No description provided for @orderStatusPending.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda'**
  String get orderStatusPending;

  /// No description provided for @orderStatusApproved.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlangan'**
  String get orderStatusApproved;

  /// No description provided for @orderStatusRejected.
  ///
  /// In uz, this message translates to:
  /// **'Rad etilgan'**
  String get orderStatusRejected;

  /// No description provided for @orderTypeCourse.
  ///
  /// In uz, this message translates to:
  /// **'Kurs'**
  String get orderTypeCourse;

  /// No description provided for @orderTypeAudiobook.
  ///
  /// In uz, this message translates to:
  /// **'Audiokitob'**
  String get orderTypeAudiobook;

  /// No description provided for @chatActionSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Savolingizni yozing'**
  String get chatActionSubtitle;

  /// No description provided for @faqActionSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'p so\'raladigan savollar'**
  String get faqActionSubtitle;

  /// No description provided for @loginRequired.
  ///
  /// In uz, this message translates to:
  /// **'Bu bo\'lim uchun tizimga kirish kerak'**
  String get loginRequired;

  /// No description provided for @loginRequiredBtn.
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get loginRequiredBtn;

  /// No description provided for @practiceSpeech.
  ///
  /// In uz, this message translates to:
  /// **'Talaffuz mashqi'**
  String get practiceSpeech;

  /// No description provided for @practiceSpeechSub.
  ///
  /// In uz, this message translates to:
  /// **'AI matn generatsiya qiladi — o\'qing va tahlil oling'**
  String get practiceSpeechSub;

  /// No description provided for @psychologyTest.
  ///
  /// In uz, this message translates to:
  /// **'Psixologik test'**
  String get psychologyTest;

  /// No description provided for @psychologyTestSub.
  ///
  /// In uz, this message translates to:
  /// **'Savollarga javob bering va AI tahlil oling'**
  String get psychologyTestSub;

  /// No description provided for @psychologyAnalysis.
  ///
  /// In uz, this message translates to:
  /// **'Psixologik tahlil'**
  String get psychologyAnalysis;

  /// No description provided for @psychologyIntro.
  ///
  /// In uz, this message translates to:
  /// **'Quyidagi savollarga javob bering — AI sizning psixologik profilingizni tahlil qiladi'**
  String get psychologyIntro;

  /// No description provided for @psychologyAiTitle.
  ///
  /// In uz, this message translates to:
  /// **'AI tahlil uchun tizimga kiring'**
  String get psychologyAiTitle;

  /// No description provided for @psychologyAiSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Batafsil psixologik tahlil, kuchli tomonlar va tavsiyalar faqat ro\'yxatdan o\'tgan foydalanuvchilar uchun.'**
  String get psychologyAiSubtitle;

  /// No description provided for @selectDifficulty.
  ///
  /// In uz, this message translates to:
  /// **'Qiyinlik darajasini tanlang'**
  String get selectDifficulty;

  /// No description provided for @difficultyEasy.
  ///
  /// In uz, this message translates to:
  /// **'Oson'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In uz, this message translates to:
  /// **'O\'rta'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In uz, this message translates to:
  /// **'Qiyin'**
  String get difficultyHard;

  /// No description provided for @generateText.
  ///
  /// In uz, this message translates to:
  /// **'Matn generatsiya qilish'**
  String get generateText;

  /// No description provided for @generatingText.
  ///
  /// In uz, this message translates to:
  /// **'Matn yaratilmoqda...'**
  String get generatingText;

  /// No description provided for @practiceReadText.
  ///
  /// In uz, this message translates to:
  /// **'Quyidagi matnni ovoz chiqarib o\'qing'**
  String get practiceReadText;

  /// No description provided for @tabPracticums.
  ///
  /// In uz, this message translates to:
  /// **'Praktikum'**
  String get tabPracticums;

  /// No description provided for @practicumsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Praktikumlar'**
  String get practicumsTitle;

  /// No description provided for @practicumsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ekspert ovozi bilan amaliy mashqlar'**
  String get practicumsSubtitle;

  /// No description provided for @noPracticums.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha praktikumlar yo\'q.'**
  String get noPracticums;

  /// No description provided for @tabTests.
  ///
  /// In uz, this message translates to:
  /// **'Testlar'**
  String get tabTests;

  /// No description provided for @testsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Testlar'**
  String get testsTitle;

  /// No description provided for @testsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Barcha mavjud testlar'**
  String get testsSubtitle;

  /// No description provided for @quizEasy.
  ///
  /// In uz, this message translates to:
  /// **'Oson'**
  String get quizEasy;

  /// No description provided for @quizMedium.
  ///
  /// In uz, this message translates to:
  /// **'O\'rta'**
  String get quizMedium;

  /// No description provided for @quizHard.
  ///
  /// In uz, this message translates to:
  /// **'Qiyin'**
  String get quizHard;

  /// No description provided for @quizQuestions.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta savol'**
  String quizQuestions(Object count);

  /// No description provided for @quizStart.
  ///
  /// In uz, this message translates to:
  /// **'Testni boshlash'**
  String get quizStart;

  /// No description provided for @quizResult.
  ///
  /// In uz, this message translates to:
  /// **'Test natijasi'**
  String get quizResult;

  /// No description provided for @quizScore.
  ///
  /// In uz, this message translates to:
  /// **'{correct}/{total} to\'g\'ri'**
  String quizScore(Object correct, Object total);

  /// No description provided for @quizCorrect.
  ///
  /// In uz, this message translates to:
  /// **'To\'g\'ri'**
  String get quizCorrect;

  /// No description provided for @quizWrong.
  ///
  /// In uz, this message translates to:
  /// **'Noto\'g\'ri'**
  String get quizWrong;

  /// No description provided for @quizFinish.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlash'**
  String get quizFinish;

  /// No description provided for @quizNext.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi'**
  String get quizNext;

  /// No description provided for @noQuizzes.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha testlar yo\'q.'**
  String get noQuizzes;

  /// No description provided for @quizDraft.
  ///
  /// In uz, this message translates to:
  /// **'Tekshirilmoqda'**
  String get quizDraft;

  /// No description provided for @uploadAudio.
  ///
  /// In uz, this message translates to:
  /// **'Audio fayl yuklash'**
  String get uploadAudio;

  /// No description provided for @fileSelected.
  ///
  /// In uz, this message translates to:
  /// **'Fayl tanlandi. Tahlil qilishga tayyor.'**
  String get fileSelected;

  /// No description provided for @orDivider.
  ///
  /// In uz, this message translates to:
  /// **'yoki'**
  String get orDivider;

  /// No description provided for @listenExpert.
  ///
  /// In uz, this message translates to:
  /// **'Ekspert ovozini tinglang'**
  String get listenExpert;

  /// No description provided for @playAudio.
  ///
  /// In uz, this message translates to:
  /// **'Tinglash'**
  String get playAudio;

  /// No description provided for @stopAudio.
  ///
  /// In uz, this message translates to:
  /// **'To\'xtatish'**
  String get stopAudio;

  /// No description provided for @continueCourse.
  ///
  /// In uz, this message translates to:
  /// **'Davom ettirish'**
  String get continueCourse;

  /// No description provided for @courseInProgress.
  ///
  /// In uz, this message translates to:
  /// **'O\'rganilmoqda'**
  String get courseInProgress;

  /// No description provided for @courseCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Kurs yakunlangan'**
  String get courseCompleted;

  /// No description provided for @lessonsCompleted.
  ///
  /// In uz, this message translates to:
  /// **'{completed}/{total} dars bajarildi'**
  String lessonsCompleted(int completed, int total);

  /// No description provided for @lesson.
  ///
  /// In uz, this message translates to:
  /// **'Dars'**
  String get lesson;

  /// No description provided for @lessonTabVideo.
  ///
  /// In uz, this message translates to:
  /// **'Video'**
  String get lessonTabVideo;

  /// No description provided for @lessonTabQuiz.
  ///
  /// In uz, this message translates to:
  /// **'Test'**
  String get lessonTabQuiz;

  /// No description provided for @lessonTabHomework.
  ///
  /// In uz, this message translates to:
  /// **'Vazifa'**
  String get lessonTabHomework;

  /// No description provided for @tapToWatch.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rish uchun bosing'**
  String get tapToWatch;

  /// No description provided for @noVideoForLesson.
  ///
  /// In uz, this message translates to:
  /// **'Bu dars uchun video mavjud emas'**
  String get noVideoForLesson;

  /// No description provided for @noQuizForLesson.
  ///
  /// In uz, this message translates to:
  /// **'Bu dars uchun test mavjud emas'**
  String get noQuizForLesson;

  /// No description provided for @lessonDescription.
  ///
  /// In uz, this message translates to:
  /// **'DARS TAVSIFI'**
  String get lessonDescription;

  /// No description provided for @markAsComplete.
  ///
  /// In uz, this message translates to:
  /// **'Bajarildi deb belgilash'**
  String get markAsComplete;

  /// No description provided for @completed.
  ///
  /// In uz, this message translates to:
  /// **'Bajarildi'**
  String get completed;

  /// No description provided for @lessonCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Dars yakunlandi!'**
  String get lessonCompleted;

  /// No description provided for @lessonCompletedWithScore.
  ///
  /// In uz, this message translates to:
  /// **'Dars yakunlandi! Ball: {score}%'**
  String lessonCompletedWithScore(int score);

  /// No description provided for @videoOpenError.
  ///
  /// In uz, this message translates to:
  /// **'Videoni ochib bo\'lmadi'**
  String get videoOpenError;

  /// No description provided for @quizLessonTitle.
  ///
  /// In uz, this message translates to:
  /// **'Dars testi'**
  String get quizLessonTitle;

  /// No description provided for @quizLessonSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta savol'**
  String quizLessonSubtitle(int count);

  /// No description provided for @quizAnswerAll.
  ///
  /// In uz, this message translates to:
  /// **'Barcha savollarga javob bering'**
  String get quizAnswerAll;

  /// No description provided for @submitQuiz.
  ///
  /// In uz, this message translates to:
  /// **'Testni yuborish'**
  String get submitQuiz;

  /// No description provided for @quizPassed.
  ///
  /// In uz, this message translates to:
  /// **'Test muvaffaqiyatli o\'tildi!'**
  String get quizPassed;

  /// No description provided for @quizFailed.
  ///
  /// In uz, this message translates to:
  /// **'Test o\'tilmadi'**
  String get quizFailed;

  /// No description provided for @quizCorrectCount.
  ///
  /// In uz, this message translates to:
  /// **'{correct}/{total} to\'g\'ri'**
  String quizCorrectCount(int correct, int total);

  /// No description provided for @homeworkTitle.
  ///
  /// In uz, this message translates to:
  /// **'Uy vazifasi'**
  String get homeworkTitle;

  /// No description provided for @homeworkSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Uy vazifasini bajaring va kuratoga yuboring. Kurator ko\'rib chiqqach, natijani ko\'rasiz.'**
  String get homeworkSubtitle;

  /// No description provided for @homeworkHint.
  ///
  /// In uz, this message translates to:
  /// **'Javobingizni bu yerga yozing...'**
  String get homeworkHint;

  /// No description provided for @homeworkEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, javobingizni yozing'**
  String get homeworkEmpty;

  /// No description provided for @homeworkSend.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get homeworkSend;

  /// No description provided for @homeworkSubmitted.
  ///
  /// In uz, this message translates to:
  /// **'Uy vazifasi muvaffaqiyatli yuborildi!'**
  String get homeworkSubmitted;

  /// No description provided for @homeworkPending.
  ///
  /// In uz, this message translates to:
  /// **'Kurator tekshirmoqda...'**
  String get homeworkPending;

  /// No description provided for @homeworkReviewed.
  ///
  /// In uz, this message translates to:
  /// **'Baholandi'**
  String get homeworkReviewed;

  /// No description provided for @homeworkResubmit.
  ///
  /// In uz, this message translates to:
  /// **'Qayta yuborish'**
  String get homeworkResubmit;

  /// No description provided for @yourAnswer.
  ///
  /// In uz, this message translates to:
  /// **'SIZNING JAVOBINGIZ'**
  String get yourAnswer;

  /// No description provided for @curatorFeedback.
  ///
  /// In uz, this message translates to:
  /// **'KURATOR IZOHI'**
  String get curatorFeedback;

  /// No description provided for @sending.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilmoqda...'**
  String get sending;

  /// No description provided for @cancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get cancel;

  /// No description provided for @securityCaptureDetected.
  ///
  /// In uz, this message translates to:
  /// **'Ekran yozilayotgani aniqlandi'**
  String get securityCaptureDetected;

  /// No description provided for @securityCaptureSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Sizning ekraningiz yozib olinmoqda. Maxfiy kontent yashirilgan. Davom etish uchun yozishni to\'xtating.'**
  String get securityCaptureSubtitle;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangilash talab qilinadi'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredMessage.
  ///
  /// In uz, this message translates to:
  /// **'NotiqAI ning yangi versiyasi chiqdi. Davom etish uchun ilovani yangilang.'**
  String get updateRequiredMessage;

  /// No description provided for @updateNow.
  ///
  /// In uz, this message translates to:
  /// **'Yangilash'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In uz, this message translates to:
  /// **'Keyinroq'**
  String get updateLater;

  /// No description provided for @permissionGateTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ruxsatlar kerak'**
  String get permissionGateTitle;

  /// No description provided for @permissionGateMessage.
  ///
  /// In uz, this message translates to:
  /// **'Ilova to\'liq ishlashi uchun quyidagi ruxsatlarni bering:'**
  String get permissionGateMessage;

  /// No description provided for @permissionMicrophone.
  ///
  /// In uz, this message translates to:
  /// **'Mikrofon'**
  String get permissionMicrophone;

  /// No description provided for @permissionLocation.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv'**
  String get permissionLocation;

  /// No description provided for @permissionNotification.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get permissionNotification;

  /// No description provided for @permissionGrant.
  ///
  /// In uz, this message translates to:
  /// **'Ruxsat berish'**
  String get permissionGrant;

  /// No description provided for @permissionOpenSettings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalarga o\'tish'**
  String get permissionOpenSettings;

  /// No description provided for @permissionLater.
  ///
  /// In uz, this message translates to:
  /// **'Keyinroq'**
  String get permissionLater;

  /// No description provided for @gradeTitleExcellent.
  ///
  /// In uz, this message translates to:
  /// **'A\'lo darajadagi natija!'**
  String get gradeTitleExcellent;

  /// No description provided for @gradeTitleGood.
  ///
  /// In uz, this message translates to:
  /// **'Yaxshi natija!'**
  String get gradeTitleGood;

  /// No description provided for @gradeTitleAverage.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha natija'**
  String get gradeTitleAverage;

  /// No description provided for @gradeTitleWeak.
  ///
  /// In uz, this message translates to:
  /// **'Kuchsiz natija'**
  String get gradeTitleWeak;

  /// No description provided for @analysisMetrics.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rsatkichlar'**
  String get analysisMetrics;

  /// No description provided for @metricVoiceConfidence.
  ///
  /// In uz, this message translates to:
  /// **'Ovoz ishonchliligi'**
  String get metricVoiceConfidence;

  /// No description provided for @metricPauseBalance.
  ///
  /// In uz, this message translates to:
  /// **'Pauzalar balansi'**
  String get metricPauseBalance;

  /// No description provided for @metricFillerWords.
  ///
  /// In uz, this message translates to:
  /// **'Parazit so\'zlar'**
  String get metricFillerWords;

  /// No description provided for @metricThoughtFlow.
  ///
  /// In uz, this message translates to:
  /// **'Fikr izchilligi'**
  String get metricThoughtFlow;

  /// No description provided for @metricPronunciationAccuracy.
  ///
  /// In uz, this message translates to:
  /// **'Talaffuz aniqligi'**
  String get metricPronunciationAccuracy;

  /// No description provided for @metricWordAccuracy.
  ///
  /// In uz, this message translates to:
  /// **'So\'z to\'g\'riligi'**
  String get metricWordAccuracy;

  /// No description provided for @metricAvgWordScore.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha ball'**
  String get metricAvgWordScore;

  /// No description provided for @metricPhonemeErrors.
  ///
  /// In uz, this message translates to:
  /// **'Fonema aniqligi'**
  String get metricPhonemeErrors;

  /// No description provided for @gradePronunciationPerfect.
  ///
  /// In uz, this message translates to:
  /// **'Barcha so\'zlar to\'g\'ri talaffuz qilindi!'**
  String get gradePronunciationPerfect;

  /// No description provided for @gradePronunciationMinor.
  ///
  /// In uz, this message translates to:
  /// **'Bir nechta kichik xatolik aniqlandi.'**
  String get gradePronunciationMinor;

  /// No description provided for @gradePronunciationNeedsWork.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta so\'zda xatolik topildi.'**
  String gradePronunciationNeedsWork(int count);

  /// No description provided for @perfectPronunciation.
  ///
  /// In uz, this message translates to:
  /// **'A\'lo! Barcha so\'zlar to\'g\'ri aytildi.'**
  String get perfectPronunciation;

  /// No description provided for @charLevelAnalysis.
  ///
  /// In uz, this message translates to:
  /// **'Harf darajasidagi tahlil'**
  String get charLevelAnalysis;

  /// No description provided for @psychologyScoreLabel.
  ///
  /// In uz, this message translates to:
  /// **'Psixologik ball'**
  String get psychologyScoreLabel;

  /// No description provided for @quizGradeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Test natijasi'**
  String get quizGradeTitle;

  /// No description provided for @quizGoodSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ajoyib! Natijangiz yaxshi.'**
  String get quizGoodSubtitle;

  /// No description provided for @quizBadSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinib ko\'ring, siz qila olasiz!'**
  String get quizBadSubtitle;

  /// No description provided for @quizMetricScore.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy ball'**
  String get quizMetricScore;

  /// No description provided for @quizMetricCorrect.
  ///
  /// In uz, this message translates to:
  /// **'To\'g\'ri javoblar'**
  String get quizMetricCorrect;

  /// No description provided for @tryAgain.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get tryAgain;

  /// No description provided for @levelBeginner.
  ///
  /// In uz, this message translates to:
  /// **'Boshlang\'ich'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In uz, this message translates to:
  /// **'O\'rta'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In uz, this message translates to:
  /// **'Yuqori'**
  String get levelAdvanced;

  /// No description provided for @filterAll.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get filterAll;

  /// No description provided for @searchCoursesHint.
  ///
  /// In uz, this message translates to:
  /// **'Kurs qidirish…'**
  String get searchCoursesHint;

  /// No description provided for @coursesCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta kurs'**
  String coursesCount(int count);

  /// No description provided for @priceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Narx'**
  String get priceLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
