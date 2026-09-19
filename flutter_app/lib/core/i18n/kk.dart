import 'app_strings.dart';

/// Kazakh — the default and primary locale of the app (see
/// KAZAKH_LOCALIZATION.md). Every string here uses correct Kazakh
/// Cyrillic letters (Ә, Ғ, Қ, Ң, Ө, Ұ, Ү, Һ, І) — never a Russian
/// substitute.
class KkStrings implements AppStrings {
  @override
  String get settingsTheme => 'Ашық / қараңғы көрініс';
  const KkStrings();

  @override
  String get commonSave => 'Сақтау';
  @override
  String get commonCancel => 'Болдырмау';
  @override
  String get commonDelete => 'Жою';
  @override
  String get commonEdit => 'Өңдеу';
  @override
  String get commonSearch => 'Іздеу';
  @override
  String get commonAdd => 'Қосу';
  @override
  String get commonClose => 'Жабу';
  @override
  String get commonConfirm => 'Растау';
  @override
  String get commonBack => 'Артқа';
  @override
  String get commonRetry => 'Қайталау';
  @override
  String get commonLoading => 'Жүктелуде...';
  @override
  String get commonError => 'Қате орын алды';
  @override
  String get commonEmpty => 'Деректер жоқ';
  @override
  String get commonYes => 'Иә';
  @override
  String get commonNo => 'Жоқ';
  @override
  String get commonSeeAll => 'Барлығын көру';
  @override
  String get commonCannotOpenLink => 'Бұл әрекетті орындау мүмкін болмады';

  @override
  String get navDashboard => 'Басты бет';
  @override
  String get navOrders => 'Тапсырыстар';
  @override
  String get navTasks => 'Тапсырмалар';
  @override
  String get navProfile => 'Профиль';
  @override
  String get navClients => 'Клиенттер';
  @override
  String get navPayments => 'Төлемдер';
  @override
  String get navEmployees => 'Қызметкерлер';
  @override
  String get navPartners => 'Серіктестер';
  @override
  String get navAnalytics => 'Аналитика';
  @override
  String get navProduction => 'Өндіріс';
  @override
  String get navWarehouse => 'Қойма';
  @override
  String get navPurchases => 'Сатып алу';
  @override
  String get navSettings => 'Баптаулар';

  @override
  String get quickAddNewClient => 'Жаңа клиент';
  @override
  String get quickAddNewOrder => 'Жаңа тапсырыс';
  @override
  String get quickAddNewMeasurement => 'Өлшем қосу';
  @override
  String get quickAddNewPayment => 'Төлем қосу';
  @override
  String get quickAddNewExpense => 'Шығын қосу';
  @override
  String get quickAddPhotoReport => 'Фотоесеп қосу';

  @override
  String get authWelcomeTitle => 'JUMA UI-ге қош келдіңіз';
  @override
  String get authWelcomeSubtitle => 'Жиһаз өндірісін басқару жүйесі';
  @override
  String get authPassword => 'Құпиясөз';
  @override
  String get authConfirmPassword => 'Құпиясөзді растау';
  @override
  String get authFullName => 'Аты-жөні';
  @override
  String get authPhone => 'Телефон';
  @override
  String get authLoginButton => 'Кіру';
  @override
  String get authDevelopmentLogin => 'Әзірлеуші ретінде кіру';
  @override
  String get authDevelopmentLoginError =>
      'Әзірлеу серверіне қосылу мүмкін болмады. Жергілікті әзірлеу режимін қайта іске қосыңыз';
  @override
  String get authForgotPassword => 'Құпиясөзді ұмыттыңыз ба?';
  @override
  String get authRememberDevice => 'Бұл құрылғыны есте сақтау';
  @override
  String get authLogout => 'Шығу';
  @override
  String get authLogoutAllDevices => 'Барлық құрылғыдан шығу';
  @override
  String get authInvalidCredentials => 'Логин немесе құпиясөз қате';
  @override
  String get authFieldRequired => 'Бұл өрісті толтыру міндетті';
  @override
  String get authPasswordTooShort => 'Құпиясөз кемінде 8 таңбадан тұруы керек';
  @override
  String get authPasswordsDoNotMatch => 'Құпиясөздер сәйкес келмейді';
  @override
  String get authAccountDeactivated =>
      'Тіркелгіңіз өшірілген. Директорға хабарласыңыз';
  @override
  String get authSessionExpired => 'Сессия аяқталды, қайта кіріңіз';
  @override
  String get authResetPasswordTitle => 'Құпиясөзді қалпына келтіру';
  @override
  String get authResetPasswordSent => 'Қалпына келтіру сілтемесі жіберілді';
  @override
  String get authCheckYourEmail => 'Email-іңізді тексеріңіз';
  @override
  String get authEmail => 'Email';
  @override
  String get authSignUpTitle => 'Тіркелу';
  @override
  String get authSignUpSubtitle => 'Жаңа тіркелгі жасаңыз';
  @override
  String get authSignUpButton => 'Тіркелу';
  @override
  String get authNoAccountLink => 'Тіркелгіңіз жоқ па? Тіркелу';
  @override
  String get authHaveAccountLink => 'Тіркелгіңіз бар ма? Кіру';
  @override
  String get authInvalidEmail => 'Email мекенжайы қате';
  @override
  String get authInvalidPhone => 'Телефон нөмірі қате. Мысалы: +77001234567';
  @override
  String get authEmailConfirmTitle => 'Email-ді растаңыз';
  @override
  String get authEmailConfirmSubtitle =>
      'Растау сілтемесін мына email-ге жібердік:';
  @override
  String get authEmailConfirmInstructions =>
      'Хатты ашып, ондағы сілтемені басыңыз, содан кейін төмендегі батырманы басыңыз.';
  @override
  String get authResendEmail => 'Хатты қайта жіберу';
  @override
  String get authEmailResent => 'Хат қайта жіберілді';
  @override
  String get authContinueButton => 'Растадым, жалғастыру';
  @override
  String get authEnterPasswordToContinue =>
      'Жалғастыру үшін құпиясөзді қайта енгізіңіз';
  @override
  String get authPhoneVerifyTitle => 'Телефонды растаңыз';
  @override
  String get authPhoneVerifySubtitle => 'Растау кодын мына нөмірге жібердік:';
  @override
  String get authOtpLabel => 'SMS коды';
  @override
  String get authOtpVerifyButton => 'Растау';
  @override
  String get authResendCode => 'Кодты қайта жіберу';
  @override
  String get authCodeResent => 'Код қайта жіберілді';
  @override
  String get authChangePhone => 'Нөмірді өзгерту';

  @override
  String get dashboardGreetingPrefix => 'Қайырлы күн';
  @override
  String get dashboardActiveOrders => 'Белсенді тапсырыстар';
  @override
  String get dashboardDelayedOrders => 'Кешіккен тапсырыстар';
  @override
  String get dashboardCompletedThisMonth => 'Осы ай аяқталды';
  @override
  String get dashboardTotalContractAmount => 'Жалпы келісімшарт сомасы';
  @override
  String get dashboardPaymentsReceived => 'Түскен төлемдер';
  @override
  String get dashboardRemainingDebt => 'Клиент қарызы';
  @override
  String get dashboardExpenses => 'Шығындар';
  @override
  String get dashboardLowStock => 'Қоймада аз қалдық';
  @override
  String get dashboardUpcomingDeliveries => 'Жақын жеткізулер';
  @override
  String get dashboardMyOpenTasks => 'Менің тапсырмаларым';
  @override
  String get dashboardTodayTasks => 'Бүгінгі тапсырмалар';
  @override
  String get dashboardPaymentProgress => 'Төлем деңгейі';
  @override
  String get dashboardModulesTitle => 'Модульдер';
  @override
  String get dashboardLoadError => 'Деректерді жүктеу мүмкін болмады';

  @override
  String get clientsSearchHint => 'Аты немесе телефон бойынша іздеу';
  @override
  String get clientsEmptyTitle => 'Клиенттер табылмады';
  @override
  String get clientsEmptyDescription =>
      'Жаңа клиент қосу үшін төмендегі батырманы басыңыз';
  @override
  String get clientFormNameLabel => 'Аты-жөні';
  @override
  String get clientFormPhoneLabel => 'Телефон';
  @override
  String get clientFormPhoneSecondaryLabel => 'Қосымша телефон';
  @override
  String get clientFormWhatsappLabel => 'WhatsApp / Telegram';
  @override
  String get clientFormAddressLabel => 'Мекенжай';
  @override
  String get clientFormCityLabel => 'Қала';
  @override
  String get clientFormSourceLabel => 'Тапсырыс көзі';
  @override
  String get clientFormNotesLabel => 'Ескертпе';
  @override
  String get clientFormResponsibleManagerLabel => 'Жауапты менеджер';
  @override
  String get clientEditTitle => 'Клиентті өңдеу';
  @override
  String get clientNewTitle => 'Жаңа клиент';
  @override
  String get clientDeleteConfirmTitle => 'Клиентті жою';
  @override
  String get clientDeleteConfirmBody =>
      'Бұл клиентті жойғыңыз келетініне сенімдісіз бе? Бұл әрекетті кейін директор арқылы қалпына келтіруге болады';
  @override
  String get clientCreatedToast => 'Клиент қосылды';
  @override
  String get clientUpdatedToast => 'Клиент жаңартылды';
  @override
  String get clientDeletedToast => 'Клиент жойылды';
  @override
  String get clientCompanyMissingError =>
      'Компания анықталмады. Қайта кіріп көріңіз';
  @override
  String get clientNotFound => 'Клиент табылмады';
  @override
  String get clientCallAction => 'Қоңырау шалу';
  @override
  String get clientWhatsappAction => 'WhatsApp';
  @override
  String get clientNoNotes => 'Ескертпе жоқ';
  @override
  String get clientResponsibleManagerNone => 'Тағайындалмаған';

  @override
  String get orderSearchHint => 'Тапсырыс нөмірі, жиһаз түрі немесе клиент';
  @override
  String get orderFilterAll => 'Барлығы';
  @override
  String get orderStatusMeasurement => 'Замер';
  @override
  String get orderStatusAccepted => 'Қабылданды';
  @override
  String get orderStatusInProgress => 'Өңделуде';
  @override
  String get orderStatusReady => 'Тапсырыс дайын';
  @override
  String get orderStatusInstalled => 'Орнатылды';
  @override
  String get orderFormClientLabel => 'Клиент';
  @override
  String get orderFormSelectClient => 'Клиентті таңдау';
  @override
  String get orderFormProductTypeLabel => 'Жиһаз түрі';
  @override
  String get orderFormTotalAmountLabel => 'Жалпы бағасы (₸)';
  @override
  String get orderFormMeasurementDateLabel => 'Өлшем алу күні';
  @override
  String get orderFormPlannedCompletionDateLabel => 'Дайын болу мерзімі';
  @override
  String get orderFormResponsibleEmployeeLabel => 'Жауапты қызметкер';
  @override
  String get orderFormNotesLabel => 'Ескертпе';
  @override
  String get orderFormSelectDate => 'Күнді таңдау';
  @override
  String get orderNewTitle => 'Жаңа тапсырыс';
  @override
  String get orderEditTitle => 'Тапсырысты өңдеу';
  @override
  String get ordersEmptyTitle => 'Тапсырыстар табылмады';
  @override
  String get ordersEmptyDescription =>
      'Жаңа тапсырыс қосу үшін төмендегі батырманы басыңыз';
  @override
  String get orderPaidLabel => 'Төленген сома';
  @override
  String get orderRemainingLabel => 'Қалған сома';
  @override
  String get orderPaymentProgressLabel => 'Төлем пайызы';
  @override
  String get orderDeleteConfirmTitle => 'Тапсырысты жою';
  @override
  String get orderDeleteConfirmBody =>
      'Бұл тапсырысты жойғыңыз келетініне сенімдісіз бе? Бұл әрекетті кейін директор арқылы қалпына келтіруге болады';
  @override
  String get orderCreatedToast => 'Тапсырыс қосылды';
  @override
  String get orderUpdatedToast => 'Тапсырыс жаңартылды';
  @override
  String get orderDeletedToast => 'Тапсырыс жойылды';
  @override
  String get orderStatusUpdatedToast => 'Тапсырыс статусы жаңартылды';
  @override
  String get orderNotFound => 'Тапсырыс табылмады';
  @override
  String get orderSelectClientTitle => 'Клиентті таңдау';
  @override
  String get orderSelectEmployeeTitle => 'Қызметкерді таңдау';
  @override
  String get orderNoEmployeeAssigned => 'Тағайындалмаған';
  @override
  String get orderChangeStatusTitle => 'Статусты өзгерту';
  @override
  String get orderResponsibleEmployeeNone => 'Жауапты тағайындалмаған';

  @override
  String get paymentsSearchHint => 'Клиент, тапсырыс немесе төлем түрі';
  @override
  String get paymentMethodCash => 'Қолма-қол';
  @override
  String get paymentMethodKaspi => 'Kaspi';
  @override
  String get paymentMethodBankTransfer => 'Банк аударымы';
  @override
  String get paymentMethodCard => 'Карта';
  @override
  String get paymentMethodOther => 'Басқа';
  @override
  String get paymentFormAmountLabel => 'Төлем сомасы (₸)';
  @override
  String get paymentFormDateLabel => 'Төлем күні';
  @override
  String get paymentFormMethodLabel => 'Төлем түрі';
  @override
  String get paymentFormResponsibleEmployeeLabel => 'Төлемге жауапты қызметкер';
  @override
  String get paymentFormCommentLabel => 'Ескертпе';
  @override
  String get paymentFormReceiptLabel => 'Чек / файл';
  @override
  String get paymentAttachReceipt => 'Чек тіркеу';
  @override
  String get paymentReceiptAttached => 'Чек тіркелді';
  @override
  String get paymentViewReceipt => 'Чекті көру';
  @override
  String get paymentNewTitle => 'Төлем қосу';
  @override
  String get paymentEditTitle => 'Төлемді өңдеу';
  @override
  String get paymentsEmptyTitle => 'Төлемдер табылмады';
  @override
  String get paymentsEmptyDescription =>
      'Тапсырысқа төлем қосу үшін тапсырыс бетіне өтіңіз';
  @override
  String get paymentCreatedToast => 'Төлем қосылды';
  @override
  String get paymentUpdatedToast => 'Төлем жаңартылды';
  @override
  String get paymentDeletedToast => 'Төлем жойылды';
  @override
  String get paymentDeleteConfirmTitle => 'Төлемді жою';
  @override
  String get paymentDeleteConfirmBody =>
      'Бұл төлемді жойғыңыз келетініне сенімдісіз бе? Тапсырыстың қалған сомасы қайта есептеледі';
  @override
  String get paymentFilterAllMethods => 'Барлық түрлер';
  @override
  String get paymentFilterDateFrom => 'Бастап';
  @override
  String get paymentFilterDateTo => 'Дейін';
  @override
  String get paymentFilterClear => 'Тазалау';
  @override
  String get paymentHistoryTitle => 'Төлем тарихы';
  @override
  String get paymentMaxAmountHint => 'Ең көбі';
  @override
  String get paymentNotFound => 'Төлем табылмады';
  @override
  String get paymentAmountExceedsRemaining => 'Сома қалған сомадан асып кетті';

  @override
  String get employeesSearchHint => 'Аты-жөні, email немесе телефон';
  @override
  String get employeeFilterAllRoles => 'Барлық рөлдер';
  @override
  String get employeeFilterActive => 'Белсенді';
  @override
  String get employeeFilterInactive => 'Белсенді емес';
  @override
  String get employeeFilterAllStatuses => 'Барлық статустар';
  @override
  String get employeeRoleDirector => 'Директор';
  @override
  String get employeeRoleManager => 'Менеджер';
  @override
  String get employeeRoleMeasurer => 'Өлшеуші';
  @override
  String get employeeRoleDesigner => 'Дизайнер';
  @override
  String get employeeRoleWorkshopManager => 'Цех бастығы';
  @override
  String get employeeRoleMaster => 'Шебер';
  @override
  String get employeeRoleAssistant => 'Көмекші';
  @override
  String get employeeRoleInstaller => 'Жеткізуші';
  @override
  String get employeeRoleAccountant => 'Бухгалтер';
  @override
  String get employeeRoleWarehouse => 'Қоймашы';
  @override
  String get employeeRoleAdmin => 'Жүйе әкімшісі';
  @override
  String get employeeFormFullNameLabel => 'Аты-жөні';
  @override
  String get employeeFormPhoneLabel => 'Телефон нөмірі';
  @override
  String get employeeFormEmailLabel => 'Email';
  @override
  String get employeeFormPasswordLabel => 'Құпиясөз';
  @override
  String get employeeFormRoleLabel => 'Рөлі';
  @override
  String get employeeFormHireDateLabel => 'Жұмысқа кірген күні';
  @override
  String get employeeFormSalaryTypeLabel => 'Жалақы түрі';
  @override
  String get employeeFormBaseSalaryLabel => 'Тұрақты айлық мөлшері (₸)';
  @override
  String get employeeFormBonusPercentLabel => 'Бонус пайызы (%)';
  @override
  String get employeeFormStatusLabel => 'Қызметкер статусы';
  @override
  String get employeeFormNotesLabel => 'Ескертпе';
  @override
  String get salaryTypeFixed => 'Тұрақты';
  @override
  String get salaryTypePercentage => 'Пайыздық';
  @override
  String get employeeNewTitle => 'Қызметкер қосу';
  @override
  String get employeeEditTitle => 'Қызметкерді өңдеу';
  @override
  String get employeeMyProfileTitle => 'Менің профилім';
  @override
  String get employeesEmptyTitle => 'Қызметкерлер табылмады';
  @override
  String get employeesEmptyDescription =>
      'Жаңа қызметкер қосу үшін төмендегі батырманы басыңыз';
  @override
  String get employeeCreatedToast => 'Қызметкер қосылды';
  @override
  String get employeeUpdatedToast => 'Қызметкер жаңартылды';
  @override
  String get employeeDeletedToast => 'Қызметкер жойылды';
  @override
  String get employeeActivatedToast => 'Қызметкер белсенді етілді';
  @override
  String get employeeDeactivatedToast => 'Қызметкер белсенді емес етілді';
  @override
  String get employeeAvatarUpdatedToast => 'Аватар жаңартылды';
  @override
  String get employeeDeleteConfirmTitle => 'Қызметкерді жою';
  @override
  String get employeeDeleteConfirmBody =>
      'Бұл қызметкерді жойғыңыз келетініне сенімдісіз бе? Бұл әрекетті кейін қалпына келтіруге болады';
  @override
  String get employeeDeactivateConfirmTitle => 'Қызметкерді белсенді емес ету';
  @override
  String get employeeDeactivateConfirmBody =>
      'Бұл қызметкер жүйеге кіре алмай қалады. Кейін қайта белсенді ете аласыз';
  @override
  String get employeeNotFound => 'Қызметкер табылмады';
  @override
  String get employeeFinancialHidden => 'Жасырын';
  @override
  String get employeeStatusActive => 'Белсенді';
  @override
  String get employeeStatusInactive => 'Белсенді емес';
  @override
  String get employeeSelectRoleTitle => 'Рөлді таңдау';
  @override
  String get employeeSelectSalaryTypeTitle => 'Жалақы түрін таңдау';
  @override
  String get employeeSelectDateTitle => 'Күнді таңдау';
  @override
  String get employeeNoPhone => 'Телефон көрсетілмеген';
  @override
  String get employeeNoHireDate => 'Күн көрсетілмеген';
  @override
  String get employeeNoNotes => 'Ескертпе жоқ';
  @override
  String get employeeChangeAvatar => 'Аватарды өзгерту';
  @override
  String get employeeRolePurchaser => 'Сатып алу менеджері';

  // ---- partners ----
  @override
  String get partnerCategoryGazelleDriver => 'Газелист';
  @override
  String get partnerCategoryTaxiDriver => 'Таксист';
  @override
  String get partnerCategoryLdsp => 'ЛДСП';
  @override
  String get partnerCategoryMdfCnc => 'МДФ ЧПУ';
  @override
  String get partnerCategoryFittings => 'Фурнитура';
  @override
  String get partnerCategoryCanteen => 'Асхана';
  @override
  String get partnerCategoryOther => 'Басқа';
  @override
  String get partnersSearchHint => 'Атауы, телефон немесе компания';
  @override
  String get partnerFilterAllCategories => 'Барлығы';
  @override
  String get partnerFilterActive => 'Белсенді';
  @override
  String get partnerFilterInactive => 'Белсенді емес';
  @override
  String get partnerFilterAllStatuses => 'Барлық статустар';
  @override
  String get partnerSelectCategoryTitle => 'Санатты таңдау';
  @override
  String get partnerShowActiveAction => 'Белсенділерді көрсету';
  @override
  String get partnerShowTrashAction => 'Өшірілгендерді көрсету';
  @override
  String get partnerFormDisplayNameLabel => 'Атауы немесе аты-жөні';
  @override
  String get partnerFormCompanyNameLabel => 'Компания атауы';
  @override
  String get partnerFormCategoryLabel => 'Санаты';
  @override
  String get partnerFormPhoneLabel => 'Телефон нөмірі';
  @override
  String get partnerFormPhoneSecondaryLabel => 'Қосымша телефон';
  @override
  String get partnerFormWhatsappLabel => 'WhatsApp нөмірі';
  @override
  String get partnerFormCityLabel => 'Қала';
  @override
  String get partnerFormAddressLabel => 'Мекенжай';
  @override
  String get partnerFormContactPersonLabel => 'Байланыс адамы';
  @override
  String get partnerFormTaxIdLabel => 'БСН/ЖСН';
  @override
  String get partnerFormServiceDescriptionLabel =>
      'Қызмет немесе тауар сипаттамасы';
  @override
  String get partnerFormPriceNoteLabel => 'Баға туралы ескертпе';
  @override
  String get partnerFormTrustRatingLabel => 'Сенімділік рейтингі';
  @override
  String get partnerFormLastWorkedAtLabel => 'Соңғы жұмыс күні';
  @override
  String get partnerFormNotesLabel => 'Ескертпе';
  @override
  String get partnerFormStatusLabel => 'Статус';
  @override
  String get partnerFormBankDetailsLabel => 'Банк немесе төлем реквизиттері';
  @override
  String get partnerFormBalanceLabel => 'Қарыз/аванс балансы';
  @override
  String get partnerTrustRatingUnset => 'Белгіленбеген';
  @override
  String get partnerNewTitle => 'Жаңа серіктес';
  @override
  String get partnerEditTitle => 'Серіктесті өңдеу';
  @override
  String get partnerCallAction => 'Қоңырау шалу';
  @override
  String get partnerWhatsappAction => 'WhatsApp';
  @override
  String get partnerOpenMapAction => 'Картадан ашу';
  @override
  String get partnerEditFinancialsAction => 'Қаржылық деректерді өзгерту';
  @override
  String get partnerRestoreAction => 'Қалпына келтіру';
  @override
  String get partnerAddDocumentAction => 'Құжат тіркеу';
  @override
  String get partnerCreatedToast => 'Серіктес қосылды';
  @override
  String get partnerUpdatedToast => 'Серіктес жаңартылды';
  @override
  String get partnerDeletedToast => 'Серіктес өшірілді';
  @override
  String get partnerRestoredToast => 'Серіктес қалпына келтірілді';
  @override
  String get partnerDocumentAddedToast => 'Құжат тіркелді';
  @override
  String get partnerDocumentDeletedToast => 'Құжат өшірілді';
  @override
  String get partnerDeleteConfirmTitle => 'Серіктесті жою';
  @override
  String get partnerDeleteConfirmBody =>
      'Серіктесті жойғыңыз келе ме? Бұл әрекетті директор қалпына келтіре алады.';
  @override
  String get partnersEmptyTitle => 'Серіктестер табылмады';
  @override
  String get partnersEmptyDescription =>
      'Жаңа серіктес қосу үшін “+” батырмасын басыңыз';
  @override
  String get partnersTrashEmptyTitle => 'Өшірілген серіктестер жоқ';
  @override
  String get partnersLoadError => 'Серіктестер тізімін жүктеу мүмкін болмады';
  @override
  String get partnersLoadMoreAction => 'Көбірек жүктеу';
  @override
  String get partnerNotFound => 'Серіктес табылмады';
  @override
  String get partnerStatusInactive => 'Белсенді емес';
  @override
  String get partnerDocumentsTitle => 'Құжаттар';
  @override
  String get partnerDocumentsLoadError => 'Құжаттарды жүктеу мүмкін болмады';
  @override
  String get partnerDocumentsEmpty => 'Құжаттар әлі тіркелмеген';

  // ---- analytics ----
  @override
  String get analyticsPeriodDay => 'Күн';
  @override
  String get analyticsPeriodWeek => 'Апта';
  @override
  String get analyticsPeriodMonth => 'Ай';
  @override
  String get analyticsPeriodYear => 'Жыл';
  @override
  String get analyticsSelectPeriodTitle => 'Кезеңді таңдау';
  @override
  String get analyticsPeriodComparisonNew => 'жаңа';
  @override
  String get analyticsOrdersByStatusTitle => 'Статус бойынша тапсырыстар';
  @override
  String get analyticsNoDataForPeriod => 'Бұл кезеңде деректер жоқ';
  @override
  String get analyticsPaymentMethodsTitle =>
      'Төлем әдістері бойынша статистика';
  @override
  String get analyticsEmployeeKpiTitle => 'Қызметкерлер бойынша KPI';
  @override
  String get analyticsOrdersAssignedLabel => 'Тағайындалған тапсырыстар';
  @override
  String get analyticsOrdersCompletedLabel => 'Аяқталған';
  @override
  String get analyticsPaymentsRecordedLabel => 'Тіркелген төлемдер';
  @override
  String get analyticsTopClientsTitle => 'Ең көп тапсырыс беретін клиенттер';
  @override
  String get analyticsOrdersCountSuffix => 'тапсырыс';
  @override
  String get analyticsLoadError => 'Аналитиканы жүктеу мүмкін болмады';
  @override
  String get analyticsOwnKpiOnlyNote =>
      'Сізге тек өз KPI көрсеткіштеріңіз қолжетімді';
  @override
  String get analyticsTurnover => 'Жалпы айналым';
  @override
  String get analyticsOrdersCount => 'Тапсырыстар саны';
  @override
  String get analyticsInstalledCount => 'Орнатылған тапсырыстар';
  @override
  String get analyticsNewClientsCount => 'Жаңа клиенттер';
  @override
  String get analyticsAvgOrderAmount => 'Орташа тапсырыс сомасы';
  @override
  String get analyticsPaymentsReceived => 'Түскен төлемдер';
  @override
  String get analyticsRemainingDebt => 'Қалған қарыз';

  // ---- production ----
  @override
  String get productionNoMasterAssigned => 'Шебер тағайындалмаған';
  @override
  String get productionStageMovedToast => 'Кезең ауыстырылды';
  @override
  String get productionColumnEmpty => 'Бос';
  @override
  String get productionSelectMasterTitle => 'Шеберді таңдау';
  @override
  String get productionMastersLoadError =>
      'Шеберлер тізімін жүктеу мүмкін болмады';
  @override
  String get productionNoMastersAvailable => 'Қолжетімді шебер жоқ';
  @override
  String get productionSelectStageTitle => 'Кезеңді таңдау';
  @override
  String get productionFilterAllStages => 'Барлық кезеңдер';
  @override
  String get productionMaterialsTitle => 'Материал жеткіліктілігі';
  @override
  String get productionNoMaterialsReserved => 'Материал брондалмаған';
  @override
  String get productionPhotoAddedToast => 'Фото тіркелді';
  @override
  String get productionPhotoDeletedToast => 'Фото өшірілді';
  @override
  String get productionPhotosTitle => 'Фотолар';
  @override
  String get productionAddPhotoAction => 'Фото тіркеу';
  @override
  String get productionNoPhotos => 'Фото әлі тіркелмеген';
  @override
  String get productionTimeLogStartedToast => 'Уақыт есептеуіші басталды';
  @override
  String get productionTimeLogStoppedToast => 'Уақыт есептеуіші тоқтатылды';
  @override
  String get productionTimeLogsTitle => 'Уақыт журналдары';
  @override
  String get productionStopTimerAction => 'Тоқтату';
  @override
  String get productionStartTimerAction => 'Бастау';
  @override
  String get productionNoTimeLogs => 'Уақыт журналдары жоқ';
  @override
  String get productionTimeLogOngoing => 'жүруде';
  @override
  String get productionHistoryTitle => 'Өндіріс тарихы';
  @override
  String get productionNoHistory => 'Тарих әлі жоқ';
  @override
  String get productionQrTitle => 'QR код';
  @override
  String get productionScanQrTitle => 'QR кодты сканерлеу';
  @override
  String get productionCameraUnavailable => 'Камера қолжетімсіз';
  @override
  String get productionSearchHint => 'Тапсырыс нөмірі, түрі немесе клиент';
  @override
  String get productionLoadError => 'Өндіріс кезегін жүктеу мүмкін болмады';
  @override
  String get productionQueueEmptyTitle => 'Өндірісте тапсырыстар жоқ';
  @override
  String get productionOrderDetailTitle => 'Өндіріс мәліметі';
  @override
  String get productionOrderNotFound => 'Тапсырыс табылмады';
  @override
  String get productionMasterAssignedToast => 'Шебер тағайындалды';
  @override
  String get productionCurrentStageLabel => 'Ағымдағы кезең';
  @override
  String get productionMoveStageAction => 'Кезеңді ауыстыру';

  // ---- warehouse ----
  @override
  String get warehouseSearchHint => 'Материал атауы немесе barcode';
  @override
  String get warehouseLoadError => 'Қойма деректерін жүктеу мүмкін болмады';
  @override
  String get warehouseEmptyTitle => 'Материалдар табылмады';
  @override
  String get warehouseFilterAllCategories => 'Барлық санаттар';
  @override
  String get warehouseLowStockFilterLabel => 'Аз қалдық қана';
  @override
  String get warehouseTableColumnMaterial => 'Материал';
  @override
  String get warehouseTableColumnCategory => 'Санат';
  @override
  String get warehouseTableColumnAvailable => 'Қолжетімді';
  @override
  String get warehouseTableColumnReserved => 'Резервте';
  @override
  String get warehouseTableColumnMin => 'Мин.';
  @override
  String get warehouseLowStockBadge => 'Аз қалдық';
  @override
  String get warehouseMaterialDetailTitle => 'Материал мәліметі';
  @override
  String get warehouseAvailableLabel => 'Қолжетімді қалдық';
  @override
  String get warehouseReservedLabel => 'Резервте';
  @override
  String get warehouseMinQuantityLabel => 'Минималды қалдық';
  @override
  String get warehouseBarcodeLabel => 'Barcode';
  @override
  String get warehouseNoBarcode => 'Barcode көрсетілмеген';
  @override
  String get warehousePreferredSupplierLabel => 'Негізгі жеткізуші';
  @override
  String get warehouseNoSupplier => 'Жеткізуші тағайындалмаған';
  @override
  String get warehouseContactSupplierAction => 'Жеткізушімен байланысу';
  @override
  String get warehouseCallAction => 'Қоңырау шалу';
  @override
  String get warehouseWhatsappAction => 'WhatsApp';
  @override
  String get warehouseReceiveAction => 'Келіп түсу';
  @override
  String get warehouseIssueAction => 'Шығыс';
  @override
  String get warehouseReserveAction => 'Резервтеу';
  @override
  String get warehouseHoldAction => 'Резерв қою';
  @override
  String get warehouseAddToCartAction => 'Себетке қосу';
  @override
  String get warehouseBatchesTitle => 'Партиялар';
  @override
  String get warehouseNoBatches => 'Партиялар жоқ';
  @override
  String get warehouseBatchRemainingLabel => 'қалды';
  @override
  String get warehouseHoldsTitle => 'Резервтер';
  @override
  String get warehouseNoHolds => 'Белсенді резерв жоқ';
  @override
  String get warehouseReleaseHoldAction => 'Резервтен босату';
  @override
  String get warehouseHoldReleasedToast => 'Резерв босатылды';
  @override
  String get warehouseReceiveTitle => 'Келіп түсуді тіркеу';
  @override
  String get warehouseQuantityLabel => 'Мөлшер';
  @override
  String get warehouseCostPerUnitLabel => 'Бірлік құны (тиын)';
  @override
  String get warehouseBatchNumberLabel => 'Партия нөмірі';
  @override
  String get warehouseLocationLabel => 'Қойма орны';
  @override
  String get warehouseSelectLocationTitle => 'Қойма орнын таңдаңыз';
  @override
  String get warehouseReceivedToast => 'Келіп түсу тіркелді';
  @override
  String get warehouseQuantityRequiredError => 'Мөлшерді енгізіңіз';
  @override
  String get warehouseReserveTitle => 'Тапсырысқа резервтеу';
  @override
  String get warehouseOrderIdLabel => 'Тапсырыс ID';
  @override
  String get warehouseReservedToast => 'Материал резервтелді';
  @override
  String get warehouseHoldTitle => 'Жаңа резерв';
  @override
  String get warehouseReasonLabel => 'Себебі';
  @override
  String get warehouseHoldCreatedToast => 'Резерв құрылды';
  @override
  String get warehouseCartTitle => 'Себет';
  @override
  String get warehouseCartEmpty => 'Себет бос';
  @override
  String get warehouseIssueConfirmAction => 'Шығысты растау';
  @override
  String get warehouseIssuedToast => 'Шығыс тіркелді';
  @override
  String get warehouseScanTitle => 'Barcode / QR сканерлеу';
  @override
  String get warehouseScanNotFoundToast => 'Материал табылмады';
  @override
  String get warehouseCameraUnavailable => 'Камера қолжетімсіз';
  @override
  String get warehouseSummaryTitle => 'Қойма аналитикасы';
  @override
  String get warehouseMaterialsCountLabel => 'Материал түрлері';
  @override
  String get warehouseLowStockCountLabel => 'Аз қалдықты позициялар';
  @override
  String get warehouseTotalValueLabel => 'Жалпы құны';

  // ---- purchases ----
  @override
  String get purchasesStatusDraft => 'Жоба';
  @override
  String get purchasesStatusApproved => 'Бекітілді';
  @override
  String get purchasesStatusRejected => 'Бас тартылды';
  @override
  String get purchasesStatusDelivered => 'Жеткізілді';
  @override
  String get purchasesStatusReceived => 'Қабылданды';
  @override
  String get purchasesStatusCancelled => 'Жойылды';
  @override
  String get purchasesSearchHint => 'Тапсырыс нөмірі немесе жеткізуші';
  @override
  String get purchasesLoadError =>
      'Сатып алу тапсырыстарын жүктеу мүмкін болмады';
  @override
  String get purchasesEmptyTitle => 'Тапсырыстар табылмады';
  @override
  String get purchasesFilterAllStatuses => 'Барлық статустар';
  @override
  String get purchasesSelectStatusTitle => 'Статусты таңдаңыз';
  @override
  String get purchasesTableColumnNumber => 'Нөмірі';
  @override
  String get purchasesTableColumnSupplier => 'Жеткізуші';
  @override
  String get purchasesTableColumnStatus => 'Статус';
  @override
  String get purchasesTableColumnTotal => 'Сомасы';
  @override
  String get purchasesTableColumnExpectedDate => 'Күтілетін жеткізу';
  @override
  String get purchasesCreateAction => 'Жаңа тапсырыс';
  @override
  String get purchasesPendingBadge => 'Жолда';
  @override
  String get purchasesDetailTitle => 'Сатып алу тапсырысы';
  @override
  String get purchasesOrderNotFound => 'Тапсырыс табылмады';
  @override
  String get purchasesResponsibleEmployeeLabel => 'Жауапты қызметкер';
  @override
  String get purchasesNoResponsibleEmployee =>
      'Жауапты қызметкер тағайындалмаған';
  @override
  String get purchasesExpectedDeliveryLabel => 'Күтілетін жеткізу күні';
  @override
  String get purchasesNoExpectedDelivery => 'Күн көрсетілмеген';
  @override
  String get purchasesSubtotalLabel => 'Аралық сома';
  @override
  String get purchasesDeliveryCostLabel => 'Жеткізу құны';
  @override
  String get purchasesVatLabel => 'ҚҚС';
  @override
  String get purchasesDiscountLabel => 'Жеңілдік';
  @override
  String get purchasesTotalLabel => 'Жалпы сома';
  @override
  String get purchasesCommentLabel => 'Ескерту';
  @override
  String get purchasesRejectionReasonLabel => 'Бас тарту себебі';
  @override
  String get purchasesItemsTitle => 'Материалдар';
  @override
  String get purchasesNoItems => 'Материалдар қосылмаған';
  @override
  String get purchasesApproveAction => 'Бекіту';
  @override
  String get purchasesRejectAction => 'Бас тарту';
  @override
  String get purchasesDeliverAction => 'Жеткізілді деп белгілеу';
  @override
  String get purchasesReceiveAction => 'Қабылдау';
  @override
  String get purchasesCancelAction => 'Тапсырысты жою';
  @override
  String get purchasesEditAction => 'Өңдеу';
  @override
  String get purchasesApprovedToast => 'Тапсырыс бекітілді';
  @override
  String get purchasesRejectedToast => 'Тапсырыстан бас тартылды';
  @override
  String get purchasesDeliveredToast => 'Тапсырыс жеткізілді деп белгіленді';
  @override
  String get purchasesReceivedToast => 'Тапсырыс қабылданды';
  @override
  String get purchasesCancelledToast => 'Тапсырыс жойылды';
  @override
  String get purchasesConfirmRejectTitle => 'Тапсырыстан бас тарту';
  @override
  String get purchasesConfirmCancelTitle => 'Тапсырысты жою';
  @override
  String get purchasesReasonLabel => 'Себебі';
  @override
  String get purchasesCreateTitle => 'Жаңа сатып алу тапсырысы';
  @override
  String get purchasesEditTitle => 'Тапсырысты өңдеу';
  @override
  String get purchasesOrderNumberLabel => 'Тапсырыс нөмірі';
  @override
  String get purchasesOrderNumberRequiredError => 'Тапсырыс нөмірін енгізіңіз';
  @override
  String get purchasesSupplierLabel => 'Жеткізуші';
  @override
  String get purchasesSupplierRequiredError => 'Жеткізушіні таңдаңыз';
  @override
  String get purchasesSelectSupplierTitle => 'Жеткізушіні таңдаңыз';
  @override
  String get purchasesSuppliersLoadError =>
      'Жеткізушілерді жүктеу мүмкін болмады';
  @override
  String get purchasesNoSuppliersAvailable => 'Жеткізушілер табылмады';
  @override
  String get purchasesSelectEmployeeTitle => 'Қызметкерді таңдаңыз';
  @override
  String get purchasesEmployeesLoadError =>
      'Қызметкерлерді жүктеу мүмкін болмады';
  @override
  String get purchasesNoEmployeesAvailable => 'Қызметкерлер табылмады';
  @override
  String get purchasesAddItemAction => 'Материал қосу';
  @override
  String get purchasesNoItemsAddedError => 'Кемінде бір материал қосыңыз';
  @override
  String get purchasesCreatedToast => 'Тапсырыс құрылды';
  @override
  String get purchasesUpdatedToast => 'Тапсырыс сақталды';
  @override
  String get purchasesSelectMaterialTitle => 'Материалды таңдаңыз';
  @override
  String get purchasesMaterialsLoadError =>
      'Материалдарды жүктеу мүмкін болмады';
  @override
  String get purchasesNoMaterialsAvailable => 'Материалдар табылмады';
  @override
  String get purchasesQuantityLabel => 'Мөлшер';
  @override
  String get purchasesUnitPriceLabel => 'Бірлік бағасы (тиын)';
  @override
  String get purchasesLocationLabel => 'Қойма орны';
  @override
  String get purchasesReceiveConfirmTitle => 'Тапсырысты қабылдау';
  @override
  String get purchasesReceiveConfirmBody =>
      'Материалдар қоймаға қабылданып, қалдық жаңартылады. Жалғастыру керек пе?';
  @override
  String get purchasesLocationRequiredError =>
      'Әр материалға қойма орнын көрсетіңіз';
  @override
  String get purchasesPaymentsTitle => 'Төлемдер';
  @override
  String get purchasesRecordPaymentAction => 'Төлем жазу';
  @override
  String get purchasesPaymentAmountLabel => 'Төлем сомасы';
  @override
  String get purchasesPaymentMethodLabel => 'Төлем тәсілі';
  @override
  String get purchasesSelectMethodTitle => 'Төлем тәсілін таңдаңыз';
  @override
  String get purchasesPaymentDateLabel => 'Төлем күні';
  @override
  String get purchasesPaymentCommentLabel => 'Ескерту';
  @override
  String get purchasesPaymentRecordedToast => 'Төлем жазылды';
  @override
  String get purchasesReversePaymentAction => 'Төлемді қайтару';
  @override
  String get purchasesPaymentReversedToast => 'Төлем қайтарылды';
  @override
  String get purchasesReverseReasonLabel => 'Қайтару себебі';
  @override
  String get purchasesNoPayments => 'Төлемдер жоқ';
  @override
  String get purchasesInvoiceLabel => 'Шот-фактура';
  @override
  String get purchasesAdvancePaymentLabel => 'Аванс (шот-фактурасыз)';
  @override
  String get purchasesOutstandingBalanceLabel => 'Қалған қарыз';
  @override
  String get purchasesAdvanceBalanceLabel => 'Аванс қалдығы';
  @override
  String get purchasesInvoicesTitle => 'Шот-фактуралар';
  @override
  String get purchasesNoInvoices => 'Шот-фактуралар жоқ';
  @override
  String get purchasesInvoiceStatusUnpaid => 'Төленбеген';
  @override
  String get purchasesInvoiceStatusPartial => 'Ішінара төленген';
  @override
  String get purchasesInvoiceStatusPaid => 'Төленген';
  @override
  String get purchasesInvoiceAmountLabel => 'Сомасы';
  @override
  String get purchasesInvoicePaidLabel => 'Төленді';
  @override
  String get purchasesInvoiceDueDateLabel => 'Төлеу мерзімі';
  @override
  String get purchasesAnalyticsTitle => 'Сатып алу аналитикасы';
  @override
  String get purchasesMonthlyPurchasesLabel => 'Айлық сатып алу';
  @override
  String get purchasesTotalDebtLabel => 'Жалпы қарыз';
  @override
  String get purchasesTotalAdvanceLabel => 'Жалпы аванс';
  @override
  String get purchasesAvgUnitPriceLabel => 'Орташа сатып алу бағасы';
  @override
  String get purchasesTopMaterialsTitle => 'Ең көп сатып алынған материалдар';
  @override
  String get purchasesSupplierRatingsTitle => 'Жеткізуші рейтингі';
  @override
  String get purchasesOnTimeRateLabel => 'Уақытылы жеткізу';
  @override
  String get purchasesNoDataYet => 'Деректер әлі жоқ';
  @override
  String get purchasesPurchaseHistoryTitle => 'Сатып алу тарихы';
  @override
  String get purchasesNoPurchaseHistory => 'Сатып алу тарихы жоқ';
  @override
  String get purchasesFilterAllSuppliers => 'Барлық жеткізушілер';
  @override
  String get purchasesSupplierFilterLabel => 'Жеткізуші бойынша сүзу';
  @override
  String get purchasesDateRangeLabel => 'Күн аралығы';
  @override
  String get purchasesClearFilterAction => 'Тазарту';
  @override
  String get purchasesLoadMoreAction => 'Көбірек көрсету';
  @override
  String get purchasesCreatedAtLabel => 'Құрылған күні';
  @override
  String get purchasesSupplierBalanceTitle => 'Жеткізуші балансы';
  @override
  String get purchasesReceiveGuardMessage =>
      'Бұл тапсырысты қабылдау мүмкін емес — тек "Жеткізілді" статусындағы тапсырыстар қабылданады';
  @override
  String get purchasesPayInvoiceAction => 'Осы шот-фактураны төлеу';

  // ---- company registration / onboarding ----
  @override
  String get companyRoleViewer => 'Бақылаушы';
  @override
  String get onboardingChoiceTitle => 'Компанияңызды таңдаңыз';
  @override
  String get onboardingChoiceSubtitle =>
      'Жаңа компания құрыңыз немесе бар компанияға қосылыңыз';
  @override
  String get onboardingCreateCompanyOption => 'Жаңа компания құру';
  @override
  String get onboardingCreateCompanyDescription =>
      'Компанияңызды тіркеп, оның иесі болыңыз';
  @override
  String get onboardingJoinCompanyOption => 'Бар компанияға қосылу';
  @override
  String get onboardingJoinCompanyDescription =>
      'Компания коды немесе шақыру коды арқылы қосылыңыз';
  @override
  String get onboardingRejectedBanner =>
      'Алдыңғы сұранысыңыз қабылданбады. Қайта сұраныс жіберуге болады';
  @override
  String get createCompanyTitle => 'Жаңа компания';
  @override
  String get createCompanyNameLabel => 'Компания атауы';
  @override
  String get createCompanyNameRequiredError => 'Компания атауын енгізіңіз';
  @override
  String get createCompanyPhoneLabel => 'Телефон';
  @override
  String get createCompanyEmailLabel => 'Email';
  @override
  String get createCompanyCityLabel => 'Қала';
  @override
  String get createCompanyAddressLabel => 'Мекенжай';
  @override
  String get createCompanyIinBinLabel => 'ИИН/БИН';
  @override
  String get createCompanySubmitButton => 'Компанияны құру';
  @override
  String get createCompanySuccessToast => 'Компания сәтті құрылды';
  @override
  String get joinCompanyTitle => 'Компанияға қосылу';
  @override
  String get joinCompanyTabByCode => 'Компания коды';
  @override
  String get joinCompanyTabByInvite => 'Шақыру коды';
  @override
  String get joinCompanyCodeLabel => 'Компания коды';
  @override
  String get joinCompanyCodeRequiredError => 'Компания кодын енгізіңіз';
  @override
  String get joinCompanyInviteCodeLabel => 'Шақыру коды';
  @override
  String get joinCompanyInviteCodeRequiredError => 'Шақыру кодын енгізіңіз';
  @override
  String get joinCompanyRoleLabel => 'Қалаған рөл';
  @override
  String get joinCompanyRoleRequiredError => 'Рөлді таңдаңыз';
  @override
  String get joinCompanySelectRoleTitle => 'Рөлді таңдаңыз';
  @override
  String get joinCompanyMessageLabel => 'Қысқа хабарлама (міндетті емес)';
  @override
  String get joinCompanySubmitButton => 'Сұраныс жіберу';
  @override
  String get joinCompanyAcceptInviteButton => 'Шақыруды қабылдау';
  @override
  String get joinCompanyRequestSentToast => 'Сұраныс жіберілді';
  @override
  String get joinCompanyInviteAcceptedToast => 'Сіз компанияға қосылдыңыз';
  @override
  String get joinCompanyScanQrAction => 'QR кодты сканерлеу';
  @override
  String get waitingApprovalTitle => 'Растауды күту';
  @override
  String get waitingApprovalCompanyLabel => 'Компания';
  @override
  String get waitingApprovalRoleLabel => 'Сұралған рөл';
  @override
  String get waitingApprovalSubmittedLabel => 'Жіберілген күні';
  @override
  String get waitingApprovalStatusPending => 'Қарастырылуда';
  @override
  String get waitingApprovalStatusRejected => 'Қабылданбады';
  @override
  String get waitingApprovalRejectionReasonLabel => 'Себебі';
  @override
  String get waitingApprovalWithdrawAction => 'Сұранысты қайтарып алу';
  @override
  String get waitingApprovalWithdrawConfirmTitle =>
      'Сұранысты қайтарып алу керек пе?';
  @override
  String get waitingApprovalWithdrawnToast => 'Сұраныс қайтарып алынды';
  @override
  String get waitingApprovalTryAgainAction => 'Қайта сұраныс жіберу';
  @override
  String get waitingApprovalEmptyTitle => 'Сұраныс табылмады';
  @override
  String get accessBlockedSuspendedTitle => 'Тіркелгі уақытша тоқтатылған';
  @override
  String get accessBlockedSuspendedMessage =>
      'Директорға хабарласыңыз немесе кейінірек қайталаңыз';
  @override
  String get accessBlockedCompanyInactiveTitle => 'Компания белсенді емес';
  @override
  String get accessBlockedCompanyInactiveMessage =>
      'Компанияңыздың қолжетімділігі уақытша шектелген. Әкімшіге хабарласыңыз';
  @override
  String get accessBlockedSignOutAction => 'Шығу';
  @override
  String get companyRequestsTitle => 'Қосылу сұраныстары';
  @override
  String get companyRequestsEmptyTitle => 'Күтіп тұрған сұраныстар жоқ';
  @override
  String get companyRequestsEmptyDescription =>
      'Жаңа қосылу сұраныстары осы жерде көрсетіледі';
  @override
  String get companyRequestsApproveAction => 'Қабылдау';
  @override
  String get companyRequestsRejectAction => 'Бас тарту';
  @override
  String get companyRequestsChangeRoleAction => 'Рөлді өзгерту';
  @override
  String get companyRequestsApprovedToast => 'Сұраныс қабылданды';
  @override
  String get companyRequestsRejectedToast => 'Сұраныс қабылданбады';
  @override
  String get companyRequestsRejectReasonLabel =>
      'Бас тарту себебі (міндетті емес)';
  @override
  String get companyRequestsRequestedRoleLabel => 'Сұралған рөл';
  @override
  String get companyRequestsMessageLabel => 'Хабарлама';
  @override
  String get companyRequestsInviteAction => 'Қызметкер шақыру';
  @override
  String get companyRequestsMembersAction => 'Компания мүшелері';
  @override
  String get companyInviteTitle => 'Қызметкер шақыру';
  @override
  String get companyInviteRoleLabel => 'Рөл';
  @override
  String get companyInviteMaxUsesLabel => 'Қолдану саны';
  @override
  String get companyInviteExpiresLabel => 'Жарамдылық мерзімі';
  @override
  String get companyInviteGenerateAction => 'Шақыру коды жасау';
  @override
  String get companyInviteCodeLabel => 'Шақыру коды';
  @override
  String get companyInviteCopyAction => 'Көшіру';
  @override
  String get companyInviteCopiedToast => 'Код көшірілді';
  @override
  String get companyInviteEmailNote =>
      'Кодты қызметкерге өзіңіз жіберіңіз (email арқылы автоматты жіберу әлі қосылмаған)';
  @override
  String get companyMembersTitle => 'Компания мүшелері';
  @override
  String get companyMembersEmptyTitle => 'Мүшелер табылмады';
  @override
  String get companyMembersRoleLabel => 'Рөлі';

  // ---- company settings & subscription (Stage 3) ----
  @override
  String get settingsMenuCompany => 'Компания';
  @override
  String get settingsMenuSubscription => 'Жазылым';
  @override
  String get settingsMenuBilling => 'Төлемдер тарихы';
  @override
  String get companySettingsTitle => 'Компания баптаулары';
  @override
  String get companySettingsSavedToast => 'Баптаулар сақталды';
  @override
  String get companySettingsLogoLabel => 'Логотип (сурет сілтемесі)';
  @override
  String get companySettingsWebsiteLabel => 'Веб-сайт';
  @override
  String get companySettingsTimezoneLabel => 'Уақыт белдеуі';
  @override
  String get companySettingsCurrencyLabel => 'Валюта';
  @override
  String get companySettingsWorkingHoursLabel => 'Жұмыс уақыты';
  @override
  String get companySettingsDescriptionLabel => 'Сипаттама';
  @override
  String get subscriptionTitle => 'Жазылым';
  @override
  String get subscriptionPlansTitle => 'Тарифтер';
  @override
  String get subscriptionContactSales => 'Сатумен байланысыңыз';
  @override
  String get subscriptionMaxEmployeesLabel => 'Ең көп қызметкер саны';
  @override
  String get subscriptionMaxStorageLabel => 'Ең көп сақтау көлемі';
  @override
  String get subscriptionUnlimitedLabel => 'Шектеусіз';
  @override
  String get subscriptionPerMonthLabel => '/ ай';
  @override
  String get subscriptionCurrentPlanBadge => 'Ағымдағы тариф';
  @override
  String get subscriptionTrialStatusLabel => 'Сынақ мерзімі';
  @override
  String get subscriptionTrialActiveValue => 'Белсенді';
  @override
  String get subscriptionStartDateLabel => 'Басталу күні';
  @override
  String get subscriptionEndDateLabel => 'Аяқталу күні';
  @override
  String get subscriptionRemainingDaysLabel => 'Қалған күндер';
  @override
  String get subscriptionNextPaymentLabel => 'Келесі төлем күні';
  @override
  String get subscriptionCompanyStatusLabel => 'Компания статусы';
  @override
  String get subscriptionCompanyActiveValue => 'Белсенді';
  @override
  String get subscriptionCompanyInactiveValue => 'Белсенді емес';
  @override
  String get subscriptionActiveUsersLabel => 'Белсенді қолданушылар';
  @override
  String get subscriptionExpiredTitle => 'Жазылым мерзімі аяқталды';
  @override
  String get subscriptionExpiredMessage =>
      'Бұл модульге қолжетімділік үшін жазылымды жаңартыңыз';
  @override
  String get subscriptionExpiredRenewAction => 'Жазылымды жаңарту';
  @override
  String get billingTitle => 'Төлемдер тарихы';
  @override
  String get billingNoHistoryTitle => 'Төлем тарихы жоқ';
  @override
  String get billingNextChargeLabel => 'Келесі төлем';
  @override
  String get billingContactSalesDescription =>
      'Бұл тариф үшін бағаны сату бөлімінен сұраңыз';

  // ---- audit log (Stage 4 Part 3) ----
  @override
  String get settingsMenuAuditLog => 'Аудит журналы';
  @override
  String get auditLogTitle => 'Аудит журналы';
  @override
  String get auditLogFiltersTitle => 'Сүзгілер';
  @override
  String get auditLogDateLabel => 'Күні';
  @override
  String get auditLogAllDatesLabel => 'Барлық күндер';
  @override
  String get auditLogModuleLabel => 'Модуль';
  @override
  String get auditLogAllModulesLabel => 'Барлық модульдер';
  @override
  String get auditLogActionLabel => 'Әрекет';
  @override
  String get auditLogAllActionsLabel => 'Барлық әрекеттер';
  @override
  String get auditLogEmployeeLabel => 'Қызметкер';
  @override
  String get auditLogAllEmployeesLabel => 'Барлық қызметкерлер';
  @override
  String get auditLogClearFiltersAction => 'Сүзгілерді тазалау';
  @override
  String get auditLogDetailTitle => 'Аудит жазбасы';
  @override
  String get auditLogEntityIdLabel => 'Жазба ID';
  @override
  String get auditLogBeforeLabel => 'Дейін';
  @override
  String get auditLogAfterLabel => 'Кейін';

  // ---- generic record-not-found (deep-link fallback) ----
  @override
  String get recordNotFoundTitle => 'Жазба табылмады';
  @override
  String get recordNotFoundDescription =>
      'Бұл жазба жойылған немесе сілтеме дұрыс емес';
  @override
  String get recordNotFoundBackAction => 'Тізімге оралу';

  // ---- offline / connectivity (Stage 4 Part 7) ----
  @override
  String get offlineBannerMessage =>
      'Байланыс жоқ. Деректер соңғы белгілі күйде көрсетілуде';

  // ---- notifications (Stage 4 Part 2's UI) ----
  @override
  String get notificationsTitle => 'Хабарландырулар';
  @override
  String get notificationsEmptyTitle => 'Хабарландырулар жоқ';
  @override
  String get notificationsEmptyDescription =>
      'Жаңа хабарландырулар осында көрсетіледі';
  @override
  String get notificationsMarkAllReadAction => 'Барлығын оқылды деп белгілеу';
}
