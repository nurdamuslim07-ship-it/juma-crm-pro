import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/locale_provider.dart';

final measurementStringsProvider = Provider(
  (ref) => MeasurementStrings(ref.watch(localeProvider) == AppLocale.ru),
);

class MeasurementStrings {
  const MeasurementStrings(this.ru);
  final bool ru;
  String get title => ru ? 'Замеры' : 'Өлшеулер';
  String get add => ru ? 'Новый замер' : 'Жаңа өлшеу';
  String get sheet => ru ? 'Лист замера' : 'Өлшеу парағы';
  String get search => ru ? 'Клиент или адрес' : 'Клиент немесе мекенжай';
  String get empty => ru ? 'Замеров пока нет' : 'Әзірге өлшеулер жоқ';
  String get noResults => ru ? 'Ничего не найдено' : 'Ештеңе табылмады';
  String get client => ru ? 'Выберите клиента' : 'Клиентті таңдаңыз';
  String get address => ru ? 'Адрес' : 'Мекенжай';
  String get material => ru ? 'Материал' : 'Материал';
  String get product => ru ? 'Тип мебели' : 'Жиһаз түрі';
  String get width => ru ? 'Ширина, мм' : 'Ені, мм';
  String get height => ru ? 'Высота, мм' : 'Биіктігі, мм';
  String get depth => ru ? 'Глубина, мм' : 'Тереңдігі, мм';
  String get amount =>
      ru ? 'Предварительная стоимость, ₸' : 'Алдын ала құны, ₸';
  String get notes => ru ? 'Примечание' : 'Ескертпе';
  String get photo => ru ? 'Добавить фото и размеры' : 'Фото және өлшем қосу';
  String get annotate => ru
      ? 'Проведите по фото или нажмите две точки, затем введите размер'
      : 'Фотоға сызыңыз немесе екі нүктені басып, өлшемді енгізіңіз';
  String get arrow => ru ? 'Стрелка' : 'Жебе';
  String get arrowLabel => ru ? 'Размер / подпись' : 'Өлшем / жазу';
  String get undo =>
      ru ? 'Убрать последнюю стрелку' : 'Соңғы жебені алып тастау';
  String get save => ru ? 'Сохранить' : 'Сақтау';
  String get saved => ru ? 'Сохранено' : 'Сақталды';
  String get order => ru ? 'Преобразовать в заказ' : 'Тапсырысқа айналдыру';
  String get openOrder => ru ? 'Открыть заказ' : 'Тапсырысты ашу';
  String get error => ru
      ? 'Не удалось выполнить действие. Проверьте соединение и повторите.'
      : 'Әрекет орындалмады. Байланысты тексеріп, қайталаңыз.';
  String get required => ru ? 'Заполните поле' : 'Өрісті толтырыңыз';
  String get positive =>
      ru ? 'Введите число больше нуля' : 'Нөлден үлкен сан енгізіңіз';
  String get priceError => ru
      ? 'Введите сумму, не меньше нуля (до 2 знаков после запятой)'
      : 'Нөлден кем емес соманы енгізіңіз (үтірден кейін 2 санға дейін)';
  String get retry => ru ? 'Повторить' : 'Қайталау';
  String get photoLimit => ru
      ? 'Выберите фото размером до 10 МБ'
      : '10 МБ-тан аспайтын фото таңдаңыз';
  String get photos => ru ? 'Фотографии' : 'Фотолар';
  String get addPhotos => ru ? 'Добавить фотографии' : 'Фотолар қосу';
  String get deletePhoto => ru ? 'Удалить фото' : 'Фотоны өшіру';
  String get restorePhoto => ru ? 'Вернуть фото' : 'Фотоны қайтару';
  String get photoRemoved =>
      ru ? 'Фото убрано из замера' : 'Фото өлшеуден алынды';
  String get photoSaveHint => ru
      ? 'Добавление и удаление фото применяются после сохранения.'
      : 'Фото қосу мен өшіру «Сақтау» басылғанда орындалады.';
  String get cleanupError => ru
      ? 'Замер сохранён, но удаление файла из хранилища не завершено.'
      : 'Өлшеу сақталды, бірақ файлды қоймадан өшіру аяқталмады.';
  String get roomPlan => ru ? 'План помещения' : 'Бөлме жоспары';
  String get planHint => ru
      ? 'Нажимайте по углам комнаты по порядку. Сетка — 1 м, шаг — 0,1 м. Для точных размеров создайте прямоугольник.'
      : 'Бөлменің бұрыштарын ретімен басыңыз. Тор — 1 м, қадам — 0,1 м. Нақты өлшем үшін тіктөртбұрыш жасаңыз.';
  String get rectangle => ru ? 'Прямоугольник' : 'Тіктөртбұрыш';
  String get roomWidth => ru ? 'Длина, м' : 'Ұзындығы, м';
  String get roomDepth => ru ? 'Ширина, м' : 'Ені, м';
  String get roomRange => ru
      ? 'Введите размеры от 0 до 50 м'
      : '0-ден үлкен, 50 м-ге дейінгі өлшем енгізіңіз';
  String get area => ru ? 'Площадь' : 'Ауданы';
  String get perimeter => ru ? 'Периметр' : 'Периметр';
  String get invalidPlan => ru
      ? 'Нужно не менее 3 углов без пересечения стен'
      : 'Қабырғалары қиылыспайтын кемінде 3 бұрыш қажет';
  String get undoPoint => ru ? 'Убрать угол' : 'Бұрышты қайтару';
  String get exportPdf => ru ? 'Экспорт PDF' : 'PDF шығару';
}
