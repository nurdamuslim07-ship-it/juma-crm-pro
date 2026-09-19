import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/locale_provider.dart';

final workflowStringsProvider = Provider(
  (ref) => WorkflowStrings(ref.watch(localeProvider) == AppLocale.ru),
);

class WorkflowStrings {
  const WorkflowStrings(this.ru);
  final bool ru;
  static const stages = [
    'measurement',
    'design',
    'contract',
    'advance',
    'cutting',
    'edge_banding',
    'assembly',
    'quality',
    'delivery',
    'installation',
    'completed',
  ];
  String stage(String value) {
    final i = stages.indexOf(value);
    if (i < 0) return value;
    return (ru
        ? [
            'Замер',
            'Согласование проекта',
            'Договор',
            'Аванс',
            'Раскрой',
            'Кромкование',
            'Сборка',
            'Контроль качества',
            'Доставка',
            'Монтаж',
            'Завершён',
          ]
        : [
            'Өлшеу',
            'Жобаны келісу',
            'Шарт',
            'Аванс',
            'Кесу',
            'Жиектеу',
            'Құрастыру',
            'Сапаны тексеру',
            'Жеткізу',
            'Орнату',
            'Аяқталды',
          ])[i];
  }

  String get title =>
      ru ? 'Этапы и связь с клиентом' : 'Кезеңдер және клиентпен байланыс';
  String get consent => ru
      ? 'Клиент согласился на уведомления WhatsApp'
      : 'Клиент WhatsApp хабарламаларына келісім берді';
  String get source =>
      ru ? 'Где и когда получено согласие' : 'Келісім қайда және қашан алынды';
  String get save => ru ? 'Сохранить' : 'Сақтау';
  String get error => ru
      ? 'Не удалось выполнить действие. Проверьте данные и права доступа.'
      : 'Әрекет орындалмады. Мәліметтер мен қолжетімділік құқығын тексеріңіз.';
  String get history => ru ? 'История этапов' : 'Кезеңдер тарихы';
  String get messages => ru ? 'Сообщения WhatsApp' : 'WhatsApp хабарламалары';
  String get setup => ru
      ? 'Автоотправка требует подключения WhatsApp Business Platform. До подключения сообщения остаются в очереди.'
      : 'Автоматты жіберу үшін WhatsApp Business Platform қосылуы қажет. Қосылғанша хабарламалар кезекте тұрады.';
  String get contracts => ru ? 'Договоры' : 'Шарттар';
  String get create => ru ? 'Подготовить договор' : 'Шарт дайындау';
  String get pdf => ru ? 'Открыть PDF' : 'PDF ашу';
  String get approve =>
      ru ? 'Проверено — в очередь WhatsApp' : 'Тексерілді — WhatsApp кезегіне';
  String get approved =>
      ru ? 'В очереди / одобрен' : 'Кезекке қойылды / бекітілді';
  String get draft => ru ? 'Проект договора' : 'Шарт жобасы';
  String get hint => ru
      ? 'Заполните и проверьте условия. Сохранение и отправка не означают подписание клиентом.'
      : 'Шарттарды толтырып, тексеріңіз. Сақтау мен жіберу клиенттің қол қойғанын білдірмейді.';
  String get company => ru
      ? 'Исполнитель: название и реквизиты'
      : 'Орындаушы: атауы мен деректемелері';
  String get client => ru ? 'Заказчик' : 'Тапсырыс беруші';
  String get product =>
      ru ? 'Изделие, материал и размеры' : 'Бұйым, материал және өлшемдер';
  String get amount => ru ? 'Стоимость, ₸' : 'Құны, ₸';
  String get payment => ru ? 'Условия оплаты' : 'Төлем тәртібі';
  String get deadline =>
      ru ? 'Срок изготовления и монтажа' : 'Дайындау және орнату мерзімі';
  String get warranty => ru ? 'Условия гарантии' : 'Кепілдік шарттары';
  String get terms => ru ? 'Дополнительные условия' : 'Қосымша шарттар';
  String get required => ru ? 'Заполните поле' : 'Өрісті толтырыңыз';
  String get preview => ru ? 'Предпросмотр PDF' : 'PDF алдын ала қарау';
  String get saved => ru ? 'Сохранено' : 'Сақталды';
  String get empty => ru ? 'Пока нет записей' : 'Әзірге жазба жоқ';
  String status(String value) =>
      (ru
          ? {
              'queued': 'В очереди',
              'sending': 'Отправляется',
              'sent': 'Отправлено',
              'delivered': 'Доставлено',
              'read': 'Прочитано',
              'failed': 'Ошибка',
              'unknown': 'Нужна проверка отправки',
              'skipped': 'Не отправлено',
            }
          : {
              'queued': 'Кезекте',
              'sending': 'Жіберілуде',
              'sent': 'Жіберілді',
              'delivered': 'Жеткізілді',
              'read': 'Оқылды',
              'failed': 'Қате',
              'unknown': 'Жіберілуін тексеру керек',
              'skipped': 'Жіберілмеді',
            })[value] ??
      value;
  String get tracking => ru ? 'Создать личную ссылку' : 'Жеке сілтеме жасау';
  String get trackingHint => ru
      ? 'Ссылка скопирована. Срок — 90 дней. Предыдущая ссылка отозвана.'
      : 'Сілтеме көшірілді. Мерзімі — 90 күн. Бұрынғы сілтеме тоқтатылды.';
}
