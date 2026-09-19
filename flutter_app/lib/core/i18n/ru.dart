import 'app_strings.dart';

/// Russian — optional secondary locale (see KAZAKH_LOCALIZATION.md).
/// Kazakh remains the default; this exists so the locale switcher has
/// a second option, not because Russian is the primary language.
class RuStrings implements AppStrings {
  @override
  String get settingsTheme => 'Светлая / тёмная тема';
  const RuStrings();

  @override
  String get commonSave => 'Сохранить';
  @override
  String get commonCancel => 'Отмена';
  @override
  String get commonDelete => 'Удалить';
  @override
  String get commonEdit => 'Редактировать';
  @override
  String get commonSearch => 'Поиск';
  @override
  String get commonAdd => 'Добавить';
  @override
  String get commonClose => 'Закрыть';
  @override
  String get commonConfirm => 'Подтвердить';
  @override
  String get commonBack => 'Назад';
  @override
  String get commonRetry => 'Повторить';
  @override
  String get commonLoading => 'Загрузка...';
  @override
  String get commonError => 'Произошла ошибка';
  @override
  String get commonEmpty => 'Нет данных';
  @override
  String get commonYes => 'Да';
  @override
  String get commonNo => 'Нет';
  @override
  String get commonSeeAll => 'Показать все';
  @override
  String get commonCannotOpenLink => 'Не удалось выполнить это действие';

  @override
  String get navDashboard => 'Главная';
  @override
  String get navOrders => 'Заказы';
  @override
  String get navTasks => 'Задачи';
  @override
  String get navProfile => 'Профиль';
  @override
  String get navClients => 'Клиенты';
  @override
  String get navPayments => 'Платежи';
  @override
  String get navEmployees => 'Сотрудники';
  @override
  String get navPartners => 'Партнёры';
  @override
  String get navAnalytics => 'Аналитика';
  @override
  String get navProduction => 'Производство';
  @override
  String get navWarehouse => 'Склад';
  @override
  String get navPurchases => 'Закупки';
  @override
  String get navSettings => 'Настройки';

  @override
  String get quickAddNewClient => 'Новый клиент';
  @override
  String get quickAddNewOrder => 'Новый заказ';
  @override
  String get quickAddNewMeasurement => 'Добавить замер';
  @override
  String get quickAddNewPayment => 'Добавить платёж';
  @override
  String get quickAddNewExpense => 'Добавить расход';
  @override
  String get quickAddPhotoReport => 'Добавить фотоотчёт';

  @override
  String get authWelcomeTitle => 'Добро пожаловать в JUMA UI';
  @override
  String get authWelcomeSubtitle =>
      'Система управления мебельным производством';
  @override
  String get authPassword => 'Пароль';
  @override
  String get authConfirmPassword => 'Подтвердите пароль';
  @override
  String get authFullName => 'ФИО';
  @override
  String get authPhone => 'Телефон';
  @override
  String get authLoginButton => 'Войти';
  @override
  String get authDevelopmentLogin => 'Войти как разработчик';
  @override
  String get authDevelopmentLoginError =>
      'Не удалось подключиться к серверу разработки. Перезапустите локальный режим разработки';
  @override
  String get authForgotPassword => 'Забыли пароль?';
  @override
  String get authRememberDevice => 'Запомнить это устройство';
  @override
  String get authLogout => 'Выйти';
  @override
  String get authLogoutAllDevices => 'Выйти со всех устройств';
  @override
  String get authInvalidCredentials => 'Неверный логин или пароль';
  @override
  String get authFieldRequired => 'Это поле обязательно';
  @override
  String get authPasswordTooShort =>
      'Пароль должен содержать минимум 8 символов';
  @override
  String get authPasswordsDoNotMatch => 'Пароли не совпадают';
  @override
  String get authAccountDeactivated =>
      'Ваш аккаунт деактивирован. Обратитесь к директору';
  @override
  String get authSessionExpired => 'Сессия истекла, войдите снова';
  @override
  String get authResetPasswordTitle => 'Восстановление пароля';
  @override
  String get authResetPasswordSent => 'Ссылка для восстановления отправлена';
  @override
  String get authCheckYourEmail => 'Проверьте email';
  @override
  String get authEmail => 'Email';
  @override
  String get authSignUpTitle => 'Регистрация';
  @override
  String get authSignUpSubtitle => 'Создайте новый аккаунт';
  @override
  String get authSignUpButton => 'Зарегистрироваться';
  @override
  String get authNoAccountLink => 'Нет аккаунта? Зарегистрироваться';
  @override
  String get authHaveAccountLink => 'Уже есть аккаунт? Войти';
  @override
  String get authInvalidEmail => 'Неверный email адрес';
  @override
  String get authInvalidPhone =>
      'Неверный номер телефона. Например: +77001234567';
  @override
  String get authEmailConfirmTitle => 'Подтвердите email';
  @override
  String get authEmailConfirmSubtitle =>
      'Мы отправили ссылку для подтверждения на email:';
  @override
  String get authEmailConfirmInstructions =>
      'Откройте письмо и перейдите по ссылке, затем нажмите кнопку ниже.';
  @override
  String get authResendEmail => 'Отправить письмо ещё раз';
  @override
  String get authEmailResent => 'Письмо отправлено повторно';
  @override
  String get authContinueButton => 'Подтвердил, продолжить';
  @override
  String get authEnterPasswordToContinue =>
      'Введите пароль ещё раз, чтобы продолжить';
  @override
  String get authPhoneVerifyTitle => 'Подтвердите телефон';
  @override
  String get authPhoneVerifySubtitle =>
      'Мы отправили код подтверждения на номер:';
  @override
  String get authOtpLabel => 'SMS-код';
  @override
  String get authOtpVerifyButton => 'Подтвердить';
  @override
  String get authResendCode => 'Отправить код ещё раз';
  @override
  String get authCodeResent => 'Код отправлен повторно';
  @override
  String get authChangePhone => 'Изменить номер';

  @override
  String get dashboardGreetingPrefix => 'Добрый день';
  @override
  String get dashboardActiveOrders => 'Активные заказы';
  @override
  String get dashboardDelayedOrders => 'Просроченные заказы';
  @override
  String get dashboardCompletedThisMonth => 'Завершено в этом месяце';
  @override
  String get dashboardTotalContractAmount => 'Общая сумма договоров';
  @override
  String get dashboardPaymentsReceived => 'Полученные платежи';
  @override
  String get dashboardRemainingDebt => 'Долг клиентов';
  @override
  String get dashboardExpenses => 'Расходы';
  @override
  String get dashboardLowStock => 'Низкий остаток на складе';
  @override
  String get dashboardUpcomingDeliveries => 'Ближайшие доставки';
  @override
  String get dashboardMyOpenTasks => 'Мои задачи';
  @override
  String get dashboardTodayTasks => 'Задачи на сегодня';
  @override
  String get dashboardPaymentProgress => 'Уровень оплаты';
  @override
  String get dashboardModulesTitle => 'Модули';
  @override
  String get dashboardLoadError => 'Не удалось загрузить данные';

  @override
  String get clientsSearchHint => 'Поиск по имени или телефону';
  @override
  String get clientsEmptyTitle => 'Клиенты не найдены';
  @override
  String get clientsEmptyDescription =>
      'Нажмите кнопку ниже, чтобы добавить нового клиента';
  @override
  String get clientFormNameLabel => 'ФИО';
  @override
  String get clientFormPhoneLabel => 'Телефон';
  @override
  String get clientFormPhoneSecondaryLabel => 'Доп. телефон';
  @override
  String get clientFormWhatsappLabel => 'WhatsApp / Telegram';
  @override
  String get clientFormAddressLabel => 'Адрес';
  @override
  String get clientFormCityLabel => 'Город';
  @override
  String get clientFormSourceLabel => 'Источник заказа';
  @override
  String get clientFormNotesLabel => 'Примечание';
  @override
  String get clientFormResponsibleManagerLabel => 'Ответственный менеджер';
  @override
  String get clientEditTitle => 'Редактировать клиента';
  @override
  String get clientNewTitle => 'Новый клиент';
  @override
  String get clientDeleteConfirmTitle => 'Удалить клиента';
  @override
  String get clientDeleteConfirmBody =>
      'Вы уверены, что хотите удалить этого клиента? Это действие может восстановить директор';
  @override
  String get clientCreatedToast => 'Клиент добавлен';
  @override
  String get clientUpdatedToast => 'Клиент обновлён';
  @override
  String get clientDeletedToast => 'Клиент удалён';
  @override
  String get clientCompanyMissingError =>
      'Компания не определена. Войдите заново';
  @override
  String get clientNotFound => 'Клиент не найден';
  @override
  String get clientCallAction => 'Позвонить';
  @override
  String get clientWhatsappAction => 'WhatsApp';
  @override
  String get clientNoNotes => 'Нет примечаний';
  @override
  String get clientResponsibleManagerNone => 'Не назначен';

  @override
  String get orderSearchHint => 'Номер заказа, тип мебели или клиент';
  @override
  String get orderFilterAll => 'Все';
  @override
  String get orderStatusMeasurement => 'Замер';
  @override
  String get orderStatusAccepted => 'Принят';
  @override
  String get orderStatusInProgress => 'В работе';
  @override
  String get orderStatusReady => 'Заказ готов';
  @override
  String get orderStatusInstalled => 'Установлен';
  @override
  String get orderFormClientLabel => 'Клиент';
  @override
  String get orderFormSelectClient => 'Выбрать клиента';
  @override
  String get orderFormProductTypeLabel => 'Тип мебели';
  @override
  String get orderFormTotalAmountLabel => 'Общая сумма (₸)';
  @override
  String get orderFormMeasurementDateLabel => 'Дата замера';
  @override
  String get orderFormPlannedCompletionDateLabel => 'Срок готовности';
  @override
  String get orderFormResponsibleEmployeeLabel => 'Ответственный сотрудник';
  @override
  String get orderFormNotesLabel => 'Примечание';
  @override
  String get orderFormSelectDate => 'Выбрать дату';
  @override
  String get orderNewTitle => 'Новый заказ';
  @override
  String get orderEditTitle => 'Редактировать заказ';
  @override
  String get ordersEmptyTitle => 'Заказы не найдены';
  @override
  String get ordersEmptyDescription =>
      'Нажмите кнопку ниже, чтобы добавить новый заказ';
  @override
  String get orderPaidLabel => 'Оплачено';
  @override
  String get orderRemainingLabel => 'Остаток';
  @override
  String get orderPaymentProgressLabel => 'Процент оплаты';
  @override
  String get orderDeleteConfirmTitle => 'Удалить заказ';
  @override
  String get orderDeleteConfirmBody =>
      'Вы уверены, что хотите удалить этот заказ? Это действие может восстановить директор';
  @override
  String get orderCreatedToast => 'Заказ добавлен';
  @override
  String get orderUpdatedToast => 'Заказ обновлён';
  @override
  String get orderDeletedToast => 'Заказ удалён';
  @override
  String get orderStatusUpdatedToast => 'Статус заказа обновлён';
  @override
  String get orderNotFound => 'Заказ не найден';
  @override
  String get orderSelectClientTitle => 'Выбрать клиента';
  @override
  String get orderSelectEmployeeTitle => 'Выбрать сотрудника';
  @override
  String get orderNoEmployeeAssigned => 'Не назначен';
  @override
  String get orderChangeStatusTitle => 'Изменить статус';
  @override
  String get orderResponsibleEmployeeNone => 'Ответственный не назначен';

  @override
  String get paymentsSearchHint => 'Клиент, заказ или тип платежа';
  @override
  String get paymentMethodCash => 'Наличные';
  @override
  String get paymentMethodKaspi => 'Kaspi';
  @override
  String get paymentMethodBankTransfer => 'Банковский перевод';
  @override
  String get paymentMethodCard => 'Карта';
  @override
  String get paymentMethodOther => 'Другое';
  @override
  String get paymentFormAmountLabel => 'Сумма платежа (₸)';
  @override
  String get paymentFormDateLabel => 'Дата платежа';
  @override
  String get paymentFormMethodLabel => 'Тип платежа';
  @override
  String get paymentFormResponsibleEmployeeLabel => 'Ответственный за платёж';
  @override
  String get paymentFormCommentLabel => 'Примечание';
  @override
  String get paymentFormReceiptLabel => 'Чек / файл';
  @override
  String get paymentAttachReceipt => 'Прикрепить чек';
  @override
  String get paymentReceiptAttached => 'Чек прикреплён';
  @override
  String get paymentViewReceipt => 'Посмотреть чек';
  @override
  String get paymentNewTitle => 'Добавить платёж';
  @override
  String get paymentEditTitle => 'Редактировать платёж';
  @override
  String get paymentsEmptyTitle => 'Платежи не найдены';
  @override
  String get paymentsEmptyDescription =>
      'Перейдите на страницу заказа, чтобы добавить платёж';
  @override
  String get paymentCreatedToast => 'Платёж добавлен';
  @override
  String get paymentUpdatedToast => 'Платёж обновлён';
  @override
  String get paymentDeletedToast => 'Платёж удалён';
  @override
  String get paymentDeleteConfirmTitle => 'Удалить платёж';
  @override
  String get paymentDeleteConfirmBody =>
      'Вы уверены, что хотите удалить этот платёж? Остаток по заказу будет пересчитан';
  @override
  String get paymentFilterAllMethods => 'Все типы';
  @override
  String get paymentFilterDateFrom => 'С';
  @override
  String get paymentFilterDateTo => 'По';
  @override
  String get paymentFilterClear => 'Очистить';
  @override
  String get paymentHistoryTitle => 'История платежей';
  @override
  String get paymentMaxAmountHint => 'Максимум';
  @override
  String get paymentNotFound => 'Платёж не найден';
  @override
  String get paymentAmountExceedsRemaining => 'Сумма превышает остаток';

  @override
  String get employeesSearchHint => 'Имя, email или телефон';
  @override
  String get employeeFilterAllRoles => 'Все роли';
  @override
  String get employeeFilterActive => 'Активные';
  @override
  String get employeeFilterInactive => 'Неактивные';
  @override
  String get employeeFilterAllStatuses => 'Все статусы';
  @override
  String get employeeRoleDirector => 'Директор';
  @override
  String get employeeRoleManager => 'Менеджер';
  @override
  String get employeeRoleMeasurer => 'Замерщик';
  @override
  String get employeeRoleDesigner => 'Дизайнер';
  @override
  String get employeeRoleWorkshopManager => 'Начальник цеха';
  @override
  String get employeeRoleMaster => 'Мастер';
  @override
  String get employeeRoleAssistant => 'Помощник';
  @override
  String get employeeRoleInstaller => 'Монтажник';
  @override
  String get employeeRoleAccountant => 'Бухгалтер';
  @override
  String get employeeRoleWarehouse => 'Кладовщик';
  @override
  String get employeeRoleAdmin => 'Системный администратор';
  @override
  String get employeeFormFullNameLabel => 'ФИО';
  @override
  String get employeeFormPhoneLabel => 'Номер телефона';
  @override
  String get employeeFormEmailLabel => 'Email';
  @override
  String get employeeFormPasswordLabel => 'Пароль';
  @override
  String get employeeFormRoleLabel => 'Роль';
  @override
  String get employeeFormHireDateLabel => 'Дата приёма на работу';
  @override
  String get employeeFormSalaryTypeLabel => 'Тип зарплаты';
  @override
  String get employeeFormBaseSalaryLabel => 'Постоянный оклад (₸)';
  @override
  String get employeeFormBonusPercentLabel => 'Процент бонуса (%)';
  @override
  String get employeeFormStatusLabel => 'Статус сотрудника';
  @override
  String get employeeFormNotesLabel => 'Примечание';
  @override
  String get salaryTypeFixed => 'Постоянная';
  @override
  String get salaryTypePercentage => 'Процентная';
  @override
  String get employeeNewTitle => 'Добавить сотрудника';
  @override
  String get employeeEditTitle => 'Редактировать сотрудника';
  @override
  String get employeeMyProfileTitle => 'Мой профиль';
  @override
  String get employeesEmptyTitle => 'Сотрудники не найдены';
  @override
  String get employeesEmptyDescription =>
      'Нажмите кнопку ниже, чтобы добавить нового сотрудника';
  @override
  String get employeeCreatedToast => 'Сотрудник добавлен';
  @override
  String get employeeUpdatedToast => 'Сотрудник обновлён';
  @override
  String get employeeDeletedToast => 'Сотрудник удалён';
  @override
  String get employeeActivatedToast => 'Сотрудник активирован';
  @override
  String get employeeDeactivatedToast => 'Сотрудник деактивирован';
  @override
  String get employeeAvatarUpdatedToast => 'Аватар обновлён';
  @override
  String get employeeDeleteConfirmTitle => 'Удалить сотрудника';
  @override
  String get employeeDeleteConfirmBody =>
      'Вы уверены, что хотите удалить этого сотрудника? Это действие можно будет отменить позже';
  @override
  String get employeeDeactivateConfirmTitle => 'Деактивировать сотрудника';
  @override
  String get employeeDeactivateConfirmBody =>
      'Этот сотрудник не сможет войти в систему. Позже вы сможете снова его активировать';
  @override
  String get employeeNotFound => 'Сотрудник не найден';
  @override
  String get employeeFinancialHidden => 'Скрыто';
  @override
  String get employeeStatusActive => 'Активен';
  @override
  String get employeeStatusInactive => 'Неактивен';
  @override
  String get employeeSelectRoleTitle => 'Выбрать роль';
  @override
  String get employeeSelectSalaryTypeTitle => 'Выбрать тип зарплаты';
  @override
  String get employeeSelectDateTitle => 'Выбрать дату';
  @override
  String get employeeNoPhone => 'Телефон не указан';
  @override
  String get employeeNoHireDate => 'Дата не указана';
  @override
  String get employeeNoNotes => 'Нет примечаний';
  @override
  String get employeeChangeAvatar => 'Изменить аватар';
  @override
  String get employeeRolePurchaser => 'Менеджер по закупкам';

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
  String get partnerCategoryCanteen => 'Столовая';
  @override
  String get partnerCategoryOther => 'Другое';
  @override
  String get partnersSearchHint => 'Название, телефон или компания';
  @override
  String get partnerFilterAllCategories => 'Все категории';
  @override
  String get partnerFilterActive => 'Активные';
  @override
  String get partnerFilterInactive => 'Неактивные';
  @override
  String get partnerFilterAllStatuses => 'Все статусы';
  @override
  String get partnerSelectCategoryTitle => 'Выбрать категорию';
  @override
  String get partnerShowActiveAction => 'Показать активных';
  @override
  String get partnerShowTrashAction => 'Показать удалённых';
  @override
  String get partnerFormDisplayNameLabel => 'Название или ФИО';
  @override
  String get partnerFormCompanyNameLabel => 'Название компании';
  @override
  String get partnerFormCategoryLabel => 'Категория';
  @override
  String get partnerFormPhoneLabel => 'Номер телефона';
  @override
  String get partnerFormPhoneSecondaryLabel => 'Дополнительный телефон';
  @override
  String get partnerFormWhatsappLabel => 'Номер WhatsApp';
  @override
  String get partnerFormCityLabel => 'Город';
  @override
  String get partnerFormAddressLabel => 'Адрес';
  @override
  String get partnerFormContactPersonLabel => 'Контактное лицо';
  @override
  String get partnerFormTaxIdLabel => 'БИН/ИИН';
  @override
  String get partnerFormServiceDescriptionLabel => 'Описание услуги или товара';
  @override
  String get partnerFormPriceNoteLabel => 'Примечание о цене';
  @override
  String get partnerFormTrustRatingLabel => 'Рейтинг доверия';
  @override
  String get partnerFormLastWorkedAtLabel => 'Дата последней работы';
  @override
  String get partnerFormNotesLabel => 'Примечание';
  @override
  String get partnerFormStatusLabel => 'Статус';
  @override
  String get partnerFormBankDetailsLabel =>
      'Банковские или платёжные реквизиты';
  @override
  String get partnerFormBalanceLabel => 'Баланс долга/аванса';
  @override
  String get partnerTrustRatingUnset => 'Не указан';
  @override
  String get partnerNewTitle => 'Новый партнёр';
  @override
  String get partnerEditTitle => 'Редактировать партнёра';
  @override
  String get partnerCallAction => 'Позвонить';
  @override
  String get partnerWhatsappAction => 'WhatsApp';
  @override
  String get partnerOpenMapAction => 'Открыть на карте';
  @override
  String get partnerEditFinancialsAction => 'Изменить финансовые данные';
  @override
  String get partnerRestoreAction => 'Восстановить';
  @override
  String get partnerAddDocumentAction => 'Прикрепить документ';
  @override
  String get partnerCreatedToast => 'Партнёр добавлен';
  @override
  String get partnerUpdatedToast => 'Партнёр обновлён';
  @override
  String get partnerDeletedToast => 'Партнёр удалён';
  @override
  String get partnerRestoredToast => 'Партнёр восстановлен';
  @override
  String get partnerDocumentAddedToast => 'Документ прикреплён';
  @override
  String get partnerDocumentDeletedToast => 'Документ удалён';
  @override
  String get partnerDeleteConfirmTitle => 'Удалить партнёра';
  @override
  String get partnerDeleteConfirmBody =>
      'Удалить партнёра? Директор сможет восстановить эту запись.';
  @override
  String get partnersEmptyTitle => 'Партнёры не найдены';
  @override
  String get partnersEmptyDescription =>
      'Нажмите «+», чтобы добавить нового партнёра';
  @override
  String get partnersTrashEmptyTitle => 'Удалённых партнёров нет';
  @override
  String get partnersLoadError => 'Не удалось загрузить список партнёров';
  @override
  String get partnersLoadMoreAction => 'Загрузить ещё';
  @override
  String get partnerNotFound => 'Партнёр не найден';
  @override
  String get partnerStatusInactive => 'Неактивен';
  @override
  String get partnerDocumentsTitle => 'Документы';
  @override
  String get partnerDocumentsLoadError => 'Не удалось загрузить документы';
  @override
  String get partnerDocumentsEmpty => 'Документы ещё не прикреплены';

  // ---- analytics ----
  @override
  String get analyticsPeriodDay => 'День';
  @override
  String get analyticsPeriodWeek => 'Неделя';
  @override
  String get analyticsPeriodMonth => 'Месяц';
  @override
  String get analyticsPeriodYear => 'Год';
  @override
  String get analyticsSelectPeriodTitle => 'Выбрать период';
  @override
  String get analyticsPeriodComparisonNew => 'новое';
  @override
  String get analyticsOrdersByStatusTitle => 'Заказы по статусу';
  @override
  String get analyticsNoDataForPeriod => 'За этот период данных нет';
  @override
  String get analyticsPaymentMethodsTitle => 'Статистика по способам оплаты';
  @override
  String get analyticsEmployeeKpiTitle => 'KPI по сотрудникам';
  @override
  String get analyticsOrdersAssignedLabel => 'Назначенные заказы';
  @override
  String get analyticsOrdersCompletedLabel => 'Завершено';
  @override
  String get analyticsPaymentsRecordedLabel => 'Оформленные платежи';
  @override
  String get analyticsTopClientsTitle =>
      'Клиенты с наибольшим количеством заказов';
  @override
  String get analyticsOrdersCountSuffix => 'заказ(ов)';
  @override
  String get analyticsLoadError => 'Не удалось загрузить аналитику';
  @override
  String get analyticsOwnKpiOnlyNote =>
      'Вам доступны только ваши собственные показатели KPI';
  @override
  String get analyticsTurnover => 'Общий оборот';
  @override
  String get analyticsOrdersCount => 'Количество заказов';
  @override
  String get analyticsInstalledCount => 'Установленные заказы';
  @override
  String get analyticsNewClientsCount => 'Новые клиенты';
  @override
  String get analyticsAvgOrderAmount => 'Средняя сумма заказа';
  @override
  String get analyticsPaymentsReceived => 'Полученные платежи';
  @override
  String get analyticsRemainingDebt => 'Оставшийся долг';

  // ---- production ----
  @override
  String get productionNoMasterAssigned => 'Мастер не назначен';
  @override
  String get productionStageMovedToast => 'Этап изменён';
  @override
  String get productionColumnEmpty => 'Пусто';
  @override
  String get productionSelectMasterTitle => 'Выбрать мастера';
  @override
  String get productionMastersLoadError =>
      'Не удалось загрузить список мастеров';
  @override
  String get productionNoMastersAvailable => 'Нет доступных мастеров';
  @override
  String get productionSelectStageTitle => 'Выбрать этап';
  @override
  String get productionFilterAllStages => 'Все этапы';
  @override
  String get productionMaterialsTitle => 'Достаточность материалов';
  @override
  String get productionNoMaterialsReserved => 'Материалы не забронированы';
  @override
  String get productionPhotoAddedToast => 'Фото добавлено';
  @override
  String get productionPhotoDeletedToast => 'Фото удалено';
  @override
  String get productionPhotosTitle => 'Фотографии';
  @override
  String get productionAddPhotoAction => 'Прикрепить фото';
  @override
  String get productionNoPhotos => 'Фото ещё не прикреплены';
  @override
  String get productionTimeLogStartedToast => 'Таймер запущен';
  @override
  String get productionTimeLogStoppedToast => 'Таймер остановлен';
  @override
  String get productionTimeLogsTitle => 'Журналы времени';
  @override
  String get productionStopTimerAction => 'Остановить';
  @override
  String get productionStartTimerAction => 'Начать';
  @override
  String get productionNoTimeLogs => 'Журналов времени нет';
  @override
  String get productionTimeLogOngoing => 'в процессе';
  @override
  String get productionHistoryTitle => 'История производства';
  @override
  String get productionNoHistory => 'История пока пуста';
  @override
  String get productionQrTitle => 'QR-код';
  @override
  String get productionScanQrTitle => 'Сканировать QR-код';
  @override
  String get productionCameraUnavailable => 'Камера недоступна';
  @override
  String get productionSearchHint => 'Номер заказа, тип или клиент';
  @override
  String get productionLoadError => 'Не удалось загрузить очередь производства';
  @override
  String get productionQueueEmptyTitle => 'В производстве заказов нет';
  @override
  String get productionOrderDetailTitle => 'Детали производства';
  @override
  String get productionOrderNotFound => 'Заказ не найден';
  @override
  String get productionMasterAssignedToast => 'Мастер назначен';
  @override
  String get productionCurrentStageLabel => 'Текущий этап';
  @override
  String get productionMoveStageAction => 'Изменить этап';

  // ---- warehouse ----
  @override
  String get warehouseSearchHint => 'Название материала или barcode';
  @override
  String get warehouseLoadError => 'Не удалось загрузить данные склада';
  @override
  String get warehouseEmptyTitle => 'Материалы не найдены';
  @override
  String get warehouseFilterAllCategories => 'Все категории';
  @override
  String get warehouseLowStockFilterLabel => 'Только низкий остаток';
  @override
  String get warehouseTableColumnMaterial => 'Материал';
  @override
  String get warehouseTableColumnCategory => 'Категория';
  @override
  String get warehouseTableColumnAvailable => 'Доступно';
  @override
  String get warehouseTableColumnReserved => 'В резерве';
  @override
  String get warehouseTableColumnMin => 'Мин.';
  @override
  String get warehouseLowStockBadge => 'Низкий остаток';
  @override
  String get warehouseMaterialDetailTitle => 'Детали материала';
  @override
  String get warehouseAvailableLabel => 'Доступный остаток';
  @override
  String get warehouseReservedLabel => 'В резерве';
  @override
  String get warehouseMinQuantityLabel => 'Минимальный остаток';
  @override
  String get warehouseBarcodeLabel => 'Barcode';
  @override
  String get warehouseNoBarcode => 'Barcode не указан';
  @override
  String get warehousePreferredSupplierLabel => 'Основной поставщик';
  @override
  String get warehouseNoSupplier => 'Поставщик не назначен';
  @override
  String get warehouseContactSupplierAction => 'Связаться с поставщиком';
  @override
  String get warehouseCallAction => 'Позвонить';
  @override
  String get warehouseWhatsappAction => 'WhatsApp';
  @override
  String get warehouseReceiveAction => 'Поступление';
  @override
  String get warehouseIssueAction => 'Расход';
  @override
  String get warehouseReserveAction => 'Резервировать';
  @override
  String get warehouseHoldAction => 'Создать резерв';
  @override
  String get warehouseAddToCartAction => 'Добавить в корзину';
  @override
  String get warehouseBatchesTitle => 'Партии';
  @override
  String get warehouseNoBatches => 'Партий нет';
  @override
  String get warehouseBatchRemainingLabel => 'осталось';
  @override
  String get warehouseHoldsTitle => 'Резервы';
  @override
  String get warehouseNoHolds => 'Активных резервов нет';
  @override
  String get warehouseReleaseHoldAction => 'Снять резерв';
  @override
  String get warehouseHoldReleasedToast => 'Резерв снят';
  @override
  String get warehouseReceiveTitle => 'Зарегистрировать поступление';
  @override
  String get warehouseQuantityLabel => 'Количество';
  @override
  String get warehouseCostPerUnitLabel => 'Цена за единицу (тиын)';
  @override
  String get warehouseBatchNumberLabel => 'Номер партии';
  @override
  String get warehouseLocationLabel => 'Место на складе';
  @override
  String get warehouseSelectLocationTitle => 'Выберите место на складе';
  @override
  String get warehouseReceivedToast => 'Поступление зарегистрировано';
  @override
  String get warehouseQuantityRequiredError => 'Введите количество';
  @override
  String get warehouseReserveTitle => 'Резерв под заказ';
  @override
  String get warehouseOrderIdLabel => 'ID заказа';
  @override
  String get warehouseReservedToast => 'Материал зарезервирован';
  @override
  String get warehouseHoldTitle => 'Новый резерв';
  @override
  String get warehouseReasonLabel => 'Причина';
  @override
  String get warehouseHoldCreatedToast => 'Резерв создан';
  @override
  String get warehouseCartTitle => 'Корзина';
  @override
  String get warehouseCartEmpty => 'Корзина пуста';
  @override
  String get warehouseIssueConfirmAction => 'Подтвердить расход';
  @override
  String get warehouseIssuedToast => 'Расход зарегистрирован';
  @override
  String get warehouseScanTitle => 'Сканирование barcode / QR';
  @override
  String get warehouseScanNotFoundToast => 'Материал не найден';
  @override
  String get warehouseCameraUnavailable => 'Камера недоступна';
  @override
  String get warehouseSummaryTitle => 'Аналитика склада';
  @override
  String get warehouseMaterialsCountLabel => 'Виды материалов';
  @override
  String get warehouseLowStockCountLabel => 'Позиции с низким остатком';
  @override
  String get warehouseTotalValueLabel => 'Общая стоимость';

  // ---- purchases ----
  @override
  String get purchasesStatusDraft => 'Черновик';
  @override
  String get purchasesStatusApproved => 'Утверждён';
  @override
  String get purchasesStatusRejected => 'Отклонён';
  @override
  String get purchasesStatusDelivered => 'Доставлен';
  @override
  String get purchasesStatusReceived => 'Принят';
  @override
  String get purchasesStatusCancelled => 'Отменён';
  @override
  String get purchasesSearchHint => 'Номер заказа или поставщик';
  @override
  String get purchasesLoadError => 'Не удалось загрузить заказы на закупку';
  @override
  String get purchasesEmptyTitle => 'Заказы не найдены';
  @override
  String get purchasesFilterAllStatuses => 'Все статусы';
  @override
  String get purchasesSelectStatusTitle => 'Выберите статус';
  @override
  String get purchasesTableColumnNumber => 'Номер';
  @override
  String get purchasesTableColumnSupplier => 'Поставщик';
  @override
  String get purchasesTableColumnStatus => 'Статус';
  @override
  String get purchasesTableColumnTotal => 'Сумма';
  @override
  String get purchasesTableColumnExpectedDate => 'Ожидаемая поставка';
  @override
  String get purchasesCreateAction => 'Новый заказ';
  @override
  String get purchasesPendingBadge => 'В пути';
  @override
  String get purchasesDetailTitle => 'Заказ на закупку';
  @override
  String get purchasesOrderNotFound => 'Заказ не найден';
  @override
  String get purchasesResponsibleEmployeeLabel => 'Ответственный сотрудник';
  @override
  String get purchasesNoResponsibleEmployee => 'Ответственный не назначен';
  @override
  String get purchasesExpectedDeliveryLabel => 'Ожидаемая дата поставки';
  @override
  String get purchasesNoExpectedDelivery => 'Дата не указана';
  @override
  String get purchasesSubtotalLabel => 'Промежуточная сумма';
  @override
  String get purchasesDeliveryCostLabel => 'Стоимость доставки';
  @override
  String get purchasesVatLabel => 'НДС';
  @override
  String get purchasesDiscountLabel => 'Скидка';
  @override
  String get purchasesTotalLabel => 'Итоговая сумма';
  @override
  String get purchasesCommentLabel => 'Примечание';
  @override
  String get purchasesRejectionReasonLabel => 'Причина отказа';
  @override
  String get purchasesItemsTitle => 'Материалы';
  @override
  String get purchasesNoItems => 'Материалы не добавлены';
  @override
  String get purchasesApproveAction => 'Утвердить';
  @override
  String get purchasesRejectAction => 'Отклонить';
  @override
  String get purchasesDeliverAction => 'Отметить как доставлено';
  @override
  String get purchasesReceiveAction => 'Принять';
  @override
  String get purchasesCancelAction => 'Отменить заказ';
  @override
  String get purchasesEditAction => 'Изменить';
  @override
  String get purchasesApprovedToast => 'Заказ утверждён';
  @override
  String get purchasesRejectedToast => 'Заказ отклонён';
  @override
  String get purchasesDeliveredToast => 'Заказ отмечен как доставленный';
  @override
  String get purchasesReceivedToast => 'Заказ принят';
  @override
  String get purchasesCancelledToast => 'Заказ отменён';
  @override
  String get purchasesConfirmRejectTitle => 'Отклонить заказ';
  @override
  String get purchasesConfirmCancelTitle => 'Отменить заказ';
  @override
  String get purchasesReasonLabel => 'Причина';
  @override
  String get purchasesCreateTitle => 'Новый заказ на закупку';
  @override
  String get purchasesEditTitle => 'Изменить заказ';
  @override
  String get purchasesOrderNumberLabel => 'Номер заказа';
  @override
  String get purchasesOrderNumberRequiredError => 'Введите номер заказа';
  @override
  String get purchasesSupplierLabel => 'Поставщик';
  @override
  String get purchasesSupplierRequiredError => 'Выберите поставщика';
  @override
  String get purchasesSelectSupplierTitle => 'Выберите поставщика';
  @override
  String get purchasesSuppliersLoadError => 'Не удалось загрузить поставщиков';
  @override
  String get purchasesNoSuppliersAvailable => 'Поставщики не найдены';
  @override
  String get purchasesSelectEmployeeTitle => 'Выберите сотрудника';
  @override
  String get purchasesEmployeesLoadError => 'Не удалось загрузить сотрудников';
  @override
  String get purchasesNoEmployeesAvailable => 'Сотрудники не найдены';
  @override
  String get purchasesAddItemAction => 'Добавить материал';
  @override
  String get purchasesNoItemsAddedError => 'Добавьте хотя бы один материал';
  @override
  String get purchasesCreatedToast => 'Заказ создан';
  @override
  String get purchasesUpdatedToast => 'Заказ сохранён';
  @override
  String get purchasesSelectMaterialTitle => 'Выберите материал';
  @override
  String get purchasesMaterialsLoadError => 'Не удалось загрузить материалы';
  @override
  String get purchasesNoMaterialsAvailable => 'Материалы не найдены';
  @override
  String get purchasesQuantityLabel => 'Количество';
  @override
  String get purchasesUnitPriceLabel => 'Цена за единицу (тиын)';
  @override
  String get purchasesLocationLabel => 'Место на складе';
  @override
  String get purchasesReceiveConfirmTitle => 'Принять заказ';
  @override
  String get purchasesReceiveConfirmBody =>
      'Материалы будут приняты на склад, остатки обновятся. Продолжить?';
  @override
  String get purchasesLocationRequiredError =>
      'Укажите место на складе для каждого материала';
  @override
  String get purchasesPaymentsTitle => 'Платежи';
  @override
  String get purchasesRecordPaymentAction => 'Записать платёж';
  @override
  String get purchasesPaymentAmountLabel => 'Сумма платежа';
  @override
  String get purchasesPaymentMethodLabel => 'Способ оплаты';
  @override
  String get purchasesSelectMethodTitle => 'Выберите способ оплаты';
  @override
  String get purchasesPaymentDateLabel => 'Дата платежа';
  @override
  String get purchasesPaymentCommentLabel => 'Примечание';
  @override
  String get purchasesPaymentRecordedToast => 'Платёж записан';
  @override
  String get purchasesReversePaymentAction => 'Отменить платёж';
  @override
  String get purchasesPaymentReversedToast => 'Платёж отменён';
  @override
  String get purchasesReverseReasonLabel => 'Причина отмены';
  @override
  String get purchasesNoPayments => 'Платежей нет';
  @override
  String get purchasesInvoiceLabel => 'Счёт-фактура';
  @override
  String get purchasesAdvancePaymentLabel => 'Аванс (без счёта)';
  @override
  String get purchasesOutstandingBalanceLabel => 'Остаток долга';
  @override
  String get purchasesAdvanceBalanceLabel => 'Остаток аванса';
  @override
  String get purchasesInvoicesTitle => 'Счета-фактуры';
  @override
  String get purchasesNoInvoices => 'Счетов-фактур нет';
  @override
  String get purchasesInvoiceStatusUnpaid => 'Не оплачен';
  @override
  String get purchasesInvoiceStatusPartial => 'Частично оплачен';
  @override
  String get purchasesInvoiceStatusPaid => 'Оплачен';
  @override
  String get purchasesInvoiceAmountLabel => 'Сумма';
  @override
  String get purchasesInvoicePaidLabel => 'Оплачено';
  @override
  String get purchasesInvoiceDueDateLabel => 'Срок оплаты';
  @override
  String get purchasesAnalyticsTitle => 'Аналитика закупок';
  @override
  String get purchasesMonthlyPurchasesLabel => 'Закупки за месяц';
  @override
  String get purchasesTotalDebtLabel => 'Общий долг';
  @override
  String get purchasesTotalAdvanceLabel => 'Общий аванс';
  @override
  String get purchasesAvgUnitPriceLabel => 'Средняя цена закупки';
  @override
  String get purchasesTopMaterialsTitle => 'Самые закупаемые материалы';
  @override
  String get purchasesSupplierRatingsTitle => 'Рейтинг поставщиков';
  @override
  String get purchasesOnTimeRateLabel => 'Своевременная поставка';
  @override
  String get purchasesNoDataYet => 'Данных пока нет';
  @override
  String get purchasesPurchaseHistoryTitle => 'История закупок';
  @override
  String get purchasesNoPurchaseHistory => 'История закупок пуста';
  @override
  String get purchasesFilterAllSuppliers => 'Все поставщики';
  @override
  String get purchasesSupplierFilterLabel => 'Фильтр по поставщику';
  @override
  String get purchasesDateRangeLabel => 'Диапазон дат';
  @override
  String get purchasesClearFilterAction => 'Сбросить';
  @override
  String get purchasesLoadMoreAction => 'Показать ещё';
  @override
  String get purchasesCreatedAtLabel => 'Дата создания';
  @override
  String get purchasesSupplierBalanceTitle => 'Баланс поставщика';
  @override
  String get purchasesReceiveGuardMessage =>
      'Этот заказ нельзя принять — принимаются только заказы со статусом «Доставлен»';
  @override
  String get purchasesPayInvoiceAction => 'Оплатить этот счёт';

  // ---- company registration / onboarding ----
  @override
  String get companyRoleViewer => 'Наблюдатель';
  @override
  String get onboardingChoiceTitle => 'Выберите компанию';
  @override
  String get onboardingChoiceSubtitle =>
      'Создайте новую компанию или присоединитесь к существующей';
  @override
  String get onboardingCreateCompanyOption => 'Создать новую компанию';
  @override
  String get onboardingCreateCompanyDescription =>
      'Зарегистрируйте компанию и станьте её владельцем';
  @override
  String get onboardingJoinCompanyOption =>
      'Присоединиться к существующей компании';
  @override
  String get onboardingJoinCompanyDescription =>
      'Присоединитесь по коду компании или коду приглашения';
  @override
  String get onboardingRejectedBanner =>
      'Ваш предыдущий запрос был отклонён. Можно отправить новый запрос';
  @override
  String get createCompanyTitle => 'Новая компания';
  @override
  String get createCompanyNameLabel => 'Название компании';
  @override
  String get createCompanyNameRequiredError => 'Введите название компании';
  @override
  String get createCompanyPhoneLabel => 'Телефон';
  @override
  String get createCompanyEmailLabel => 'Email';
  @override
  String get createCompanyCityLabel => 'Город';
  @override
  String get createCompanyAddressLabel => 'Адрес';
  @override
  String get createCompanyIinBinLabel => 'ИИН/БИН';
  @override
  String get createCompanySubmitButton => 'Создать компанию';
  @override
  String get createCompanySuccessToast => 'Компания успешно создана';
  @override
  String get joinCompanyTitle => 'Присоединиться к компании';
  @override
  String get joinCompanyTabByCode => 'Код компании';
  @override
  String get joinCompanyTabByInvite => 'Код приглашения';
  @override
  String get joinCompanyCodeLabel => 'Код компании';
  @override
  String get joinCompanyCodeRequiredError => 'Введите код компании';
  @override
  String get joinCompanyInviteCodeLabel => 'Код приглашения';
  @override
  String get joinCompanyInviteCodeRequiredError => 'Введите код приглашения';
  @override
  String get joinCompanyRoleLabel => 'Желаемая роль';
  @override
  String get joinCompanyRoleRequiredError => 'Выберите роль';
  @override
  String get joinCompanySelectRoleTitle => 'Выберите роль';
  @override
  String get joinCompanyMessageLabel => 'Короткое сообщение (необязательно)';
  @override
  String get joinCompanySubmitButton => 'Отправить запрос';
  @override
  String get joinCompanyAcceptInviteButton => 'Принять приглашение';
  @override
  String get joinCompanyRequestSentToast => 'Запрос отправлен';
  @override
  String get joinCompanyInviteAcceptedToast => 'Вы присоединились к компании';
  @override
  String get joinCompanyScanQrAction => 'Сканировать QR-код';
  @override
  String get waitingApprovalTitle => 'Ожидание подтверждения';
  @override
  String get waitingApprovalCompanyLabel => 'Компания';
  @override
  String get waitingApprovalRoleLabel => 'Запрошенная роль';
  @override
  String get waitingApprovalSubmittedLabel => 'Дата отправки';
  @override
  String get waitingApprovalStatusPending => 'На рассмотрении';
  @override
  String get waitingApprovalStatusRejected => 'Отклонено';
  @override
  String get waitingApprovalRejectionReasonLabel => 'Причина';
  @override
  String get waitingApprovalWithdrawAction => 'Отозвать запрос';
  @override
  String get waitingApprovalWithdrawConfirmTitle => 'Отозвать запрос?';
  @override
  String get waitingApprovalWithdrawnToast => 'Запрос отозван';
  @override
  String get waitingApprovalTryAgainAction => 'Отправить запрос снова';
  @override
  String get waitingApprovalEmptyTitle => 'Запрос не найден';
  @override
  String get accessBlockedSuspendedTitle => 'Аккаунт временно приостановлен';
  @override
  String get accessBlockedSuspendedMessage =>
      'Обратитесь к директору или повторите попытку позже';
  @override
  String get accessBlockedCompanyInactiveTitle => 'Компания неактивна';
  @override
  String get accessBlockedCompanyInactiveMessage =>
      'Доступ вашей компании временно ограничен. Обратитесь к администратору';
  @override
  String get accessBlockedSignOutAction => 'Выйти';
  @override
  String get companyRequestsTitle => 'Запросы на присоединение';
  @override
  String get companyRequestsEmptyTitle => 'Нет ожидающих запросов';
  @override
  String get companyRequestsEmptyDescription =>
      'Новые запросы на присоединение появятся здесь';
  @override
  String get companyRequestsApproveAction => 'Одобрить';
  @override
  String get companyRequestsRejectAction => 'Отклонить';
  @override
  String get companyRequestsChangeRoleAction => 'Изменить роль';
  @override
  String get companyRequestsApprovedToast => 'Запрос одобрен';
  @override
  String get companyRequestsRejectedToast => 'Запрос отклонён';
  @override
  String get companyRequestsRejectReasonLabel =>
      'Причина отказа (необязательно)';
  @override
  String get companyRequestsRequestedRoleLabel => 'Запрошенная роль';
  @override
  String get companyRequestsMessageLabel => 'Сообщение';
  @override
  String get companyRequestsInviteAction => 'Пригласить сотрудника';
  @override
  String get companyRequestsMembersAction => 'Участники компании';
  @override
  String get companyInviteTitle => 'Пригласить сотрудника';
  @override
  String get companyInviteRoleLabel => 'Роль';
  @override
  String get companyInviteMaxUsesLabel => 'Количество использований';
  @override
  String get companyInviteExpiresLabel => 'Срок действия';
  @override
  String get companyInviteGenerateAction => 'Создать код приглашения';
  @override
  String get companyInviteCodeLabel => 'Код приглашения';
  @override
  String get companyInviteCopyAction => 'Копировать';
  @override
  String get companyInviteCopiedToast => 'Код скопирован';
  @override
  String get companyInviteEmailNote =>
      'Отправьте код сотруднику самостоятельно (автоматическая отправка по email пока не подключена)';
  @override
  String get companyMembersTitle => 'Участники компании';
  @override
  String get companyMembersEmptyTitle => 'Участники не найдены';
  @override
  String get companyMembersRoleLabel => 'Роль';

  // ---- company settings & subscription (Stage 3) ----
  @override
  String get settingsMenuCompany => 'Компания';
  @override
  String get settingsMenuSubscription => 'Подписка';
  @override
  String get settingsMenuBilling => 'История платежей';
  @override
  String get companySettingsTitle => 'Настройки компании';
  @override
  String get companySettingsSavedToast => 'Настройки сохранены';
  @override
  String get companySettingsLogoLabel => 'Логотип (ссылка на изображение)';
  @override
  String get companySettingsWebsiteLabel => 'Веб-сайт';
  @override
  String get companySettingsTimezoneLabel => 'Часовой пояс';
  @override
  String get companySettingsCurrencyLabel => 'Валюта';
  @override
  String get companySettingsWorkingHoursLabel => 'Рабочие часы';
  @override
  String get companySettingsDescriptionLabel => 'Описание';
  @override
  String get subscriptionTitle => 'Подписка';
  @override
  String get subscriptionPlansTitle => 'Тарифы';
  @override
  String get subscriptionContactSales => 'Свяжитесь с отделом продаж';
  @override
  String get subscriptionMaxEmployeesLabel => 'Максимум сотрудников';
  @override
  String get subscriptionMaxStorageLabel => 'Максимум хранилища';
  @override
  String get subscriptionUnlimitedLabel => 'Без ограничений';
  @override
  String get subscriptionPerMonthLabel => '/ мес';
  @override
  String get subscriptionCurrentPlanBadge => 'Текущий тариф';
  @override
  String get subscriptionTrialStatusLabel => 'Пробный период';
  @override
  String get subscriptionTrialActiveValue => 'Активен';
  @override
  String get subscriptionStartDateLabel => 'Дата начала';
  @override
  String get subscriptionEndDateLabel => 'Дата окончания';
  @override
  String get subscriptionRemainingDaysLabel => 'Осталось дней';
  @override
  String get subscriptionNextPaymentLabel => 'Дата следующего платежа';
  @override
  String get subscriptionCompanyStatusLabel => 'Статус компании';
  @override
  String get subscriptionCompanyActiveValue => 'Активна';
  @override
  String get subscriptionCompanyInactiveValue => 'Неактивна';
  @override
  String get subscriptionActiveUsersLabel => 'Активные пользователи';
  @override
  String get subscriptionExpiredTitle => 'Срок подписки истёк';
  @override
  String get subscriptionExpiredMessage =>
      'Обновите подписку, чтобы получить доступ к этому модулю';
  @override
  String get subscriptionExpiredRenewAction => 'Обновить подписку';
  @override
  String get billingTitle => 'История платежей';
  @override
  String get billingNoHistoryTitle => 'История платежей отсутствует';
  @override
  String get billingNextChargeLabel => 'Следующий платёж';
  @override
  String get billingContactSalesDescription =>
      'Уточните цену для этого тарифа у отдела продаж';

  // ---- audit log (Stage 4 Part 3) ----
  @override
  String get settingsMenuAuditLog => 'Журнал аудита';
  @override
  String get auditLogTitle => 'Журнал аудита';
  @override
  String get auditLogFiltersTitle => 'Фильтры';
  @override
  String get auditLogDateLabel => 'Дата';
  @override
  String get auditLogAllDatesLabel => 'Все даты';
  @override
  String get auditLogModuleLabel => 'Модуль';
  @override
  String get auditLogAllModulesLabel => 'Все модули';
  @override
  String get auditLogActionLabel => 'Действие';
  @override
  String get auditLogAllActionsLabel => 'Все действия';
  @override
  String get auditLogEmployeeLabel => 'Сотрудник';
  @override
  String get auditLogAllEmployeesLabel => 'Все сотрудники';
  @override
  String get auditLogClearFiltersAction => 'Очистить фильтры';
  @override
  String get auditLogDetailTitle => 'Запись аудита';
  @override
  String get auditLogEntityIdLabel => 'ID записи';
  @override
  String get auditLogBeforeLabel => 'До';
  @override
  String get auditLogAfterLabel => 'После';

  // ---- generic record-not-found (deep-link fallback) ----
  @override
  String get recordNotFoundTitle => 'Запись не найдена';
  @override
  String get recordNotFoundDescription =>
      'Эта запись удалена или ссылка неверна';
  @override
  String get recordNotFoundBackAction => 'Вернуться к списку';

  // ---- offline / connectivity (Stage 4 Part 7) ----
  @override
  String get offlineBannerMessage =>
      'Нет соединения. Показаны последние известные данные';

  // ---- notifications (Stage 4 Part 2's UI) ----
  @override
  String get notificationsTitle => 'Уведомления';
  @override
  String get notificationsEmptyTitle => 'Уведомлений нет';
  @override
  String get notificationsEmptyDescription =>
      'Новые уведомления появятся здесь';
  @override
  String get notificationsMarkAllReadAction => 'Отметить все как прочитанные';
}
