// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'NotiqAI';

  @override
  String get welcome => 'Добро пожаловать';

  @override
  String get welcomeSubtitle => 'Войдите по номеру телефона, чтобы продолжить';

  @override
  String get termsNotice =>
      'Продолжая, вы соглашаетесь с условиями использования';

  @override
  String appVersion(String version) {
    return 'NotiqAI · v$version';
  }

  @override
  String get sessionExpired => 'Сессия истекла. Войдите снова.';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get registerAndLogin => 'Регистрация и вход';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get verificationCode => 'Код подтверждения';

  @override
  String get stepPhone => 'Телефон';

  @override
  String get stepVerification => 'Подтверждение';

  @override
  String get stepInfo => 'Данные';

  @override
  String get stepNewPassword => 'Новый пароль';

  @override
  String get enterPhoneTitle => 'Введите номер телефона';

  @override
  String get enterPhoneSubtitle =>
      'На ваш номер будет отправлен код подтверждения';

  @override
  String get enterPhoneForLogin => 'Введите номер телефона для входа';

  @override
  String get enterPhoneForRegister => 'Введите номер телефона для регистрации';

  @override
  String get enterPhoneForReset =>
      'Введите номер телефона для восстановления пароля';

  @override
  String get invalidPhone => 'Введите корректный номер телефона';

  @override
  String get passwordTooShort => 'Пароль должен содержать не менее 6 символов';

  @override
  String get codeTooShort => 'Введите код полностью';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get confirmPasswordRequired => 'Подтвердите пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get createNewPassword => 'Создайте новый пароль';

  @override
  String get createNewPasswordSubtitle =>
      'Установите новый пароль для своей учётной записи';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get saveAndLogin => 'Сохранить и войти';

  @override
  String get phoneAlreadyRegistered =>
      'Этот номер телефона уже зарегистрирован. Пожалуйста, войдите.';

  @override
  String get phoneNotRegistered => 'Этот номер телефона не зарегистрирован.';

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String get welcomeBack => 'С возвращением!';

  @override
  String get loginSubtitle => 'Введите номер телефона и пароль';

  @override
  String get noAccountRegister => 'Нет аккаунта? Зарегистрируйтесь';

  @override
  String enterPasswordFor(String phone) {
    return 'Введите пароль для номера $phone';
  }

  @override
  String enterCodeFor(String phone) {
    return 'Введите код, отправленный на $phone';
  }

  @override
  String get fillInfoTitle => 'Заполните данные';

  @override
  String get fillInfoSubtitle => 'Введите данные для регистрации';

  @override
  String get enterFirstName => 'Введите имя';

  @override
  String get enterLastName => 'Введите фамилию';

  @override
  String get offerAcceptTitle => 'Принимаю условия оферты';

  @override
  String get offerAcceptSubtitle =>
      'Соглашаюсь на обработку персональных данных и правила использования приложения.';

  @override
  String get offerRequired => 'Пожалуйста, примите условия оферты.';

  @override
  String get loginRequiredMessage => 'Сначала войдите в систему.';

  @override
  String get fullNameRequired => 'Имя и фамилия обязательны';

  @override
  String get fullNameTooShort => 'Слишком короткое имя';

  @override
  String get invalidEmail => 'Неверный формат email';

  @override
  String get saving => 'Сохранение...';

  @override
  String get save => 'Сохранить';

  @override
  String get loginRequiredTitle => 'Войдите, чтобы увидеть результат';

  @override
  String get loginRequiredSubtitle =>
      'Результаты анализов, история и персональные рекомендации доступны только зарегистрированным пользователям.';

  @override
  String meaningFluency(int meaning, int fluency) {
    return 'Смысл $meaning · Беглость $fluency';
  }

  @override
  String get historySpeech => 'Анализ речи';

  @override
  String get historyObservation => 'Тест на наблюдательность';

  @override
  String get noCertificates =>
      'Сертификатов пока нет. Пройдите курсы полностью — сертификат будет выдан автоматически.';

  @override
  String get date => 'Дата';

  @override
  String get grade => 'Оценка';

  @override
  String get serial => 'Серия';

  @override
  String get noHistory =>
      'Анализов пока нет. Попробуйте модуль речи или наблюдательности.';

  @override
  String get contactBannerTitle => 'Najot Nur';

  @override
  String get contactBannerSubtitle =>
      'Центр ораторского мастерства — всегда готов помочь вам.';

  @override
  String get quickContact => 'Быстрая связь';

  @override
  String get contactTelegram => 'Телеграм';

  @override
  String get contactPhone => 'Телефон';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactAddress => 'Адрес';

  @override
  String get telegramHandle => '@najotnur_support';

  @override
  String get supportPhone => '+998 71 200 00 00';

  @override
  String get supportEmail => 'support@najotnur.uz';

  @override
  String get supportAddress => 'г. Ташкент, ул. Мустакиллик, 10';

  @override
  String get faqTitle => 'Часто задаваемые вопросы';

  @override
  String get faq1Q => 'Как работает анализ речи?';

  @override
  String get faq1A =>
      'Вы записываете 2-минутную речь. ИИ анализирует содержание, беглость и слова-паразиты, после чего выдаёт подробный результат.';

  @override
  String get faq2Q => 'Как получить сертификат?';

  @override
  String get faq2A =>
      'Пройдите все уроки курса и сдайте тесты. Когда курс пройден на 100%, сертификат выпускается автоматически.';

  @override
  String get faq3Q => 'Где хранятся мои результаты?';

  @override
  String get faq3A =>
      'Все анализы и результаты хранятся в вашем профиле. Вы можете посмотреть их в разделе «История анализов».';

  @override
  String get faq4Q => 'Я забыл пароль, что делать?';

  @override
  String get faq4A =>
      'На экране входа нажмите кнопку «Забыли пароль». На ваш номер телефона будет отправлен код восстановления.';

  @override
  String get noNotifications => 'Уведомлений пока нет.';

  @override
  String get audiencePersonal => 'Личное';

  @override
  String get audienceCourse => 'Курс';

  @override
  String get audienceAll => 'Для всех';

  @override
  String get onboarding1Title => 'Развивайте речь с NotiqAI';

  @override
  String get onboarding1Body =>
      'Анализируйте свои ораторские навыки с помощью ИИ, находите ошибки и достигайте мастерства.';

  @override
  String get onboarding2Title => 'Голос и дикция';

  @override
  String get onboarding2Body =>
      'Читайте текст, а ИИ проанализирует ваш голос. Ошибки в звуках выделяются красным.';

  @override
  String get onboarding3Title => 'Наблюдательность и речь';

  @override
  String get onboarding3Body =>
      '10 тестов, видеоуроки и аудиокниги — всё для вашего успеха.';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabCourses => 'Уроки';

  @override
  String get tabBooks => 'Книги';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get logoutConfirmTitle => 'Выйти из системы?';

  @override
  String get logoutConfirmMessage => 'После выхода потребуется войти снова.';

  @override
  String get logoutConfirmYes => 'Да, выйти';

  @override
  String get logoutConfirmNo => 'Отмена';

  @override
  String get exitConfirmMessage => 'Выйти из приложения? Нажмите ещё раз.';

  @override
  String get noAudiobooks => 'Аудиокниг пока нет.';

  @override
  String get noCourses => 'Курсов пока нет.';

  @override
  String get buyConfirmTitle => 'Купить?';

  @override
  String lessonNumber(int n) {
    return 'Урок $n';
  }

  @override
  String get fillersTitle => 'Слова-паразиты';

  @override
  String get scoreMeaning => 'Смысл';

  @override
  String get scoreFluency => 'Беглость';

  @override
  String get scoreOverall => 'Общий балл';

  @override
  String get errorWord => 'Ошибка';

  @override
  String get voiceRecorded => 'Записано ✓';

  @override
  String get reselectText => 'Выбрать текст заново';

  @override
  String get next => 'Далее';

  @override
  String get prev => 'Назад';

  @override
  String questionCounter(int current, int total) {
    return '$current / $total';
  }

  @override
  String get submit => 'Отправить';

  @override
  String get testComplete => 'Тест завершён';

  @override
  String get weakAreas => 'Сильные и слабые стороны';

  @override
  String get selectAnOption => 'Выберите вариант';

  @override
  String get lessonList => 'Уроки';

  @override
  String get welcomeBody =>
      'Официальное приложение центра ораторского мастерства Najot Nur. Развивайте речь, голос и наблюдательность с помощью ИИ.';

  @override
  String get homeGreeting => 'Что попробуем сегодня?';

  @override
  String get homeSubtitle => 'Вы можете попробовать без регистрации.';

  @override
  String get homeActionSpeech => 'Проверить речь';

  @override
  String get homeActionSpeechSub => 'ИИ проанализирует вашу речь и голос';

  @override
  String get homeActionObservation => 'Проверить наблюдательность';

  @override
  String get homeActionObservationSub => '10 тестов: психология и язык тела';

  @override
  String get homeFeatures => 'Возможности';

  @override
  String get free => 'Бесплатно';

  @override
  String get forSale => 'Продаётся';

  @override
  String lessonsShort(int count) {
    return '$count ур.';
  }

  @override
  String andMore(int n) {
    return 'Ещё $n ур.';
  }

  @override
  String sumPrice(String price) {
    return '$price сум';
  }

  @override
  String get user => 'Пользователь';

  @override
  String get guest => 'Гость';

  @override
  String get notRegistered => 'Не зарегистрирован';

  @override
  String get historySubtitle => 'Результаты речи и наблюдательности';

  @override
  String get certificatesSubtitle => 'По пройденным курсам';

  @override
  String get notificationsSubtitle => 'Новые сообщения и объявления';

  @override
  String get helpSubtitle => 'Телеграм, телефон, FAQ';

  @override
  String get speechHubPrompt => 'Какое направление попробуем?';

  @override
  String get speechHubSub =>
      'Голос — оценит произношение, Речь — ясность мысли.';

  @override
  String get voiceCheckDesc =>
      'Прочитайте предложенный текст — ИИ выделит ошибки в звуках и словах красным и оценит произношение.';

  @override
  String get speechAnalysisDesc =>
      'Расскажите о себе 2 минуты. ИИ проанализирует слова-паразиты, паузы и ясность мысли.';

  @override
  String get noReferences => 'Тексты не найдены.';

  @override
  String get taskLabel => 'Задание';

  @override
  String get selfIntroPrompt => 'Расскажите о себе ~2 минуты';

  @override
  String get balanceTooLittle => 'Мало информации — добавьте подробностей';

  @override
  String get balanceTooMuch => 'Слишком много информации — сократите';

  @override
  String get balanceGood => 'Объём информации сбалансирован';

  @override
  String get strengthsTitle => 'Сильные стороны';

  @override
  String get improvementsTitle => 'Что улучшить';

  @override
  String get summaryTitle => 'Общий вывод';

  @override
  String get scoreOverallLabel => 'общий балл';

  @override
  String get textWithErrors => 'Текст — ошибки выделены красным';

  @override
  String get overallAnalysis => 'Общий анализ';

  @override
  String get soundErrors => 'Ошибки в звуках';

  @override
  String accuracyLabel(int score) {
    return 'Точность: $score%';
  }

  @override
  String get noTests => 'Тесты не найдены.';

  @override
  String get finishAndAnalyze => 'Завершить и проанализировать';

  @override
  String answeredCount(int count) {
    return 'Отвечено: $count';
  }

  @override
  String get mediaPlaceholder => 'Изображение/видео скоро появится';

  @override
  String get catPsychology => 'Психология';

  @override
  String get catBodyLanguage => 'Язык тела';

  @override
  String get catObservation => 'Наблюдательность';

  @override
  String testNumber(int n) {
    return 'Тест $n';
  }

  @override
  String get noPage => 'Страница недоступна.';

  @override
  String get paymentComingSoon => 'Платёжная интеграция (Uzum/ATMOS) скоро!';

  @override
  String get paidAudiobook => 'Платная аудиокнига';

  @override
  String get buyAudiobookPrompt => 'Купите эту аудиокнигу, чтобы прочитать её';

  @override
  String get noAudioFile => 'Аудиофайл недоступен.';

  @override
  String audioLoadError(String error) {
    return 'Не удалось загрузить аудио: $error';
  }

  @override
  String pageOfTotal(int current, int total) {
    return '$current / $total стр.';
  }

  @override
  String get loadingAudio => 'Загрузка…';

  @override
  String get paymentLater =>
      'Платёжная интеграция (Uzum/ATMOS) на следующем этапе';

  @override
  String get startCourse => 'Начать курс';

  @override
  String get aiExercise => 'AI упражнение';

  @override
  String get speedLabel => 'Скорость';

  @override
  String get qualityLabel => 'Качество видео';

  @override
  String qualityChanged(String q) {
    return 'Качество видео изменено на $q';
  }

  @override
  String get start => 'Начать';

  @override
  String get logout => 'Выход';

  @override
  String get retry => 'Повторить';

  @override
  String get phoneLogin => 'Войти по номеру телефона';

  @override
  String get orUse => 'или';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get phoneHint => '+998 XX XXX XX XX';

  @override
  String get password => 'Пароль';

  @override
  String get passwordHint => '••••••';

  @override
  String get createPassword => 'Создайте пароль';

  @override
  String get firstName => 'Имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get fullName => 'Имя и фамилия';

  @override
  String get emailOptional => 'Email (необязательно)';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выбрать язык';

  @override
  String get languagePrompt => 'На каком языке вы хотите продолжить?';

  @override
  String get uzbekLang => 'Узбекский';

  @override
  String get russianLang => 'Русский';

  @override
  String get englishLang => 'Английский';

  @override
  String get edit => 'Редактировать';

  @override
  String get profile => 'Профиль';

  @override
  String get registerLogin => 'Регистрация / Вход';

  @override
  String get openFromMenu => 'Откройте из меню ниже';

  @override
  String get audiobooks => 'Аудиокниги';

  @override
  String get videoLessons => 'Видеоуроки';

  @override
  String get buy => 'Купить';

  @override
  String lessonsCount(int count) {
    return 'Уроки ($count)';
  }

  @override
  String minutesShort(int mins) {
    return '$mins мин';
  }

  @override
  String pageNotFound(String uri) {
    return 'Страница не найдена: $uri';
  }

  @override
  String errorPrefix(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get profileUpdated => 'Профиль обновлён.';

  @override
  String get profileEdit => 'Редактировать профиль';

  @override
  String get certificates => 'Мои сертификаты';

  @override
  String pdfUrl(String url) {
    return 'PDF: $url';
  }

  @override
  String get pdfDownload => 'Скачать PDF';

  @override
  String get certRequestNew => 'Запросить сертификат';

  @override
  String get certRequestSend => 'Отправить запрос';

  @override
  String get certRequestSent => 'Ваш запрос на сертификат отправлен куратору.';

  @override
  String get certRequestPending => 'На рассмотрении';

  @override
  String get certRequestRejected => 'Отклонён';

  @override
  String get certFullName => 'Имя на сертификате';

  @override
  String get certFullNameHint => 'Например: Алиев Али';

  @override
  String get certSelectCourse => 'Выберите курс';

  @override
  String get certSelectCourseRequired => 'Пожалуйста, выберите курс';

  @override
  String get certRejectionReason => 'Причина';

  @override
  String get analysisHistory => 'История анализов';

  @override
  String get helpContact => 'Помощь и контакты';

  @override
  String get notifications => 'Уведомления';

  @override
  String get voiceCheck => 'Проверка голоса';

  @override
  String get voiceAnalysis => 'Анализ голоса';

  @override
  String get speechCheck => 'Проверка речи';

  @override
  String get speechAnalysis => 'Анализ речи';

  @override
  String get speechText => 'Текст вашей речи (можно редактировать)';

  @override
  String get speechHint => 'Здравствуйте, меня зовут...';

  @override
  String get noFillers => 'Слов-паразитов не обнаружено. Отлично!';

  @override
  String fillerCount(String key, int value) {
    return '$key × $value';
  }

  @override
  String get selectText => 'Выберите текст';

  @override
  String get readText => 'Прочитайте текст ниже';

  @override
  String get recognizedText => 'Распознанный текст (можно редактировать)';

  @override
  String get readWordsHint => 'Ваши слова...';

  @override
  String get analyze => 'Анализировать';

  @override
  String get analyzing => 'Анализируется...';

  @override
  String get recordingReady => 'Запись готова. Можно анализировать.';

  @override
  String get backToHome => 'На главную';

  @override
  String wordAndSound(String word, String sound) {
    return '$word  ·  «$sound»';
  }

  @override
  String get observationTest => 'Тест на наблюдательность';

  @override
  String get observationAnalysis => 'Анализ наблюдательности';

  @override
  String get back => 'Назад';

  @override
  String get cannotOpenVideo => 'Не удалось открыть видео.';

  @override
  String get byDirections => 'По направлениям';

  @override
  String get changeLanguageSubtitle => 'Узбекский · Русский · English';

  @override
  String get supportChatTitle => 'Напишите нам';

  @override
  String get supportChatSubtitle => 'Задайте вопрос — ответим как можно скорее';

  @override
  String get chatInputHint => 'Напишите сообщение...';

  @override
  String get chatSend => 'Отправить';

  @override
  String get chatLoginRequired => 'Войдите, чтобы воспользоваться чатом';

  @override
  String get chatNoMessages =>
      'Сообщений пока нет. Задайте свой первый вопрос!';

  @override
  String get chatSupport => 'Поддержка';

  @override
  String get chatSending => 'Отправка...';

  @override
  String get orderSheetCourseTitle => 'Запрос доступа к курсу';

  @override
  String get orderSheetAudiobookTitle => 'Купить аудиокнигу';

  @override
  String get amountLabel => 'Сумма';

  @override
  String get paymentMethod => 'Способ оплаты';

  @override
  String get paymentProofHint =>
      'Ссылка на подтверждение оплаты (необязательно)';

  @override
  String get orderSubmit => 'Отправить заявку';

  @override
  String get orderSubmitted => 'Ваша заявка принята!';

  @override
  String get orderSheetFooter =>
      'После подтверждения оплаты доступ будет открыт автоматически.';

  @override
  String get methodUzum => 'Uzum';

  @override
  String get methodUzumNasiya => 'Uzum Nasiya';

  @override
  String get methodCash => 'Наличные';

  @override
  String get uzumRedirectHint =>
      'Для оплаты вы будете перенаправлены на сайт Uzum.';

  @override
  String get uzumNasiyaRedirectHint =>
      'Для оплаты в рассрочку вы будете перенаправлены на сайт Uzum Nasiya.';

  @override
  String get audiobookOrderPending =>
      'Ваш заказ рассматривается. Пожалуйста, подождите.';

  @override
  String get orderPending => 'Заказ в обработке';

  @override
  String get myOrders => 'Мои заказы';

  @override
  String get myOrdersSubtitle => 'Покупки курсов и аудиокниг';

  @override
  String get noOrders => 'Заказов пока нет.';

  @override
  String get orderStatusPending => 'В обработке';

  @override
  String get orderStatusApproved => 'Подтверждён';

  @override
  String get orderStatusRejected => 'Отклонён';

  @override
  String get orderTypeCourse => 'Курс';

  @override
  String get orderTypeAudiobook => 'Аудиокнига';

  @override
  String get chatActionSubtitle => 'Задайте нам вопрос';

  @override
  String get faqActionSubtitle => 'Часто задаваемые вопросы';

  @override
  String get loginRequired => 'Для этого раздела необходимо войти в систему';

  @override
  String get loginRequiredBtn => 'Войти';

  @override
  String get practiceSpeech => 'Практика речи';

  @override
  String get practiceSpeechSub =>
      'ИИ генерирует текст — читайте и получите анализ';

  @override
  String get psychologyTest => 'Психологический тест';

  @override
  String get psychologyTestSub => 'Ответьте на вопросы и получите анализ ИИ';

  @override
  String get psychologyAnalysis => 'Психологический анализ';

  @override
  String get psychologyIntro =>
      'Ответьте на вопросы ниже — ИИ проанализирует ваш психологический профиль';

  @override
  String get psychologyAiTitle => 'Войдите для ИИ-анализа';

  @override
  String get psychologyAiSubtitle =>
      'Подробный психологический анализ, сильные стороны и рекомендации доступны только зарегистрированным пользователям.';

  @override
  String get selectDifficulty => 'Выберите уровень сложности';

  @override
  String get difficultyEasy => 'Лёгкий';

  @override
  String get difficultyMedium => 'Средний';

  @override
  String get difficultyHard => 'Сложный';

  @override
  String get generateText => 'Сгенерировать текст';

  @override
  String get generatingText => 'Генерация текста...';

  @override
  String get practiceReadText => 'Прочитайте текст вслух';

  @override
  String get tabPracticums => 'Практикум';

  @override
  String get practicumsTitle => 'Практикумы';

  @override
  String get practicumsSubtitle => 'Практические упражнения с голосом эксперта';

  @override
  String get noPracticums => 'Практикумов пока нет.';

  @override
  String get tabTests => 'Тесты';

  @override
  String get testsTitle => 'Тесты';

  @override
  String get testsSubtitle => 'Все доступные тесты';

  @override
  String get quizEasy => 'Лёгкий';

  @override
  String get quizMedium => 'Средний';

  @override
  String get quizHard => 'Сложный';

  @override
  String quizQuestions(Object count) {
    return '$count вопросов';
  }

  @override
  String get quizStart => 'Начать тест';

  @override
  String get quizResult => 'Результат теста';

  @override
  String quizScore(Object correct, Object total) {
    return '$correct/$total правильно';
  }

  @override
  String get quizCorrect => 'Верно';

  @override
  String get quizWrong => 'Неверно';

  @override
  String get quizFinish => 'Завершить';

  @override
  String get quizNext => 'Следующий';

  @override
  String get noQuizzes => 'Тесты пока отсутствуют.';

  @override
  String get quizDraft => 'На проверке';

  @override
  String get uploadAudio => 'Загрузить аудио файл';

  @override
  String get fileSelected => 'Файл выбран. Готово к анализу.';

  @override
  String get orDivider => 'или';

  @override
  String get listenExpert => 'Послушайте эксперта';

  @override
  String get playAudio => 'Слушать';

  @override
  String get stopAudio => 'Стоп';

  @override
  String get continueCourse => 'Продолжить';

  @override
  String get courseInProgress => 'В процессе';

  @override
  String get courseCompleted => 'Курс завершён';

  @override
  String lessonsCompleted(int completed, int total) {
    return '$completed/$total уроков выполнено';
  }

  @override
  String get lesson => 'Урок';

  @override
  String get lessonTabVideo => 'Видео';

  @override
  String get lessonTabQuiz => 'Тест';

  @override
  String get lessonTabHomework => 'Задание';

  @override
  String get tapToWatch => 'Нажмите для просмотра';

  @override
  String get noVideoForLesson => 'Для этого урока видео нет';

  @override
  String get noQuizForLesson => 'Для этого урока теста нет';

  @override
  String get lessonDescription => 'ОПИСАНИЕ УРОКА';

  @override
  String get markAsComplete => 'Отметить как выполненное';

  @override
  String get completed => 'Выполнено';

  @override
  String get lessonCompleted => 'Урок завершён!';

  @override
  String lessonCompletedWithScore(int score) {
    return 'Урок завершён! Балл: $score%';
  }

  @override
  String get videoOpenError => 'Не удалось открыть видео';

  @override
  String get quizLessonTitle => 'Тест по уроку';

  @override
  String quizLessonSubtitle(int count) {
    return '$count вопросов';
  }

  @override
  String get quizAnswerAll => 'Ответьте на все вопросы';

  @override
  String get submitQuiz => 'Отправить тест';

  @override
  String get quizPassed => 'Тест пройден успешно!';

  @override
  String get quizFailed => 'Тест не пройден';

  @override
  String quizCorrectCount(int correct, int total) {
    return '$correct/$total правильно';
  }

  @override
  String get homeworkTitle => 'Домашнее задание';

  @override
  String get homeworkSubtitle =>
      'Выполните домашнее задание и отправьте куратору. После проверки вы увидите результат.';

  @override
  String get homeworkHint => 'Напишите ваш ответ здесь...';

  @override
  String get homeworkEmpty => 'Пожалуйста, напишите ваш ответ';

  @override
  String get homeworkSend => 'Отправить';

  @override
  String get homeworkSubmitted => 'Домашнее задание успешно отправлено!';

  @override
  String get homeworkPending => 'Куратор проверяет...';

  @override
  String get homeworkReviewed => 'Проверено';

  @override
  String get homeworkResubmit => 'Отправить повторно';

  @override
  String get yourAnswer => 'ВАШ ОТВЕТ';

  @override
  String get curatorFeedback => 'КОММЕНТАРИЙ КУРАТОРА';

  @override
  String get sending => 'Отправляется...';

  @override
  String get cancel => 'Отмена';

  @override
  String get securityCaptureDetected => 'Обнаружена запись экрана';

  @override
  String get securityCaptureSubtitle =>
      'Ваш экран записывается. Конфиденциальный контент скрыт. Остановите запись, чтобы продолжить.';

  @override
  String get updateRequiredTitle => 'Требуется обновление';

  @override
  String get updateRequiredMessage =>
      'Доступна новая версия NotiqAI. Пожалуйста, обновите приложение, чтобы продолжить.';

  @override
  String get updateNow => 'Обновить';

  @override
  String get updateLater => 'Позже';

  @override
  String get permissionGateTitle => 'Нужны разрешения';

  @override
  String get permissionGateMessage =>
      'Предоставьте разрешения ниже, чтобы приложение работало полноценно:';

  @override
  String get permissionMicrophone => 'Микрофон';

  @override
  String get permissionLocation => 'Местоположение';

  @override
  String get permissionNotification => 'Уведомления';

  @override
  String get permissionGrant => 'Предоставить доступ';

  @override
  String get permissionOpenSettings => 'Открыть настройки';

  @override
  String get permissionLater => 'Позже';

  @override
  String get gradeTitleExcellent => 'Отличный результат!';

  @override
  String get gradeTitleGood => 'Хороший результат!';

  @override
  String get gradeTitleAverage => 'Средний результат';

  @override
  String get gradeTitleWeak => 'Требует улучшения';

  @override
  String get analysisMetrics => 'Показатели';

  @override
  String get metricVoiceConfidence => 'Уверенность голоса';

  @override
  String get metricPauseBalance => 'Баланс пауз';

  @override
  String get metricFillerWords => 'Слова-паразиты';

  @override
  String get metricThoughtFlow => 'Связность мыслей';

  @override
  String get metricPronunciationAccuracy => 'Точность произношения';

  @override
  String get metricWordAccuracy => 'Точность слов';

  @override
  String get metricAvgWordScore => 'Средний балл';

  @override
  String get metricPhonemeErrors => 'Точность фонем';

  @override
  String get gradePronunciationPerfect => 'Все слова произнесены правильно!';

  @override
  String get gradePronunciationMinor => 'Обнаружено несколько мелких ошибок.';

  @override
  String gradePronunciationNeedsWork(int count) {
    return 'В $count словах найдены ошибки.';
  }

  @override
  String get perfectPronunciation =>
      'Отлично! Все слова произнесены правильно.';

  @override
  String get charLevelAnalysis => 'Анализ по буквам';

  @override
  String get psychologyScoreLabel => 'Психологический балл';

  @override
  String get quizGradeTitle => 'Результат теста';

  @override
  String get quizGoodSubtitle => 'Отлично! Вы справились.';

  @override
  String get quizBadSubtitle => 'Продолжайте стараться!';

  @override
  String get quizMetricScore => 'Общий балл';

  @override
  String get quizMetricCorrect => 'Правильные ответы';

  @override
  String get tryAgain => 'Попробовать снова';
}
