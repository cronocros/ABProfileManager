-- ABPM_ruRU_Final.lua
-- Clean ruRU localization extension for ABProfileManager.
-- Load after Locale.lua, Locale_Additions.lua, DB.lua and UI/ConfigPanel.lua.
-- This file intentionally avoids UIParent scanning and global GameTooltip hooks.

local _, ns = ...

if ns.ABPM_RURU_FINAL_LOADED then
  return
end
ns.ABPM_RURU_FINAL_LOADED = true

local RURU = {}
ns.ABPM_RURU = RURU

-- -----------------------------------------------------------------------------
-- 1. Language bootstrap and fallback
-- -----------------------------------------------------------------------------
local Constants = ns.Constants or {}
ns.Constants = Constants
Constants.LANGUAGE = Constants.LANGUAGE or {}
Constants.LANGUAGE.ENGLISH = Constants.LANGUAGE.ENGLISH or "enUS"
Constants.LANGUAGE.KOREAN = Constants.LANGUAGE.KOREAN or "koKR"
Constants.LANGUAGE.RUSSIAN = "ruRU"
Constants.DEFAULT_LANGUAGE = Constants.DEFAULT_LANGUAGE or "enUS"

local SUPPORTED_LANGUAGES = {
  enUS = true,
  koKR = true,
  ruRU = true,
}

local CLIENT_LOCALE_FALLBACKS = {
  enUS = "enUS",
  enGB = "enUS",
  frFR = "enUS",
  deDE = "enUS",
  esES = "enUS",
  esMX = "enUS",
  ptBR = "enUS",
  itIT = "enUS",
  ruRU = "ruRU",
  koKR = "koKR",
  zhCN = "koKR",
  zhTW = "koKR",
}

Constants.SUPPORTED_LANGUAGES = Constants.SUPPORTED_LANGUAGES or {}
for language in pairs(SUPPORTED_LANGUAGES) do
  Constants.SUPPORTED_LANGUAGES[language] = true
end
Constants.LOCALE_FALLBACKS = Constants.LOCALE_FALLBACKS or CLIENT_LOCALE_FALLBACKS

local function getClientDefaultLanguage()
  local clientLocale = type(GetLocale) == "function" and GetLocale() or "enUS"
  return CLIENT_LOCALE_FALLBACKS[clientLocale] or "enUS"
end

local function normalizeLanguage(language)
  if SUPPORTED_LANGUAGES[language] then
    return language
  end
  return getClientDefaultLanguage()
end

local function getAddonLanguage()
  if ns.DB and type(ns.DB.GetLanguage) == "function" then
    local ok, language = pcall(ns.DB.GetLanguage, ns.DB)
    if ok and type(language) == "string" then
      return normalizeLanguage(language)
    end
  end
  return getClientDefaultLanguage()
end

local function isRuRU()
  return getAddonLanguage() == "ruRU"
end

RURU.GetClientDefaultLanguage = getClientDefaultLanguage
RURU.NormalizeLanguage = normalizeLanguage
RURU.GetLanguage = getAddonLanguage
RURU.IsRuRU = isRuRU

-- -----------------------------------------------------------------------------
-- 2. Locale data
-- -----------------------------------------------------------------------------
local LOCALE_STRINGS_RURU = {
  ["action_bar_number"] = "Панель",
  ["action_bar_range"] = "Диапазон панелей",
  ["action_bar_set"] = "Номера панелей",
  ["action_bar_set_hint"] = "Например: 1, 3, 9",
  ["action_bars_title"] = "Панели действий",
  ["action_mode_bar"] = "Одна панель",
  ["action_mode_bar_desc"] = "Применить или очистить одну полную панель действий.",
  ["action_mode_bar_range"] = "Диапазон панелей",
  ["action_mode_bar_range_desc"] = "Применить или очистить несколько панелей подряд.",
  ["action_mode_bar_set"] = "Выбранные панели",
  ["action_mode_bar_set_desc"] = "Применить или очистить только выбранные номера панелей.",
  ["action_mode_full"] = "Все",
  ["action_mode_full_desc"] = "Применить или очистить все отслеживаемые ячейки панелей действий.",
  ["action_mode_full_inline"] = "Этот режим затрагивает все отслеживаемые ячейки панелей действий.",
  ["action_mode_slot_range"] = "Диапазон ячеек",
  ["action_mode_slot_range_desc"] = "Применить или очистить только указанные номера ячеек.",
  ["action_scope_flow"] = "1. Выберите диапазон -> 2. Проверьте сводку -> 3.\nСравните или выполните синхронизацию",
  ["action_scope_hint"] = "Выберите, какую часть панелей действий применить или очистить.\n(Панель 9 — страница полёта.)",
  ["action_scope_title"] = "Выбор диапазона применения",
  ["action_slot_range"] = "Диапазон ячеек",
  ["apply_scope_none"] = "Текущий диапазон применения: не задан",
  ["apply_scope_selected"] = "Текущий диапазон применения: %s",
  ["apply_selected"] = "Применить выбранный шаблон",
  ["apply_selected_source"] = "Применить шаблон\nк панелям",
  ["bar_name_flight"] = "Панель полёта",
  ["bar_name_generic"] = "Панель %d",
  ["bis_all_specs"] = "Все специализации",
  ["bis_all_specs_hint"] = "Текущая специализация класса остаётся на левой вкладке, другие классы и специализации можно выбрать здесь.",
  ["bis_basis_crafted"] = "База/5 звёзд",
  ["bis_basis_mplus"] = "+2",
  ["bis_basis_raid"] = "Обычный",
  ["bis_basis_tier"] = "Рейд/катализатор",
  ["bis_dungeon_algethar_academy"] = "Академия Алгет'ар",
  ["bis_dungeon_magisters_terrace"] = "Терраса Магистров",
  ["bis_dungeon_maisara_caverns"] = "Пещеры Майсары",
  ["bis_dungeon_nexus_point_xenas"] = "Точка Нексуса Ксенас",
  ["bis_dungeon_pit_of_saron"] = "Яма Сарона",
  ["bis_dungeon_seat_of_the_triumvirate"] = "Престол Триумвирата",
  ["bis_dungeon_skyreach"] = "Небесный Путь",
  ["bis_dungeon_windrunner_spire"] = "Шпиль Ветрокрылых",
  ["bis_note_alt"] = "Замена",
  ["bis_note_bis"] = "BIS",
  ["bis_note_rank"] = "№%d",
  ["bis_note_third"] = "3-й вар.",
  ["bis_overlay_avg_label"] = "Уровень предметов: %s",
  ["bis_overlay_hint"] = "(размер меняется колёсиком мыши)",
  ["bis_overlay_item_tooltip"] = "Предмет",
  ["bis_overlay_item_tooltip_hint"] = "Создаёт предпросмотр Myth 1/6 272 из встроенного селектора, сохраняет его один раз и повторно использует подсказки и оценки.",
  ["bis_overlay_no_data"] = "Для выбранной специализации нет BIS-данных.",
  ["bis_overlay_notice"] = "Только справочно. Проверяйте предметы в игре.",
  ["bis_overlay_title"] = "Каталог BIS-экипировки",
  ["bis_source_crafted"] = "Изготовление",
  ["bis_source_mplus"] = "M+",
  ["bis_source_raid"] = "Рейд",
  ["bis_source_tier"] = "Тир",
  ["bis_tooltip_acquisition"] = "Получение",
  ["bis_tooltip_base_item_level_warning"] = "Уровень предмета в подсказке может быть исходным уровнем добычи, а не скорректированным уровнем текущего сезона.",
  ["bis_tooltip_basis"] = "Основа",
  ["bis_tooltip_boss"] = "Босс",
  ["bis_tooltip_crafted_fallback"] = "Для изготовленных предметов нужны качество и контекст украшения, поэтому показан только уровень изготовления текущего сезона.",
  ["bis_tooltip_current_season"] = "Предпросмотр предмета 1-го сезона Midnight",
  ["bis_tooltip_dungeon"] = "Подземелье",
  ["bis_tooltip_end_of_run"] = "Награда за прохождение",
  ["bis_tooltip_item_level_scaled"] = "Диапазон награды текущего сезона за прохождение: %d-%d",
  ["bis_tooltip_method"] = "Способ",
  ["bis_tooltip_open_journal"] = "Нажмите, чтобы открыть соответствующий бой или подземелье в Атласе приключений.",
  ["bis_tooltip_open_journal_missing"] = "ID этого подземелья для Атласа приключений ещё не подтверждён.",
  ["bis_tooltip_overall_rank"] = "Общий ранг",
  ["bis_tooltip_preview_fallback"] = "Для этого предмета из возвращённого подземелья данные предпросмотра Blizzard нестабильны, поэтому показана только сезонная информация награды.",
  ["bis_tooltip_preview_key"] = "Статы и уровень предмета для награды текущего сезона за ключ +%d.",
  ["bis_tooltip_raid"] = "Рейд",
  ["bis_tooltip_raid_fallback"] = "Для этого рейдового предмета не удалось безопасно создать ссылку предпросмотра 1-го сезона, поэтому показан только диапазон уровня предметов рейда текущего сезона.",
  ["bis_tooltip_raid_preview"] = "Этот рейдовый предмет показан по предпросмотру рейда текущего сезона в Атласе приключений.",
  ["bis_tooltip_rank"] = "Приоритет",
  ["bis_tooltip_slot"] = "Ячейка",
  ["bis_tooltip_source"] = "Источник",
  ["bis_tooltip_source_rank"] = "Ранг источника",
  ["bis_tooltip_tier_fallback"] = "Для комплектных предметов нужен контекст рейда или катализатора, поэтому показан только диапазон уровня предметов рейда текущего сезона.",
  ["bis_tooltip_vault"] = "Великое хранилище",
  ["clear_all_bars"] = "Очистить все панели действий",
  ["clear_before_apply"] = "Очистить целевые ячейки перед применением",
  ["clear_selected_range"] = "Очистить диапазон\nпанелей",
  ["combat_lockdown_active"] = "Во время боя защищённые панели действий нельзя изменять.",
  ["compare_action_empty"] = "(пусто)",
  ["compare_action_unknown"] = "Неизвестное действие",
  ["compare_completed"] = "[Сравнение завершено]\n- Отличающихся ячеек: %d",
  ["compare_no_difference"] = "[Сравнение]\n- Различий в выбранном диапазоне не найдено.",
  ["compare_none_text"] = "[Сравнение]\n- Нажмите сравнение, чтобы проверить текущие панели относительно выбранного шаблона.",
  ["compare_preview_header"] = "[Предпросмотр различий]",
  ["compare_preview_more"] = "- ...и ещё %d различий",
  ["compare_refresh_button"] = "Сравнить панели\n(текущие <-> шаблон)",
  ["compare_row_changed"] = "- %s: сейчас %s -> шаблон %s",
  ["compare_row_extra"] = "- %s: сейчас %s, в шаблоне пусто",
  ["compare_row_missing"] = "- %s: сейчас пусто, в шаблоне %s",
  ["compare_summary_changed"] = "- Заполнено в обоих, но отличается: %d",
  ["compare_summary_extra"] = "- Сейчас заполнено, в шаблоне пусто: %d",
  ["compare_summary_missing"] = "- Сейчас пусто, в шаблоне заполнено: %d",
  ["compare_summary_range"] = "- Диапазон: %s",
  ["compare_summary_same"] = "- Совпадают: %d",
  ["compare_summary_selected"] = "- Проверено ячеек: %d",
  ["compare_summary_template"] = "- Шаблон: %s",
  ["compare_title"] = "Сравнение и синхронизация",
  ["config_bis_overlay_lock"] = "Закрепить оверлей BIS",
  ["config_bis_overlay_show"] = "Показывать оверлей мест добычи BIS",
  ["config_blizzard_frames_reset"] = "Сбросить позиции всех окон",
  ["config_blizzard_frames_reset_done"] = "Позиции всех окон Blizzard сброшены.",
  ["config_blizzard_frames_show"] = "Разрешить перемещение стандартных окон Blizzard (карта мира, персонаж, профессии, книга заклинаний, достижения, таланты, друзья, гильдия, банк и др.)",
  ["config_combat_text"] = "Боевой текст",
  ["config_combat_text_damage"] = "Показывать числа урона",
  ["config_combat_text_directional"] = "Направленный разлёт урона",
  ["config_combat_text_directional_label"] = "Разлёт урона",
  ["config_combat_text_enabled"] = "Показывать плавающий боевой текст",
  ["config_combat_text_healing"] = "Показывать числа исцеления",
  ["config_combat_text_hint"] = "Настройка отображения боевых чисел.",
  ["config_combat_text_managed"] = "Применять стиль боевого текста при входе",
  ["config_combat_text_mode"] = "Режим",
  ["config_combat_text_mode_arc"] = "Дугой",
  ["config_combat_text_mode_down"] = "Вниз",
  ["config_combat_text_mode_up"] = "Вверх",
  ["config_confirm"] = "Подтверждение",
  ["config_confirm_show"] = "Запрашивать подтверждение перед применением или очисткой шаблона",
  ["config_debug"] = "Журнал отладки",
  ["config_debug_show"] = "Включить журнал отладки только для этой сессии",
  ["config_general_title"] = "Основное",
  ["config_help"] = "Левый клик по кнопке у миникарты открывает или закрывает главное окно.\nПеретаскивание правой кнопкой перемещает кнопку.",
  ["config_item_level_overlay_lock"] = "Закрепить оверлей уровня предметов",
  ["config_item_level_overlay_show"] = "Показывать справочный оверлей уровня предметов",
  ["config_language"] = "Язык интерфейса",
  ["config_language_english"] = "Английский",
  ["config_language_hint"] = "По умолчанию используется язык клиента WoW, если он поддерживается аддоном. Для неподдерживаемых европейских и американских локалей используется английский, для азиатских — корейский.",
  ["config_language_korean"] = "Корейский",
  ["config_language_russian"] = "Русский",
  ["config_log_view_btn"] = "Открыть журнал",
  ["config_mail_history_show"] = "Показывать автодополнение недавних получателей при вводе адресата письма",
  ["config_merchant_helper_show"] = "Затемнять уже известные предметы, рецепты и игрушки у торговцев",
  ["config_minimap"] = "Кнопка у миникарты",
  ["config_minimap_show"] = "Показывать кнопку у миникарты",
  ["config_mouse_move_restore"] = "Автовосстановление движения мышью",
  ["config_mouse_move_restore_show"] = "Если движение мышью выключено, включать его автоматически при входе",
  ["config_mplus_record_overlay_show"] = "Показывать рейтинг и название подземелья на значках лучших результатов Mythic+ сезона",
  ["config_open_window"] = "Открыть окно аддона",
  ["config_overview_author"] = "%s(%s)",
  ["config_overview_author_header"] = "Автор",
  ["config_overview_character"] = "- Персонаж: %s | Класс: %s | Специализация: %s",
  ["config_overview_combat_text"] = "- Боевой текст: %s | Режим: %s",
  ["config_overview_debug"] = "- Отладка: %s (только сессия)",
  ["config_overview_guide_header"] = "Подсказки",
  ["config_overview_header"] = "Сессия",
  ["config_overview_hint_debug"] = "- Журнал отладки сбрасывается при выходе или перезагрузке интерфейса.",
  ["config_overview_hint_drag"] = "- Оверлеи характеристик и профессий можно перетаскивать прямо на экране.",
  ["config_overview_hint_map"] = "- Метки карты Midnight отображаются только на поддерживаемых картах при открытой карте мира.",
  ["config_overview_hint_tomtom"] = "- TomTom позволяет ставить точки сокровищ правым кликом; записи Harandar/Voidstorm можно ставить после входа в регион.",
  ["config_overview_hint_window"] = "- Откройте главное окно кнопкой у миникарты или командой /abpm.",
  ["config_overview_not_scanned"] = "Ещё не сканировалось",
  ["config_overview_overlays"] = "- Оверлеи: характеристики %s | профессии %s | карта Midnight %s",
  ["config_overview_panel_title"] = "Обзор",
  ["config_overview_profession_scan"] = "- Скан профессий: %s",
  ["config_overview_stats_options"] = "- Настройки характеристик: танковые %s | приоритет M+ %s",
  ["config_overview_storage"] = "- Хранение: настройки общие для аккаунта, прогресс профессий - по персонажам",
  ["config_profession_overlay"] = "Оверлей знаний профессий",
  ["config_profession_overlay_lock"] = "Закрепить оверлей профессий",
  ["config_profession_overlay_show"] = "Показывать компактную еженедельную сводку профессий",
  ["config_saved_bis_overlay"] = "Оверлей добычи BIS: %s.",
  ["config_saved_bis_overlay_locked"] = "Закрепление оверлея BIS: %s.",
  ["config_saved_blizzard_frames"] = "Перемещение окон Blizzard: %s.",
  ["config_saved_combat_text_apply_failed"] = "Не удалось применить CVar боевого текста. Проверьте ограничения клиента или другой аддон.",
  ["config_saved_combat_text_damage"] = "Числа урона: %s.",
  ["config_saved_combat_text_directional"] = "Направленный разлёт урона: %s.",
  ["config_saved_combat_text_enabled"] = "Плавающий боевой текст: %s.",
  ["config_saved_combat_text_healing"] = "Числа исцеления: %s.",
  ["config_saved_combat_text_managed"] = "Управление боевым текстом: %s.",
  ["config_saved_combat_text_mode"] = "Режим боевого текста: %s.",
  ["config_saved_confirm"] = "Подтверждение действий: %s.",
  ["config_saved_debug"] = "Журнал отладки: %s для этой сессии.",
  ["config_saved_item_level_overlay"] = "Оверлей уровня предметов: %s.",
  ["config_saved_item_level_overlay_locked"] = "Закрепление оверлея уровня предметов: %s.",
  ["config_saved_language"] = "Язык интерфейса изменён на %s.",
  ["config_saved_mail_history"] = "История получателей почты: %s.",
  ["config_saved_merchant_helper"] = "Затемнение известных предметов у торговцев: %s.",
  ["config_saved_minimap"] = "Кнопка миникарты: %s.",
  ["config_saved_mouse_move_restore"] = "Автовосстановление движения мышью: %s.",
  ["config_saved_mplus_record_overlay"] = "Оверлей лучших результатов Mythic+ сезона: %s.",
  ["config_saved_mythic_plus"] = "Режим приоритета характеристик: %s.",
  ["config_saved_profession_overlay"] = "Оверлей профессий: %s.",
  ["config_saved_profession_overlay_locked"] = "Закрепление оверлея профессий: %s.",
  ["config_saved_profession_overlay_scale"] = "Размер оверлея профессий: %s.",
  ["config_saved_profession_overlay_tooltips"] = "Подсказки оверлея профессий: %s.",
  ["config_saved_silvermoon_filter"] = "%s: %s.",
  ["config_saved_silvermoon_map"] = "Оверлей карты Midnight: %s.",
  ["config_saved_stats_overlay"] = "Оверлей характеристик персонажа: %s.",
  ["config_saved_stats_overlay_locked"] = "Закрепление оверлея характеристик: %s.",
  ["config_saved_stats_overlay_scale"] = "Размер оверлея характеристик: %s.",
  ["config_saved_tank_stats"] = "Отображение защитных характеристик танка: %s.",
  ["config_saved_typography"] = "%s: %s.",
  ["config_saved_world_event_overlay"] = "Оверлей мировых событий: %s.",
  ["config_settings_info"] = "Эти же настройки должны отображаться в Настройки > AddOns.",
  ["config_silvermoon_filter_beasts"] = "Почётные звери",
  ["config_silvermoon_filter_delves"] = "Вылазки",
  ["config_silvermoon_filter_dungeons"] = "Подземелья/рейды",
  ["config_silvermoon_filter_facilities"] = "Важные объекты",
  ["config_silvermoon_filter_portals"] = "Порталы",
  ["config_silvermoon_filter_professions"] = "Центры профессий",
  ["config_silvermoon_filter_renown"] = "Торговцы известности",
  ["config_silvermoon_filters"] = "Категории меток карты",
  ["config_silvermoon_map"] = "Оверлей карты Midnight",
  ["config_silvermoon_map_show"] = "Показывать важные объекты, порталы, подземелья, вылазки и торговцев известности на картах Midnight",
  ["config_stats_mythic_plus"] = "Приоритет M+",
  ["config_stats_mythic_plus_show"] = "Использовать приоритеты характеристик Mythic+ вместо рейдовых / PvE",
  ["config_stats_overlay"] = "Оверлей характеристик персонажа",
  ["config_stats_overlay_lock"] = "Закрепить оверлей характеристик",
  ["config_stats_overlay_show"] = "Показывать крит / скорость / искусность / универсальность и защитные характеристики танка",
  ["config_stats_overlay_size_label"] = "Размер оверлея характеристик",
  ["config_stats_tank_stats"] = "Танковые характеристики",
  ["config_stats_tank_stats_show"] = "Показывать защитные характеристики танка при игре в танковой специализации",
  ["config_title"] = "Настройки",
  ["config_typography_profession_overlay"] = "Размер текста оверлея профессий",
  ["config_typography_stats_overlay"] = "Размер текста оверлея характеристик",
  ["config_typography_title"] = "Размер текста",
  ["config_typography_tooltip"] = "Размер текста подсказок",
  ["config_typography_ui"] = "Размер текста главного окна",
  ["config_version_info"] = "Версия аддона: v%s",
  ["config_world_event_overlay_show"] = "Показывать оверлей таймеров мировых событий",
  ["confirm_apply_text"] = "Применить шаблон '%s' к панелям действий?\n\nДиапазон: %s\nОчистить перед применением: %s",
  ["confirm_clear_text"] = "Очистить выбранный диапазон панелей действий?\n\nДиапазон: %s\nЦелевых ячеек: %d",
  ["confirm_clear_full_warning"] = "Внимание: будут очищены все отслеживаемые ячейки панелей действий.",
  ["confirm_delete_text"] = "Удалить %s?",
  ["confirm_duplicate_template_text"] = "Дублировать шаблон '%s'?",
  ["confirm_export_template_text"] = "Экспортировать шаблон '%s' в строку?",
  ["confirm_import_template_text"] = "Импортировать шаблон из строки?",
  ["confirm_overwrite_template_text"] = "Шаблон '%s' уже существует.\n\nПерезаписать его текущими панелями действий?",
  ["confirm_save_template_text"] = "Сохранить текущие панели действий как шаблон '%s'?",
  ["confirm_undo_text"] = "Восстановить панели действий в состояние перед последним изменением?\n\nДиапазон: %s\nЦелевых ячеек: %d",
  ["current_character"] = "Текущий персонаж: %s | Класс: %s | Специализация: %s (%s)",
  ["delete_selected"] = "Удалить шаблон",
  ["duplicate_template"] = "Дублировать шаблон",
  ["duplicated_template"] = "Шаблон скопирован: %s",
  ["footer_author"] = "Автор: %s",
  ["ghost_clear_all_button"] = "Убрать недоступные действия",
  ["ghost_clear_all_long"] = "[Убрать недоступные действия]\n- Действие: убирает маркеры недоступных действий с панелей.\n- Диапазон: все панели.\n- Что изменится: остаточные маркеры недоступных заклинаний или предметов будут убраны.\n- Что останется: реальные назначения действий не затрагиваются.\n- Использование: после синхронизации остаточные маркеры недоступных заклинаний или предметов убираются одним нажатием.",
  ["ghost_clear_all_tip"] = "Действие: убрать маркеры недоступных действий с панелей.\nИспользование: после синхронизации остаточные маркеры недоступных заклинаний или предметов убираются одним нажатием.",
  ["help_verifywp"] = "/abpm verifywp [профессия] - добавить точки TomTom для незавершённых одноразовых сокровищ профессии",
  ["hint_set_range_in_action_bars"] = "Сначала выберите диапазон применения на вкладке панелей действий.",
  ["ilvl_anchor_disabled"] = "Отключено",
  ["ilvl_anchor_mythicplus"] = "Связать с окном M+",
  ["ilvl_anchor_overlay"] = "Отдельный оверлей",
  ["ilvl_avg_label"] = "Уровень предметов: %s",
  ["ilvl_col_crest"] = "Герб",
  ["ilvl_col_difficulty"] = "Режим",
  ["ilvl_col_drop"] = "Награда",
  ["ilvl_col_grade"] = "Ранг",
  ["ilvl_col_grade_max"] = "Ранг/макс.",
  ["ilvl_col_key"] = "Ключ",
  ["ilvl_col_my_crest"] = "Мои гербы",
  ["ilvl_col_my_key"] = "Мои ключи",
  ["ilvl_col_range"] = "Диапазон",
  ["ilvl_col_tier"] = "Уровень",
  ["ilvl_col_vault"] = "Великое хранилище",
  ["ilvl_crafted_gilded"] = "Позолоченный",
  ["ilvl_crafted_runecarved"] = "Рунический",
  ["ilvl_crest_adv"] = "Искатель",
  ["ilvl_crest_chmp"] = "Защитник",
  ["ilvl_crest_dawn"] = "Рассвет",
  ["ilvl_crest_dusk"] = "Сумерки",
  ["ilvl_crest_hero"] = "Герой",
  ["ilvl_crest_midnight"] = "Полночь",
  ["ilvl_crest_myth"] = "Эпохальный",
  ["ilvl_crest_sacred"] = "Священный",
  ["ilvl_crest_vet"] = "Ветеран",
  ["ilvl_delve_bountiful_key"] = "Использование карты сокровищ",
  ["ilvl_dungeon_heroic"] = "Героич.",
  ["ilvl_dungeon_mythic0"] = "Эпох.",
  ["ilvl_grade_adv"] = "Искатель",
  ["ilvl_grade_chmp"] = "Защитник",
  ["ilvl_grade_expl"] = "Исслед.",
  ["ilvl_grade_hero"] = "Герой",
  ["ilvl_grade_myth"] = "Эпох.",
  ["ilvl_grade_vet"] = "Ветеран",
  ["ilvl_key_bountiful"] = "Богатая",
  ["ilvl_key_fragments"] = "Фрагменты",
  ["ilvl_key_restored"] = "Восстановленный ключ",
  ["ilvl_key_unknown"] = "Неизвестно",
  ["ilvl_overlay_hint"] = "(размер меняется колёсиком мыши)",
  ["ilvl_overlay_title"] = "Уровни предметов",
  ["ilvl_pvp_conquest"] = "Завоевание",
  ["ilvl_pvp_honor"] = "Честь",
  ["ilvl_raid_heroic"] = "Героич.",
  ["ilvl_raid_mythic"] = "Эпох.",
  ["ilvl_raid_normal"] = "Обычный",
  ["ilvl_row_delve_tier"] = "Ур. %s",
  ["ilvl_row_key_level"] = "+%s",
  ["ilvl_section_crafted"] = "Изготовление",
  ["ilvl_section_delves"] = "Вылазки",
  ["ilvl_section_mythicplus"] = "M+ ключи",
  ["ilvl_section_pvp"] = "PvP",
  ["ilvl_section_raid"] = "Рейд",
  ["ilvl_tab_delves"] = "Вылазки",
  ["ilvl_tab_mythicplus"] = "M+",
  ["ilvl_tab_other"] = "Другое",
  ["ilvl_tab_overview"] = "Обзор",
  ["ilvl_tab_raid"] = "Рейд",
  ["ilvl_world_boss"] = "Мировой босс",
  ["loaded_window_hint"] = "Загружено.\nОткройте окно аддона командой /abpm.",
  ["map_filters_title"] = "Фильтры меток карты",
  ["map_font_size_label"] = "Размер текста оверлея карты",
  ["map_hint"] = "Управление метками карты Midnight. Оверлей карты вынесен на отдельную вкладку.",
  ["map_label_alchemy_short"] = "Алхимия",
  ["map_label_anomander"] = "Торговец известности",
  ["map_label_atal_aman"] = "Атал'Аман",
  ["map_label_auction_house"] = "Аукцион",
  ["map_label_bait_eversong"] = "Наживка Вечной Песни",
  ["map_label_bait_great_beast"] = "Наживка великого зверя",
  ["map_label_bait_harandar"] = "Наживка Харандара",
  ["map_label_bait_voidstorm"] = "Наживка Бури Бездны",
  ["map_label_bait_zulaman"] = "Наживка Зул'Амана",
  ["map_label_bank_vault"] = "Банк",
  ["map_label_black_market"] = "Чёрный рынок\nАукцион",
  ["map_label_blacksmithing_short"] = "Кузня",
  ["map_label_blinding_vale"] = "Ослепительная долина",
  ["map_label_caeris_fairdawn"] = "Торговец известности",
  ["map_label_chel_the_chip"] = "Торговец изобилия",
  ["map_label_collegiate_calamity"] = "Академическое бедствие",
  ["map_label_conquest_vendor"] = "Торговец завоевания",
  ["map_label_creation_catalyst"] = "Катализатор творения",
  ["map_label_delve_hub"] = "Штаб вылазок",
  ["map_label_den_of_nalorakk"] = "Логово Налоракка",
  ["map_label_dreamrift"] = "Разлом снов",
  ["map_label_enchanting_short"] = "Чары",
  ["map_label_engineering_short"] = "Инж.",
  ["map_label_great_vault"] = "Великое Хранилище",
  ["map_label_grudge_pit"] = "Яма вражды",
  ["map_label_gulf_of_memory"] = "Залив памяти",
  ["map_label_herbalism_short"] = "Травы",
  ["map_label_inn"] = "Трактир",
  ["map_label_inscription_short"] = "Начерт.",
  ["map_label_item_upgrader"] = "Улучшение предметов",
  ["map_label_jewelcrafting_short"] = "Ювел.",
  ["map_label_leatherworking_short"] = "Кожа",
  ["map_label_magisters_terrace"] = "Терраса Магистров",
  ["map_label_magovu"] = "Торговец известности",
  ["map_label_maisara_caverns"] = "Пещеры Майсары",
  ["map_label_march_on_queldanas"] = "Поход на Кель'Данас",
  ["map_label_mining_short"] = "Руда",
  ["map_label_mplus_portals"] = "Порталы M+",
  ["map_label_murder_row"] = "Квартал убийц",
  ["map_label_naynar"] = "Торговец известности",
  ["map_label_nexus_point_xenas"] = "Точка Нексуса Ксенас",
  ["map_label_parhelion_plaza"] = "Площадь паргелия",
  ["map_label_portal_harandar"] = "Портал: Харандар",
  ["map_label_portal_orgrimmar"] = "Портал: Оргриммар",
  ["map_label_portal_room"] = "Зал порталов",
  ["map_label_portal_silvermoon"] = "Портал: Луносвет",
  ["map_label_portal_silvermoon_harandar"] = "Портал: Луносвет\nи Харандар",
  ["map_label_portal_stormwind"] = "Портал: Штормград",
  ["map_label_portal_timeways"] = "Портал: Пути времени",
  ["map_label_portal_voidstorm"] = "Портал: Буря Бездны",
  ["map_label_profession_hub"] = "Центр профессий",
  ["map_label_pvp_hub"] = "PvP-центр",
  ["map_label_renown_vendor"] = "Торговец известности",
  ["map_label_shadow_enclave"] = "Анклав Теней",
  ["map_label_shadowguard_point"] = "Пост Стражи Тени",
  ["map_label_skinning_short"] = "Шкуры",
  ["map_label_sunkiller_sanctum"] = "Святилище Солнцегуба",
  ["map_label_tailoring_short"] = "Ткани",
  ["map_label_the_darkway"] = "Тёмный путь",
  ["map_label_torments_rise"] = "Подъём мучений",
  ["map_label_trading_post"] = "Торговая лавка",
  ["map_label_transmog"] = "Трансмогрификация",
  ["map_label_twilight_crypts"] = "Сумеречные склепы",
  ["map_label_voidscar_arena"] = "Арена Шрама Бездны",
  ["map_label_voidspire"] = "Шпиль Бездны",
  ["map_label_windrunner_spire"] = "Шпиль Ветрокрылых",
  ["map_label_work_orders"] = "Заказы",
  ["map_prefix_delve"] = "Вылазка",
  ["map_prefix_dungeon"] = "Подземелье",
  ["map_prefix_raid"] = "Рейд",
  ["map_supported_maps_body"] = "Поддерживаемые карты:\n- Луносвет\n- Леса Вечной Песни\n- Харандар\n- Буря Бездны\n- Зул'Аман\n- Остров Кель'Данас\n\nДля торговцев известности используется единая метка. Метки порталов отображаются в Луносвете, Лесах Вечной Песни, Харандаре и Буре Бездны.",
  ["map_supported_maps_title"] = "Поддерживаемые карты",
  ["map_title"] = "Карта Midnight",
  ["merchant_known_label"] = "Известно",
  ["minimap_tooltip_line1"] = "Левый клик: открыть или закрыть главное окно",
  ["minimap_tooltip_line2"] = "Правая кнопка + перетаскивание: переместить кнопку миникарты",
  ["minimap_tooltip_line3"] = "Автор: %s",
  ["minimap_tooltip_title"] = "Менеджер панелей действий",
  ["no_items"] = "(нет)",
  ["overlay_button_collapse_body_collapsed"] = "Нажмите, чтобы развернуть содержимое оверлея.",
  ["overlay_button_collapse_body_expanded"] = "Нажмите, чтобы свернуть содержимое оверлея.",
  ["overlay_button_collapse_title"] = "Свернуть / развернуть",
  ["overlay_button_lock_body_locked"] = "Позиция закреплена. Нажмите, чтобы разрешить перетаскивание.",
  ["overlay_button_lock_body_unlocked"] = "Позиция не закреплена. Нажмите, чтобы запретить перетаскивание.",
  ["overlay_button_lock_title"] = "Закрепить позицию",
  ["overlay_button_reset_body"] = "Вернуть этот оверлей в стандартное положение.",
  ["overlay_button_reset_title"] = "Сброс позиции",
  ["overlay_size_default"] = "Обычный",
  ["overlay_size_label"] = "Размер оверлея",
  ["overlay_size_large"] = "Большой",
  ["overlay_size_small"] = "Маленький",
  ["overlay_size_xlarge"] = "Очень большой",
  ["overlay_size_xsmall"] = "Очень маленький",
  ["pk_note_auto_progress"] = "Выполнено %d/%d целей | Очки %d/%d",
  ["pk_points_value_compact_format"] = "%d/%d",
  ["pk_points_value_format"] = "%d/%d оч.",
  ["pk_profession_note_crafting"] = "1. Авто: еженедельное задание, трактат профессии, еженедельный дроп\n2. Дополнительно: книги известности и одноразовые сокровища",
  ["pk_profession_note_enchanting"] = "1. Авто: еженедельное задание, трактат профессии, еженедельный дроп и дроп от распыления\n2. Дополнительно: книги известности, книги изобилия и одноразовые сокровища",
  ["pk_profession_note_gathering"] = "1. Авто: еженедельное задание тренера, дроп при сборе, трактат профессии\n2. Дополнительно: книги известности, сокровища и первые открытия",
  ["pk_progress_compact_format"] = "Прогресс %d/%d",
  ["pk_progress_format"] = "Прогресс %d/%d",
  ["pk_row_complete_prefix"] = "Выполнено: %s",
  ["pk_source_abundance_reward"] = "Книга изобилия",
  ["pk_source_disenchant_drops"] = "Дроп от распыления",
  ["pk_source_first_discoveries"] = "Первые открытия",
  ["pk_source_renown_reward"] = "Книга известности",
  ["pk_source_trainer_weekly"] = "Еженедельное задание тренера профессии",
  ["pk_source_treasures"] = "Сокровища профессии",
  ["pk_source_treatise"] = "Трактат профессии",
  ["pk_source_weekly_drops"] = "Еженедельный дроп",
  ["pk_source_weekly_gathering_drops"] = "Дроп собирательных профессий",
  ["pk_source_weekly_quest"] = "Еженедельное задание",
  ["pk_tooltip_complete_named_row"] = "Выполнено: %s (%d оч.)",
  ["pk_tooltip_complete_row"] = "Выполнено: %s (%d оч.)",
  ["pk_tooltip_header"] = "%s\nПрогресс: %d/%d целей | %d/%d очков",
  ["pk_tooltip_pending_named_row"] = "Ожидает: %s (%d оч.)",
  ["pk_tooltip_pending_row"] = "Ожидает: %s (%d оч.)",
  ["pk_value_format"] = "%d/%d целей | %d/%d очков",
  ["pk_value_label"] = "Очки",
  ["pk_value_label_done"] = "Выполнено",
  ["profession_alchemy"] = "Алхимия",
  ["profession_blacksmithing"] = "Кузнечное дело",
  ["profession_enchanting"] = "Наложение чар",
  ["profession_engineering"] = "Инженерное дело",
  ["profession_herbalism"] = "Травничество",
  ["profession_inscription"] = "Начертание",
  ["profession_jewelcrafting"] = "Ювелирное дело",
  ["profession_leatherworking"] = "Кожевничество",
  ["profession_mining"] = "Горное дело",
  ["profession_skinning"] = "Снятие шкур",
  ["profession_tailoring"] = "Портняжное дело",
  ["professions_empty"] = "У этого персонажа не найдено поддерживаемых основных профессий.",
  ["professions_hint"] = "Отслеживает знания профессий Midnight через скрытые задания. Еженедельные задания, трактаты, еженедельный дроп, книги известности и одноразовые сокровища сканируются автоматически.",
  ["professions_last_scan"] = "Последнее сканирование: %s",
  ["professions_one_time"] = "Одноразовые источники",
  ["professions_overlay_collapse"] = "Свернуть",
  ["professions_overlay_detail_onetime"] = "Одноразово | %s",
  ["professions_overlay_detail_weekly"] = "Еженедельно | %s",
  ["professions_overlay_empty"] = "Нет поддерживаемых профессий",
  ["professions_overlay_expand"] = "Развернуть",
  ["professions_overlay_hint"] = "Перетащите для перемещения.",
  ["professions_overlay_mode_compact"] = "Компактно",
  ["professions_overlay_mode_expanded"] = "Развёрнуто",
  ["professions_overlay_mode_mini"] = "Мини",
  ["professions_overlay_panel_empty"] = "Все отслеживаемые одноразовые сокровища собраны.",
  ["professions_overlay_panel_hint"] = "Нажмите запись ниже, чтобы поставить точку TomTom.",
  ["professions_overlay_panel_missing"] = "Для установки точек сокровищ требуется TomTom.",
  ["professions_overlay_panel_region_note"] = "Примечание: сокровища Harandar и Voidstorm находятся на отдельных региональных картах; TomTom поставит точки после входа в соответствующий регион.",
  ["professions_overlay_panel_title"] = "Незавершённые сокровища",
  ["professions_overlay_prefix_onetime"] = "Разово",
  ["professions_overlay_prefix_weekly"] = "Еженед.",
  ["professions_overlay_short_abundance"] = "Изобилие",
  ["professions_overlay_short_discoveries"] = "Открытия",
  ["professions_overlay_short_renown"] = "Известность",
  ["professions_overlay_short_treasures"] = "Сокровища",
  ["professions_overlay_short_treatise"] = "Трактат",
  ["professions_overlay_short_weekly_drops"] = "Дроп",
  ["professions_overlay_short_weekly_quest"] = "Задание",
  ["professions_overlay_title"] = "Очки профессий",
  ["professions_overlay_toggle"] = "Показывать оверлей очков профессий",
  ["professions_overlay_toggle_short"] = "Оверлей",
  ["professions_overlay_toggle_tooltip"] = "Следующий вид: %s",
  ["professions_overlay_tooltip_colors"] = "Цвета:",
  ["professions_overlay_tooltip_counts"] = "%d/%d целей, %d/%d оч.",
  ["professions_overlay_tooltip_done"] = "Выполнено",
  ["professions_overlay_tooltip_done_named"] = " Выполнено: %s",
  ["professions_overlay_tooltip_legend"] = "Обозначения",
  ["professions_overlay_tooltip_metrics"] = "Формат: выполнено/всего целей · получено/максимум очков",
  ["professions_overlay_tooltip_objective_counts"] = "%d/%d целей",
  ["professions_overlay_tooltip_onetime"] = "Одноразово",
  ["professions_overlay_tooltip_pending"] = "Ожидает",
  ["professions_overlay_tooltip_pending_named"] = " Ожидает: %s",
  ["professions_overlay_tooltip_reset"] = "Еженедельный сброс через %d дн.",
  ["professions_overlay_tooltip_reset_precise"] = "До еженедельного сброса в четверг: %d дн. %d ч. %d мин.",
  ["professions_overlay_tooltip_section_header"] = "[%s]",
  ["professions_overlay_tooltip_source_detail"] = "- %s %s %s, %s",
  ["professions_overlay_tooltip_source_line"] = "- %s (%s)",
  ["professions_overlay_tooltip_summary"] = "Еженедельно %d из %d оч. · Одноразово %d из %d оч.",
  ["professions_overlay_tooltip_summary_onetime"] = "Получено %2$d из %1$d очков, доступных из одноразовых источников.",
  ["professions_overlay_tooltip_summary_weekly"] = "Получено %2$d из %1$d очков, доступных из еженедельных заданий и источников.",
  ["professions_overlay_tooltip_tomtom_header"] = "TomTom",
  ["professions_overlay_tooltip_tomtom_header_line"] = "[TomTom]",
  ["professions_overlay_tooltip_tomtom_missing"] = "Установите TomTom, чтобы ставить точки маршрута к незавершённым одноразовым сокровищам.",
  ["professions_overlay_tooltip_tomtom_none"] = "Все отслеживаемые одноразовые сокровища профессий уже собраны.",
  ["professions_overlay_tooltip_tomtom_ready"] = "Правый клик по одноразовой строке откроет панель сокровищ и поставит точку маршрута: %s",
  ["professions_overlay_tooltip_weekly"] = "Еженедельно",
  ["professions_overlay_tooltips_toggle"] = "Показывать подсказки оверлея профессий",
  ["professions_overlay_tooltips_toggle_short"] = "Подсказки",
  ["professions_rescan"] = "Пересканировать",
  ["professions_section_summary"] = "%s: %d/%d очков",
  ["professions_status_rescanned"] = "%s: знания профессии пересканированы.",
  ["professions_summary"] = "Еженедельно %d/%d очков | Одноразово %d/%d очков",
  ["professions_title"] = "Еженедельная проверка профессий",
  ["professions_weekly"] = "Еженедельные источники",
  ["profiles_title"] = "Текущий персонаж",
  ["quest_abandon_all"] = "Отменить все задания",
  ["quest_abandon_all_confirm"] = "Отменить %d заданий из журнала?\n\nЭто удалит все отменяемые задания, включая задания с прогрессом.",
  ["quest_abandon_all_done"] = "[Отмена всех завершена]\n- Отменено заданий: %d\n- Пропущено заданий: %d\n- Ошибок: %d",
  ["quest_abandon_all_nothing"] = "Нет отменяемых заданий.",
  ["quest_abandon_all_tooltip"] = "Отменить все отменяемые задания в журнале, включая задания с уже имеющимся прогрессом.",
  ["quest_actions_hint"] = "Сначала обновите список заданий. Безопасная очистка удаляет только отменяемые задания без прогресса, а «Отменить все» отменяет все отменяемые задания в журнале.",
  ["quest_actions_title"] = "Действия очистки",
  ["quest_candidates_title"] = "Список кандидатов",
  ["quest_cleanup_confirm"] = "Выполнить безопасную очистку %d заданий?\n\nБудут удалены только отменяемые задания без прогресса, не завершённые и не готовые к сдаче.",
  ["quest_cleanup_done"] = "[Очистка заданий завершена]\n- Отменено заданий: %d\n- Пропущено заданий: %d\n- Ошибок: %d",
  ["quest_cleanup_nothing"] = "Нет заданий для безопасной очистки.",
  ["quest_keep_complete"] = "Завершено",
  ["quest_keep_in_progress"] = "Есть прогресс",
  ["quest_keep_not_abandonable"] = "Нельзя отменить",
  ["quest_keep_ready_for_turnin"] = "Готово к сдаче",
  ["quest_keep_unknown"] = "Оставлено",
  ["quest_list_all_header"] = "Цели отмены всех: %d",
  ["quest_list_all_row"] = "%s [ID задания: %d]",
  ["quest_list_id_format"] = "ID задания: %d",
  ["quest_list_keep_header"] = "Оставленные задания: %d",
  ["quest_list_keep_row"] = "%s [%s]",
  ["quest_list_none"] = "(нет)",
  ["quest_list_progress"] = "Цель: %s",
  ["quest_list_safe_header"] = "Цели безопасной очистки: %d",
  ["quest_list_safe_row"] = "%s [ID задания: %d]",
  ["quest_refresh"] = "Обновить кандидатов",
  ["quest_refresh_done"] = "Кандидаты на очистку заданий обновлены.",
  ["quest_refresh_tooltip"] = "Пересобрать список кандидатов на очистку из текущего журнала заданий.",
  ["quest_safe_cleanup"] = "Безопасная очистка",
  ["quest_safe_cleanup_tooltip"] = "Отменить только задания, которые можно удалить безопасно: отменяемые, не завершены, не готовы к сдаче и без прогресса.",
  ["quest_summary_abandonable"] = "- Отменяемых заданий: %d",
  ["quest_summary_all"] = "- Целей отмены всех: %d",
  ["quest_summary_counts"] = "Текущий журнал заданий",
  ["quest_summary_header"] = "Правила очистки заданий",
  ["quest_summary_kept"] = "- Оставлено заданий: %d",
  ["quest_summary_rule_all"] = "- Отменить все: отменяются все отменяемые задания в журнале",
  ["quest_summary_rule_safe"] = "- Безопасная очистка: удаляются только отменяемые задания без прогресса",
  ["quest_summary_rule_safe_keep"] = "- Остаются: задания с прогрессом, завершённые задания и задания, готовые к сдаче",
  ["quest_summary_safe"] = "- Целей безопасной очистки: %d",
  ["quest_summary_title"] = "Правила и сводка очистки",
  ["quest_summary_total"] = "- Всего заданий: %d",
  ["quest_support_unavailable"] = "Очистка заданий недоступна в этом клиенте.",
  ["quest_unknown_title"] = "Неизвестное задание (%d)",
  ["quests_title"] = "Очистка заданий",
  ["refresh_lists"] = "Обновить список",
  ["save_template"] = "Сохранить шаблон",
  ["section_apply_info"] = "Информация о применении",
  ["section_compare_basis"] = "Основа сравнения",
  ["section_compare_summary"] = "Сводка сравнения",
  ["section_template_info"] = "Информация о шаблоне",
  ["selected_source"] = "Выбранный шаблон: %s",
  ["selected_source_actions"] = "Действия с шаблоном",
  ["selection_mode_bar"] = "%s",
  ["selection_mode_bar_range"] = "%s ~ %s",
  ["selection_mode_bar_set"] = "%s",
  ["selection_mode_full"] = "Все отслеживаемые ячейки панелей действий",
  ["selection_mode_slot_range"] = "Ячейки %d-%d",
  ["selection_preview"] = "Сводка диапазона",
  ["selection_preview_text"] = "[Сводка диапазона]\n- Диапазон: %s\n- Выбрано ячеек: %d\n- Доступно для изменения: %d\n- Сначала очистить: %s",
  ["settings_category_action_bars"] = "Панели действий",
  ["settings_category_map"] = "Карта",
  ["settings_category_professions"] = "Профессии",
  ["settings_category_quests"] = "Задания",
  ["settings_category_templates"] = "Шаблоны",
  ["settings_category_utility"] = "Утилиты",
  ["settings_subpanel_action_bars_body"] = "Вкладка панелей действий позволяет сравнивать, синхронизировать, очищать и применять только нужные диапазоны.",
  ["settings_subpanel_action_bars_title"] = "Панели действий",
  ["settings_subpanel_button_action_bars"] = "Открыть вкладку панелей",
  ["settings_subpanel_button_map"] = "Открыть вкладку карты",
  ["settings_subpanel_button_professions"] = "Открыть вкладку профессий",
  ["settings_subpanel_button_quests"] = "Открыть вкладку заданий",
  ["settings_subpanel_button_templates"] = "Открыть вкладку шаблонов",
  ["settings_subpanel_button_utility"] = "Открыть вкладку утилит",
  ["settings_subpanel_map_body"] = "Переключатели оверлея карты, фильтры категорий, метки торговцев известности и масштаб текста доступны на вкладке карты.",
  ["settings_subpanel_map_title"] = "Карта Midnight",
  ["settings_subpanel_professions_body"] = "Отслеживание еженедельных источников профессий, компактный оверлей и пересканирование доступны на вкладке профессий.",
  ["settings_subpanel_professions_title"] = "Профессии",
  ["settings_subpanel_quests_body"] = "Очистка и отмена заданий находятся на вкладке заданий, чтобы избежать случайных нажатий.",
  ["settings_subpanel_quests_title"] = "Задания",
  ["settings_subpanel_templates_body"] = "Сохранение, копирование, применение и просмотр шаблонов панелей действий доступны в главном окне.",
  ["settings_subpanel_templates_title"] = "Шаблоны",
  ["settings_subpanel_utility_body"] = "Оверлеи, вспомогательные инструменты и управление окнами находятся на вкладке утилит.",
  ["settings_subpanel_utility_title"] = "Утилиты",
  ["slot_descriptor_bar"] = "Панель %d, ячейка %d",
  ["slot_descriptor_bar_named"] = "%s, ячейка %d",
  ["slot_descriptor_generic"] = "Ячейка %d",
  ["source_details_character"] = "Сохранено с персонажа: %s",
  ["source_details_character_bullet"] = "- Сохранено с персонажа: %s",
  ["source_details_class"] = "Класс: %s",
  ["source_details_class_bullet"] = "- Класс: %s",
  ["source_details_clear"] = "Очистить перед применением: %s",
  ["source_details_clear_bullet"] = "- Сначала очистить: %s",
  ["source_details_empty_slots_bullet"] = "- Пустых ячеек: %d",
  ["source_details_items_bullet"] = "- Предметов: %d",
  ["source_details_kind"] = "Тип: %s",
  ["source_details_macros_bullet"] = "- Макросов: %d",
  ["source_details_name"] = "Название: %s",
  ["source_details_name_bullet"] = "- Название: %s",
  ["source_details_no"] = "Нет",
  ["source_details_none"] = "[Шаблон]\n- Шаблон не выбран.",
  ["source_details_other_actions_bullet"] = "- Прочих действий: %d",
  ["source_details_recorded_actions_bullet"] = "- Записано действий: %d / отслеживаемых ячеек: %d",
  ["source_details_saved_at"] = "Сохранено: %s",
  ["source_details_saved_at_bullet"] = "- Сохранено: %s",
  ["source_details_scope"] = "Диапазон применения: %s",
  ["source_details_scope_bullet"] = "- Диапазон: %s",
  ["source_details_spec"] = "ID специализации: %s",
  ["source_details_spec_bullet"] = "- ID специализации: %s",
  ["source_details_spec_name_bullet"] = "- Специализация: %s",
  ["source_details_spells_bullet"] = "- Заклинаний: %d",
  ["source_details_title"] = "Информация о выбранном шаблоне",
  ["source_details_yes"] = "Да",
  ["source_kind_template"] = "Шаблон",
  ["source_none"] = "Шаблон не выбран",
  ["source_template"] = "Шаблон: %s",
  ["spec_switch_already"] = "Текущая специализация уже %s.",
  ["spec_switch_combat"] = "Во время боя нельзя менять специализацию.",
  ["spec_switch_requested"] = "Запрошена смена специализации: %s",
  ["spec_switch_title"] = "Сменить текущую специализацию",
  ["spec_switch_unavailable"] = "В этом клиенте недоступна смена специализации через API.",
  ["state_disabled"] = "выключено",
  ["state_enabled"] = "включено",
  ["state_hidden"] = "скрыто",
  ["state_shown"] = "показано",
  ["stats_overlay_block"] = "Блок",
  ["stats_overlay_class_deathknight"] = "Рыцарь смерти",
  ["stats_overlay_class_demonhunter"] = "Охотник на демонов",
  ["stats_overlay_class_druid"] = "Друид",
  ["stats_overlay_class_evoker"] = "Пробудитель",
  ["stats_overlay_class_hunter"] = "Охотник",
  ["stats_overlay_class_mage"] = "Маг",
  ["stats_overlay_class_monk"] = "Монах",
  ["stats_overlay_class_paladin"] = "Паладин",
  ["stats_overlay_class_priest"] = "Жрец",
  ["stats_overlay_class_rogue"] = "Разбойник",
  ["stats_overlay_class_shaman"] = "Шаман",
  ["stats_overlay_class_warlock"] = "Чернокнижник",
  ["stats_overlay_class_warrior"] = "Воин",
  ["stats_overlay_crit"] = "Крит",
  ["stats_overlay_dodge"] = "Уклонение",
  ["stats_overlay_dr_tier_1"] = "Снижение эффективности: уровень 1",
  ["stats_overlay_dr_tier_2"] = "Снижение эффективности: уровень 2",
  ["stats_overlay_dr_tier_3"] = "Снижение эффективности: уровень 3",
  ["stats_overlay_dr_tier_4"] = "Снижение эффективности: уровень 4",
  ["stats_overlay_dr_tier_5"] = "Снижение эффективности: уровень 5",
  ["stats_overlay_haste"] = "Скорость",
  ["stats_overlay_identity_line"] = "%s %s - %s (%d)",
  ["stats_overlay_line"] = "%s %d (%.2f%%)",
  ["stats_overlay_mastery"] = "Искусность",
  ["stats_overlay_parry"] = "Парирование",
  ["stats_overlay_priority_line"] = "%s %s",
  ["stats_overlay_priority_unknown"] = "Приоритет неизвестен",
  ["stats_overlay_short_crit"] = "К",
  ["stats_overlay_short_haste"] = "С",
  ["stats_overlay_short_mastery"] = "И",
  ["stats_overlay_short_versatility"] = "У",
  ["stats_overlay_tooltip_block_body"] = "Вероятность заблокировать атаку щитом.",
  ["stats_overlay_tooltip_block_title"] = "Блок",
  ["stats_overlay_tooltip_crit_body"] = "Повышает вероятность нанести критический урон или выполнить критическое исцеление.",
  ["stats_overlay_tooltip_crit_title"] = "Критический удар",
  ["stats_overlay_tooltip_dodge_body"] = "Вероятность уклониться от атаки ближнего боя.",
  ["stats_overlay_tooltip_dodge_title"] = "Уклонение",
  ["stats_overlay_tooltip_haste_body"] = "Ускоряет атаки и произнесение заклинаний, а также сокращает время восстановления некоторых способностей.",
  ["stats_overlay_tooltip_haste_title"] = "Скорость",
  ["stats_overlay_tooltip_mastery_body"] = "Усиливает эффект искусности вашей специализации.",
  ["stats_overlay_tooltip_mastery_title"] = "Искусность",
  ["stats_overlay_tooltip_parry_body"] = "Вероятность парировать атаку ближнего боя.",
  ["stats_overlay_tooltip_parry_title"] = "Парирование",
  ["stats_overlay_tooltip_priority_title"] = "Приоритет характеристик",
  ["stats_overlay_tooltip_priority_body"] = "Общая PvE-подсказка для вашей текущей специализации. Приоритет может меняться в зависимости от билда, героических талантов и типа контента.",
  ["stats_overlay_tooltip_versatility_body"] = "Увеличивает наносимый урон и исцеление, а также снижает получаемый урон.",
  ["stats_overlay_tooltip_versatility_title"] = "Универсальность",
  ["stats_overlay_unknown_spec"] = "Неизвестно",
  ["stats_overlay_versatility"] = "Универсальность",
  ["stats_priority_mode_mplus"] = "M+",
  ["stats_priority_mode_pve"] = "Рейд",
  ["status_lists_refreshed"] = "Список шаблонов обновлён.",
  ["status_ready"] = "Готово.",
  ["status_ready_no_source"] = "Готово.\nШаблон не выбран.",
  ["status_selection_updated"] = "Диапазон применения обновлён.",
  ["sync_actions_title"] = "Синхронизация",
  ["sync_available_only"] = "Только доступное\n(пропуск недоступного)",
  ["sync_available_only_no_applicable"] = "Различия есть, но сейчас нечего применить.\nПропущено недоступных ячеек шаблона: %d",
  ["sync_clear_extras"] = "Убрать лишнее\n(текущие > пусто)",
  ["sync_exact"] = "Полное совпадение\n(диапазон > шаблон)",
  ["sync_fill_empty"] = "Заполнить пустые\n(шаблон > пустые)",
  ["sync_help_available_only_long"] = "[Синхронизация]\n- Действие: применить только доступное сейчас\n- Основа: выбранный шаблон\n- Диапазон: %s\n- Цель: ячейки, которые можно очистить или заменить сейчас\n- Что изменится: пустые ячейки заполнятся, лишние очистятся, отличающиеся заменятся только если действие шаблона доступно персонажу.\n- Что останется: ячейки с недоступными действиями шаблона не меняются.\n- Пример: в %s, если шаблон требует заклинание, которого нет у персонажа, эта ячейка будет пропущена.",
  ["sync_help_available_only_tip"] = "Основа: выбранный шаблон\nДиапазон: %s\nЦель: только те ячейки, которые этот персонаж может применить сейчас\nПример: недоступные способности из шаблона будут пропущены, остальные ячейки можно очистить или заменить.",
  ["sync_help_clear_extras_long"] = "[Синхронизация]\n- Действие: очистить лишние текущие ячейки\n- Основа: выбранный шаблон\n- Диапазон: %s\n- Цель: текущие ячейки, которые не используются в шаблоне\n- Что изменится: заполненные сейчас ячейки, пустые в шаблоне, будут очищены.\n- Что останется: ячейки, уже совпадающие с шаблоном, не меняются.\n- Пример: в %s, если в текущей ячейке 7 есть способность, а в шаблоне ячейка 7 пустая, очистится только она.",
  ["sync_help_clear_extras_tip"] = "Основа: выбранный шаблон\nДиапазон: %s\nЦель: лишние ячейки текущих панелей\nПример: если в текущей ячейке есть действие, а в шаблоне эта ячейка пустая, будет очищена только лишняя ячейка.",
  ["sync_help_compare_tip"] = "Назначение: сравнить выбранный диапазон.\nДиапазон: %s\nПример: проверить, чем текущие панели отличаются от выбранного шаблона, без внесения изменений.",
  ["sync_help_exact_long"] = "[Синхронизация]\n- Действие: привести весь диапазон к шаблону\n- Основа: выбранный шаблон\n- Диапазон: %s\n- Цель: весь выбранный диапазон\n- Что изменится: пустые ячейки заполнятся, лишние очистятся, отличающиеся заменятся.\n- Что останется: итоговая раскладка в диапазоне будет точно как в шаблоне.\n- Пример: в %s весь выбранный диапазон будет перестроен под шаблон.",
  ["sync_help_exact_tip"] = "Основа: выбранный шаблон\nДиапазон: %s\nЦель: весь выбранный диапазон\nПример: пустые, лишние и отличающиеся ячейки будут приведены к точному совпадению с шаблоном.",
  ["sync_help_fill_empty_long"] = "[Синхронизация]\n- Действие: заполнить пустые текущие ячейки\n- Основа: выбранный шаблон\n- Диапазон: %s\n- Цель: только пустые текущие ячейки\n- Что изменится: пустые сейчас ячейки, заполненные в шаблоне, будут заполнены.\n- Что останется: уже заполненные текущие ячейки не меняются.\n- Пример: в %s, если в шаблоне есть способность в ячейке 5, а текущая ячейка 5 пуста, заполнится только она.",
  ["sync_help_fill_empty_tip"] = "Основа: выбранный шаблон\nДиапазон: %s\nЦель: пустые ячейки текущих панелей\nПример: если в шаблоне есть способность, а текущая ячейка пуста, будет заполнена только эта пустая ячейка.",
  ["sync_help_sync_diff_long"] = "[Синхронизация]\n- Действие: заменить только отличающиеся ячейки\n- Основа: выбранный шаблон\n- Диапазон: %s\n- Цель: текущие ячейки, которые отличаются от шаблона\n- Что изменится: только отличающиеся ячейки будут обновлены до состояния шаблона.\n- Что останется: совпадающие ячейки не меняются.\n- Пример: в %s, если сейчас в ячейке 3 действие Б, а в шаблоне действие А, изменится только ячейка 3.",
  ["sync_help_sync_diff_tip"] = "Основа: выбранный шаблон\nДиапазон: %s\nЦель: отличающиеся ячейки текущих панелей\nПример: если обе ячейки заполнены, но действия разные, текущая ячейка будет заменена действием из шаблона.",
  ["sync_hint"] = "Сначала выполните сравнение.\nНаведите курсор на кнопку синхронизации, чтобы понять её действие.",
  ["sync_nothing_to_do"] = "Для этого действия синхронизации изменений нет.",
  ["sync_slot_count_summary"] = "Изменено ячеек: %d",
  ["sync_sync_diff"] = "Заменить отличия\n(текущие > шаблон)",
  ["tab_action_bars"] = "Панели действий",
  ["tab_config"] = "Настройки",
  ["tab_map"] = "Карта",
  ["tab_professions"] = "Профессии",
  ["tab_profiles"] = "Шаблоны",
  ["tab_quests"] = "Задания",
  ["tab_utility"] = "Утилиты",
  ["template_name"] = "Название шаблона",
  ["template_scroll_down"] = "Выбрать следующий шаблон",
  ["template_scroll_hint"] = "Прокрутка",
  ["template_scroll_up"] = "Выбрать предыдущий шаблон",
  ["templates"] = "Список шаблонов",
  ["tomtom_missing"] = "TomTom не установлен. Установите TomTom, чтобы ставить точки сокровищ.",
  ["tomtom_no_pending_treasure"] = "Нет незавершённых одноразовых сокровищ профессий для точки маршрута.",
  ["tomtom_waypoint_region_required"] = "Сокровища %s используют карту своего региона, поэтому TomTom сможет поставить точку после входа в этот регион.",
  ["tomtom_waypoint_set"] = "Точка TomTom установлена: %s",
  ["tomtom_waypoint_unavailable"] = "Не удалось создать точку TomTom.",
  ["transfer_cancel"] = "Отмена",
  ["transfer_close"] = "Закрыть",
  ["transfer_copy"] = "Копировать",
  ["transfer_copy_ready"] = "Строка выделена. Нажмите Ctrl+C, чтобы скопировать.",
  ["transfer_error_duplicate_slot"] = "В импортируемой строке есть повторяющиеся строки ячеек.",
  ["transfer_error_empty"] = "Сначала вставьте строку экспортированного шаблона.",
  ["transfer_error_invalid_action_kind"] = "В импортируемой строке есть неподдерживаемый тип действия.",
  ["transfer_error_invalid_format"] = "Недопустимый формат строки шаблона.",
  ["transfer_error_invalid_prefix"] = "Это не строка экспорта шаблона ABPM.",
  ["transfer_error_missing_name"] = "В импортируемом шаблоне нет корректного названия.",
  ["transfer_error_name_too_long"] = "Название шаблона в импортируемой строке слишком длинное.",
  ["transfer_error_too_large"] = "Импортируемая строка слишком большая.",
  ["transfer_error_too_many_lines"] = "В импортируемой строке слишком много строк.",
  ["transfer_export_button"] = "Экспорт строки",
  ["transfer_export_help"] = "Скопируйте строку ниже, чтобы перенести шаблон на другого персонажа или в другую среду.",
  ["transfer_export_name"] = "Выбранный шаблон: %s",
  ["transfer_export_status"] = "Нажмите «Выделить всё» или «Копировать», затем при необходимости Ctrl+C.",
  ["transfer_export_title"] = "Строка экспорта",
  ["transfer_import_action"] = "Импортировать",
  ["transfer_import_button"] = "Импорт строки",
  ["transfer_import_help"] = "Вставьте экспортированную строку ниже. Оставьте имя пустым, чтобы сохранить исходное название шаблона.",
  ["transfer_import_name"] = "Новое имя импортируемого шаблона",
  ["transfer_import_success"] = "Импортирован шаблон: %s",
  ["transfer_import_title"] = "Строка импорта",
  ["transfer_select_all"] = "Выделить всё",
  ["undo_button"] = "Отменить последнее",
  ["undo_completed"] = "[Отмена завершена]\n- Восстановлен диапазон: %s\n- Применено ячеек: %d\n- Очищено ячеек: %d\n- Призраки или отсутствующие: %d\n- Пропущено ячеек: %d",
  ["undo_unavailable"] = "Нет недавнего изменения для отмены.",
  ["utility_actions_title"] = "Действия",
  ["utility_blizzard_hint"] = "Позволяет перетаскивать стандартные окна Blizzard: карту мира, персонажа, профессии, книгу заклинаний, достижения, таланты, друзей, гильдию, банк и другие. Кнопка сброса возвращает стандартные позиции.",
  ["utility_hint"] = "Дополнительные функции аддона.",
  ["utility_overlay_hint"] = "Справочные оверлеи для уровня предметов, BIS-добычи и лучших результатов сезона Mythic+. Оверлеи можно перетаскивать по экрану и менять их размер колёсиком мыши.",
  ["utility_panel_title"] = "Утилиты",
  ["utility_profession_hint"] = "Показывает компактную еженедельную сводку прогресса знаний профессий Midnight.",
  ["utility_section_blizzard"] = "Перемещение окон Blizzard",
  ["utility_section_overlays"] = "Оверлеи добычи и событий",
  ["utility_section_profession_overlay"] = "Оверлей профессий",
  ["utility_section_shop"] = "Торговцы / почта",
  ["utility_section_stats_overlay"] = "Оверлей характеристик",
  ["utility_shop_hint"] = "Затемняет уже известные рецепты и игрушки у торговцев, а также показывает историю получателей почты.",
  ["utility_stats_hint"] = "Показывает плавающий оверлей с текущими критическим ударом, скоростью, искусностью и универсальностью. Танковые специализации могут дополнительно показывать защитные характеристики.",
  ["utility_status_title"] = "Статус",
  ["utility_title"] = "Утилиты",
  ["verifywp_added"] = "[VerifyWP] Добавлено %d/%d точек незавершённых сокровищ в TomTom.",
  ["verifywp_listed"] = "[VerifyWP] Выведено %d/%d незавершённых сокровищ (TomTom не найден).",
  ["verifywp_no_data"] = "[VerifyWP] Данные точек не найдены.",
  ["window_title"] = "Менеджер панелей действий (ABProfileManager) Автор: MingMing & Coco",
  ["world_event_abundance"] = "Изобилие",
  ["world_event_active"] = "Идёт сейчас",
  ["world_event_community_feast"] = "Общий пир",
  ["world_event_dragonbane_keep"] = "Крепость Драконьей Погибели",
  ["world_event_grand_hunts"] = "Великая охота",
  ["world_event_haranyrLegend"] = "Легенда хараниров",
  ["world_event_loc_abundance"] = "Леса Вечной Песни",
  ["world_event_loc_community_feast"] = "Луносвет",
  ["world_event_loc_dragonbane_keep"] = "Крепость Драконьей Погибели",
  ["world_event_loc_grand_hunts"] = "Harandar",
  ["world_event_loc_haranyrLegend"] = "Harandar",
  ["world_event_loc_saldeerylsCourt"] = "Луносвет",
  ["world_event_loc_stomarionAttack"] = "Область Voidstorm",
  ["world_event_loc_the_hunt"] = "Леса Вечной Песни",
  ["world_event_loc_void_storm"] = "Область Voidstorm",
  ["world_event_next"] = "Следующее: %s",
  ["world_event_next_label"] = "Следующее:",
  ["world_event_overlay_title"] = "Мировые события",
  ["world_event_saldeerylsCourt"] = "Двор Салдирила",
  ["world_event_stomarionAttack"] = "Нападение Стомариона",
  ["world_event_the_hunt"] = "Охота",
  ["world_event_tooltip_mark_done"] = "Щелчок: отметить выполненным сегодня",
  ["world_event_tooltip_unmark"] = "Щелчок: снять отметку выполнения",
  ["world_event_void_storm"] = "Буря Бездны",
}

local CLASS_NAMES_RURU = {
  ["DEATHKNIGHT"] = "Рыцарь смерти",
  ["DEMONHUNTER"] = "Охотник на демонов",
  ["DRUID"] = "Друид",
  ["EVOKER"] = "Пробудитель",
  ["HUNTER"] = "Охотник",
  ["MAGE"] = "Маг",
  ["MONK"] = "Монах",
  ["PALADIN"] = "Паладин",
  ["PRIEST"] = "Жрец",
  ["ROGUE"] = "Разбойник",
  ["SHAMAN"] = "Шаман",
  ["WARLOCK"] = "Чернокнижник",
  ["WARRIOR"] = "Воин",
}

local SPEC_NAMES_RURU = {
  [62] = "Тайная магия",
  [63] = "Огонь",
  [64] = "Лед",
  [65] = "Свет",
  [66] = "Защита",
  [70] = "Воздаяние",
  [71] = "Оружие",
  [72] = "Неистовство",
  [73] = "Защита",
  [102] = "Баланс",
  [103] = "Сила зверя",
  [104] = "Страж",
  [105] = "Исцеление",
  [250] = "Кровь",
  [251] = "Лед",
  [252] = "Нечестивость",
  [253] = "Повелитель зверей",
  [254] = "Стрельба",
  [255] = "Выживание",
  [256] = "Послушание",
  [257] = "Свет",
  [258] = "Тьма",
  [259] = "Ликвидация",
  [260] = "Головорез",
  [261] = "Скрытность",
  [262] = "Стихии",
  [263] = "Совершенствование",
  [264] = "Исцеление",
  [265] = "Колдовство",
  [266] = "Демонология",
  [267] = "Разрушение",
  [268] = "Хмелевар",
  [269] = "Танцующий с ветром",
  [270] = "Ткач туманов",
  [577] = "Истребление",
  [581] = "Месть",
  [1382] = "Хищник",
  [1467] = "Опустошитель",
  [1468] = "Хранитель",
  [1473] = "Насыщатель",
}

local OBJECTIVE_NAMES_RURU = {
  [" Death Knight - "] = " Рыцарь смерти - ",
  [" Demon Hunter - "] = " Охотник на демонов - ",
  [" Druid - "] = " Друид - ",
  [" Evoker - "] = " Пробудитель - ",
  [" Hunter - "] = " Охотник - ",
  [" Mage - "] = " Маг - ",
  [" Monk - "] = " Монах - ",
  [" Paladin - "] = " Паладин - ",
  [" Point"] = " очко",
  [" Points"] = " очков",
  [" Priest - "] = " Жрец - ",
  [" Rogue - "] = " Разбойник - ",
  [" Shaman - "] = " Шаман - ",
  [" Warlock - "] = " Чернокнижник - ",
  [" Warrior - "] = " Воин - ",
  [" objective"] = " цель",
  [" objectives"] = " целей",
  [" pt"] = " оч.",
  [" pts"] = " оч.",
  [" Воин - "] = " 전사 - ",
  [" Друид - "] = " 드루이드 - ",
  [" Жрец - "] = " 사제 - ",
  [" Маг - "] = " 마법사 - ",
  [" Монах - "] = " 수도사 - ",
  [" Охотник - "] = " 사냥꾼 - ",
  [" Охотник на демонов - "] = " 악마사냥꾼 - ",
  [" Паладин - "] = " 성기사 - ",
  [" Пробудитель - "] = " 기원사 - ",
  [" Разбойник - "] = " 도적 - ",
  [" Рыцарь смерти - "] = " 죽음의 기사 - ",
  [" Чернокнижник - "] = " 흑마법사 - ",
  [" Шаман - "] = " 주술사 - ",
  ["1 Points"] = "1 оч.",
  ["10 Points"] = "10 оч.",
  ["2 Points"] = "2 оч.",
  ["24 Points"] = "24 оч.",
  ["3 Points"] = "3 оч.",
  ["30 Points"] = "30 оч.",
  ["4 Points"] = "4 оч.",
  ["A Child's Stuffy"] = "Детская мягкая игрушка",
  ["A Really Nice Curtain"] = "Очень красивая занавеска",
  ["A Spade"] = "Лопата",
  ["Abundance"] = "풍요",
  ["Abundance book"] = "Книга изобилия",
  ["Aged Cruor"] = "Выдержанная запёкшаяся кровь",
  ["Alchemy"] = "алхимия",
  ["All tracked one-time profession treasures are collected."] = "Все отслеживаемые одноразовые сокровища профессий собраны.",
  ["Allow moving Blizzard UI frames (World Map, Character, Professions, Spellbook, Achievements, Talent, Friends, Guild, Bank, and more)"] = "Разрешить перемещение стандартных окон Blizzard",
  ["Amani Expert's Chisel"] = "Долото эксперта амани",
  ["Amani Leatherworker's Tool"] = "Инструмент кожевника амани",
  ["Amani Skinning Knife"] = "Нож свежевателя амани",
  ["Amani Tanning Oil"] = "Дубильное масло амани",
  ["Argentleaf"] = "сребролист",
  ["Artisan's Considered Order"] = "Продуманный заказ ремесленника",
  ["Artisan's Cover Comb"] = "Гребень ремесленника для покрывал",
  ["Auto: trainer quest, gathering drops, profession treatise"] = "Авто: задание тренера, дроп собирательных профессий, трактат профессии",
  ["Auto: weekly quest, profession treatise, weekly and disenchant drops"] = "Авто: еженедельное задание, трактат профессии, еженедельный дроп и дроп от распыления",
  ["Auto: weekly quest, profession treatise, weekly drops"] = "Авто: еженедельное задание, трактат профессии, еженедельный дроп",
  ["Available"] = "Доступно",
  ["Azeroot"] = "азеритовый корень",
  ["Beyond the Event Horizon: Alchemy"] = "За горизонтом событий: Алхимия",
  ["Beyond the Event Horizon: Blacksmithing"] = "За горизонтом событий: Кузнечное дело",
  ["Beyond the Event Horizon: Engineering"] = "За горизонтом событий: Инженерное дело",
  ["Blacksmithing"] = "кузнечное дело",
  ["Blizzard Frame Movement"] = "Перемещение окон Blizzard",
  ["Block"] = "Блок",
  ["Bloomed Bud"] = "Распустившийся бутон",
  ["Book of Sin'dorei Stitches"] = "Книга швов син'дорай",
  ["Brilliant Phoenix Ink"] = "Сверкающие чернила феникса",
  ["Brilliant Silver"] = "сверкающее серебро",
  ["Brilliant Silver Seam"] = "Жила блистательного серебра",
  ["Bundle of Tanner's Trinkets"] = "Связка безделушек дубильщика",
  ["Cadre Skinning Knife"] = "Нож свежевателя Кадры",
  ["Carefully Racked Spear"] = "Аккуратно уложенное копьё",
  ["Change current specialization"] = "Сменить текущую специализацию",
  ["Clear All Ghosts"] = "Убрать недоступные действия",
  ["Click"] = "Щелчок",
  ["Collected"] = "Собрано",
  ["Complete"] = "Выполнено",
  ["Completed"] = "Выполнено",
  ["Crit"] = "Крит",
  ["Current"] = "Текущее",
  ["Current character"] = "Текущий персонаж",
  ["Dance Gear"] = "Танцевальный механизм",
  ["Dawn Capacitor"] = "Рассветный конденсатор",
  ["Deconstructed Forge Techniques"] = "Разобранные кузнечные приёмы",
  ["Discoveries"] = "발견",
  ["Disenchant Drop 1"] = "Дроп от распыления 1",
  ["Disenchant Drop 2"] = "Дроп от распыления 2",
  ["Disenchant Drop 3"] = "Дроп от распыления 3",
  ["Disenchant Drop 4"] = "Дроп от распыления 4",
  ["Disenchant Drop 5"] = "Дроп от распыления 5",
  ["Dodge"] = "Уклонение",
  ["Done"] = "Выполнено",
  ["Done:"] = "Выполнено:",
  ["Drag"] = "Перетащите",
  ["Drop & Event Overlays"] = "Оверлеи добычи и событий",
  ["Drops"] = "획득",
  ["Dual-Function Magnifiers"] = "Двойные увеличительные стёкла",
  ["Echo of Abundance: Enchanting"] = "Эхо изобилия: Наложение чар",
  ["Echo of Abundance: Herbalism"] = "Эхо изобилия: травничество",
  ["Echo of Abundance: Mining"] = "Эхо изобилия: Горное дело",
  ["Echo of Abundance: Skinning"] = "Эхо изобилия: Снятие шкур",
  ["Echo of Abundance: Tailoring"] = "Эхо изобилия: портняжное дело",
  ["Embroidered Memento"] = "Вышитый сувенир",
  ["Enchanted Amani Mask"] = "Зачарованная маска амани",
  ["Enchanted Sunfire Silk"] = "Зачарованный шёлк солнечного огня",
  ["Enchanting"] = "наложение чар",
  ["Engineering"] = "инженерное дело",
  ["Entropic Shard"] = "Энтропический осколок",
  ["Etheral Stormwrench"] = "Эфирный штормовой гаечный ключ",
  ["Ethereal Gem Pliers"] = "Эфирные щипцы для самоцветов",
  ["Ethereal Leatherworking Knife"] = "Эфирный нож кожевника",
  ["Everblazing Sunmote"] = "Вечно пылающая частица солнца",
  ["Eversong Woods"] = "Леса Вечной Песни",
  ["Expeditious Pylon"] = "Проворный пилон",
  ["Extra: renown books and one-time treasures"] = "Дополнительно: книги известности и одноразовые сокровища",
  ["Extra: renown books, treasures, and first discoveries"] = "Дополнительно: книги известности, сокровища и первые открытия",
  ["Extra: renown, abundance books, and one-time treasures"] = "Дополнительно: книги известности, книги изобилия и одноразовые сокровища",
  ["Failed Experiment"] = "Неудачный эксперимент",
  ["Finely Woven Lynx Collar"] = "Тонко сотканный ошейник рыси",
  ["First Discoveries"] = "Первые открытия",
  ["First discoveries"] = "Первые открытия",
  ["Freshly Plucked Peacebloom"] = "Свежесорванный мироцвет",
  ["Gathered Herb Sample 1"] = "Образец собранной травы 1",
  ["Gathered Herb Sample 2"] = "Образец собранной травы 2",
  ["Gathered Herb Sample 3"] = "Образец собранной травы 3",
  ["Gathered Herb Sample 4"] = "Образец собранной травы 4",
  ["Gathered Herb Sample 5"] = "Образец собранной травы 5",
  ["Gathering drops"] = "Дроп собирательных профессий",
  ["Glimmering Void Pearl"] = "Мерцающая жемчужина Бездны",
  ["Greater Disenchant Drop"] = "Большая добыча от распыления",
  ["Greater Herb Sample"] = "Большой образец трав",
  ["Greater Ore Sample"] = "Большой образец руды",
  ["Greater Skinning Trophy"] = "Большой трофей снятия шкур",
  ["Half-Baked Techniques"] = "Сырые техники",
  ["Handy Wrench"] = "Удобный гаечный ключ",
  ["Harandar"] = "Харандар",
  ["Harandar Stone Sample"] = "Образец камня Харандара",
  ["Haranir Leatherworking Knife"] = "Кожевенный нож хараниров",
  ["Haranir Leatherworking Mallet"] = "Кожевенный молоток хараниров",
  ["Harvester's Sickle"] = "Серп жнеца",
  ["Haste"] = "Скорость",
  ["Herbalism"] = "травничество",
  ["Incomplete"] = "Не выполнено",
  ["Infused Quenching Oil"] = "Насыщенное закалочное масло",
  ["Inscription"] = "начертание",
  ["Install TomTom to set waypoints for unfinished one-time treasures."] = "Установите TomTom, чтобы ставить точки маршрута к незавершённым одноразовым сокровищам.",
  ["Intrepid Explorer's Marker"] = "Маркер отважного исследователя",
  ["Isle of Quel'Danas"] = "Остров Кель'Данас",
  ["Isle of Quel'Danas Renown vendors use a unified label. Portal markers are shown in Silvermoon, Eversong Woods, Harandar, and Voidstorm."] = "Для торговцев известности на острове Кель'Данас используется единая метка. Метки порталов отображаются в Луносвете, Лесах Вечной Песни, Харандаре и Буре Бездны.",
  ["Jewelcrafting"] = "ювелирное дело",
  ["Knowledge"] = "Знания",
  ["Known"] = "Изучено",
  ["Last scan:"] = "Последнее сканирование:",
  ["Leather-Bound Techniques"] = "Техники в кожаном переплёте",
  ["Leatherworking"] = "кожевничество",
  ["Left-click"] = "Левый клик",
  ["Leftover Sanguithorn Pigment"] = "Остатки пигмента кровошипа",
  ["Lightbloom Afflicted Hide"] = "Шкура, поражённая светлым цветением",
  ["Lightbloom Root"] = "Корень светлокуста",
  ["Lightbloomed Spore Sample"] = "Образец спор светлого цветения",
  ["Lightfused Argentleaf"] = "Озарённый Светом сребролист",
  ["Lightfused Azeroot"] = "Озарённый Светом азеритовый корень",
  ["Lightfused Brilliant Silver"] = "Озарённое Светом блистательное серебро",
  ["Lightfused Mana Lily"] = "Озарённая Светом маналилия",
  ["Lightfused Refulgent Copper"] = "Озарённая Светом сияющая медь",
  ["Lightfused Sanguithorn"] = "Озарённый Светом кровошип",
  ["Lightfused Tranquility Bloom"] = "Озарённый Светом цветок безмятежности",
  ["Lightfused Umbral Tin"] = "Озарённая Светом теневая оловянная руда",
  ["Lightfused Азеритовый корень"] = "Озарённый Светом азеритовый корень",
  ["Lightfused Кровошип"] = "Озарённый Светом кровошип",
  ["Lightfused Маналилия"] = "Озарённая Светом маналилия",
  ["Lightfused Сребролист"] = "Озарённый Светом сребролист",
  ["Lightfused Цветок безмятежности"] = "Озарённый Светом цветок безмятежности",
  ["Loa-Blessed Dust"] = "Пыль, благословлённая лоа",
  ["Loa-Blessed Rune"] = "Руна, благословлённая лоа",
  ["Lock BIS overlay position (disable drag)"] = "Закрепить оверлей BIS",
  ["Lock item level overlay position (disable drag)"] = "Закрепить оверлей уровня предметов",
  ["Lock profession overlay position (disable drag)"] = "Закрепить оверлей профессий",
  ["Lock stats overlay position (disable drag)"] = "Закрепить оверлей характеристик",
  ["Lost Thalassian Vellum"] = "Потерянный талассийский пергамент",
  ["Lost Voidstorm Satchel"] = "Потерянная сумка Бури Бездны",
  ["Lush Argentleaf"] = "Пышный сребролист",
  ["Lush Azeroot"] = "Пышный азеритовый корень",
  ["Lush Mana Lily"] = "Пышная маналилия",
  ["Lush Sanguithorn"] = "Пышный кровошип",
  ["Lush Tranquility Bloom"] = "Пышный цветок безмятежности",
  ["Lush Азеритовый корень"] = "Пышный азеритовый корень",
  ["Lush Кровошип"] = "Пышный кровошип",
  ["Lush Маналилия"] = "Пышная маналилия",
  ["Lush Сребролист"] = "Пышный сребролист",
  ["Lush Цветок безмятежности"] = "Пышный цветок безмятежности",
  ["Mana Lily"] = "маналилия",
  ["Manual of Mistakes and Mishaps"] = "Руководство по ошибкам и неудачам",
  ["Mastery"] = "Искусность",
  ["Measured Ladle"] = "Мерный половник",
  ["Metalworking Cheat Sheet"] = "Шпаргалка по металлообработке",
  ["Mined Ore Sample 1"] = "Образец добытой руды 1",
  ["Mined Ore Sample 2"] = "Образец добытой руды 2",
  ["Mined Ore Sample 3"] = "Образец добытой руды 3",
  ["Mined Ore Sample 4"] = "Образец добытой руды 4",
  ["Mined Ore Sample 5"] = "Образец добытой руды 5",
  ["Miner's Guide to Voidstorm"] = "Руководство шахтёра по Буре Бездны",
  ["Miniaturized Transport Skiff"] = "Миниатюрный транспортный ялик",
  ["Mining"] = "горное дело",
  ["Missing"] = "Отсутствует",
  ["Not collected"] = "Не собрано",
  ["Not complete"] = "Не выполнено",
  ["Objectives"] = "целей",
  ["Offline Helper Bot"] = "Отключённый бот-помощник",
  ["One Engineer's Junk"] = "Хлам одного инженера",
  ["One time"] = "Одноразово",
  ["One%-Time Sources"] = "Одноразовые источники",
  ["One-Time Sources"] = "Одноразовые источники",
  ["One-time"] = "1회",
  ["Open:"] = "Ожидает:",
  ["Parry"] = "Парирование",
  ["Particularly Enchanting Table"] = "Особенно чарующий стол",
  ["Particularly Enchanting Tablecloth"] = "Особенно чарующая скатерть",
  ["Patterns: Beyond the Void"] = "Выкройки: За пределами Бездны",
  ["Peculiar Lotus"] = "Странный лотос",
  ["Pending"] = "Ожидает",
  ["Pending:"] = "Ожидает:",
  ["Planting Shovel"] = "Посадочная лопатка",
  ["Point"] = "очко",
  ["Points"] = "очков",
  ["Poorly Rounded Vial"] = "Плохо огранённый фиал",
  ["Prestigiously Racked Hide"] = "Престижно развешенная шкура",
  ["Primal Argentleaf"] = "Изначальный сребролист",
  ["Primal Azeroot"] = "Изначальный азеритовый корень",
  ["Primal Brilliant Silver"] = "Изначальное блистательное серебро",
  ["Primal Essence Orb"] = "Сфера изначальной сущности",
  ["Primal Hide"] = "Изначальная шкура",
  ["Primal Mana Lily"] = "Изначальная маналилия",
  ["Primal Refulgent Copper"] = "Изначальная сияющая медь",
  ["Primal Sanguithorn"] = "Изначальный кровошип",
  ["Primal Tranquility Bloom"] = "Изначальный цветок безмятежности",
  ["Primal Umbral Tin"] = "Изначальная теневая оловянная руда",
  ["Primal Азеритовый корень"] = "Изначальный азеритовый корень",
  ["Primal Кровошип"] = "Изначальный кровошип",
  ["Primal Маналилия"] = "Изначальная маналилия",
  ["Primal Сребролист"] = "Изначальный сребролист",
  ["Primal Цветок безмятежности"] = "Изначальный цветок безмятежности",
  ["Pristine Potion"] = "Безупречное зелье",
  ["Profession Knowledge"] = "Знания профессий",
  ["Profession Overlay"] = "Оверлей профессий",
  ["Profession Points"] = "전문 기술 점수",
  ["Profession Treatise"] = "Трактат профессии",
  ["Profession Weekly Check"] = "Еженедельная проверка профессий",
  ["Profession knowledge"] = "Знания профессий",
  ["Profession trainer weekly quest"] = "Еженедельное задание тренера профессии",
  ["Profession treasures"] = "Сокровища профессии",
  ["Profession treatise"] = "Трактат профессии",
  ["Progress"] = "Прогресс",
  ["Progress:"] = "Прогресс:",
  ["Pure Void Crystal"] = "Чистый кристалл Бездны",
  ["Quest"] = "퀘스트",
  ["Refulgent Copper"] = "сияющая медь",
  ["Refulgent Copper Seam"] = "Жила сияющей меди",
  ["Renown"] = "영예",
  ["Renown book"] = "Книга известности",
  ["Rescan"] = "Пересканировать",
  ["Reset"] = "Сброс",
  ["Reset All Frame Positions"] = "Сбросить позиции всех окон",
  ["Rich Brilliant Silver"] = "Богатое блистательное серебро",
  ["Rich Refulgent Copper"] = "Богатая сияющая медь",
  ["Rich Umbral Tin"] = "Богатая теневая оловянная руда",
  ["Right-click"] = "Правый клик",
  ["Right-click to open the unfinished treasure panel and set a waypoint"] = "Правый клик: открыть список незавершённых сокровищ и поставить точку маршрута",
  ["Rutaani Floratender's Sword"] = "Меч садовника рутаани",
  ["Sanguithorn"] = "кровошип",
  ["Satin Throw Pillow"] = "Атласная декоративная подушка",
  ["Scroll"] = "Прокрутка",
  ["Selected"] = "Выбранное",
  ["Shattered Glass"] = "Расколотое стекло",
  ["Show BIS drop location overlay"] = "Показывать оверлей мест добычи BIS",
  ["Show item level reference overlay"] = "Показывать справочный оверлей уровня предметов",
  ["Show score/dungeon name on Mythic+ season-best dungeon icons"] = "Показывать рейтинг и название подземелья на значках лучших результатов Mythic+ сезона",
  ["Silvermoon"] = "Луносвет",
  ["Silvermoon Blacksmith's Hammer"] = "Молот кузнеца Луносвета",
  ["Silvermoon Smithing Kit"] = "Кузнечный набор Луносвета",
  ["Simple Leaf Pruners"] = "Простые секаторы для листьев",
  ["Sin'dorei Enchanting Rod"] = "Жезл наложения чар син'дорай",
  ["Sin'dorei Gem Faceters"] = "Огранщики самоцветов син'дорай",
  ["Sin'dorei Master's Forgemace"] = "Кузнечная булава мастера син'дорай",
  ["Sin'dorei Masterwork Chisel"] = "Искусное долото син'дорай",
  ["Sin'dorei Outfitter's Ruler"] = "Линейка портного син'дорай",
  ["Sin'dorei Tanning Oil"] = "Дубильное масло син'дорай",
  ["Skill Issue: Enchanting"] = "Вопрос навыка: Наложение чар",
  ["Skill Issue: Jewelcrafting"] = "Вопрос навыка: Ювелирное дело",
  ["Skill Issue: Tailoring"] = "Вопрос мастерства: портняжное дело",
  ["Skinned Trophy 1"] = "Трофей снятия шкур 1",
  ["Skinned Trophy 2"] = "Трофей снятия шкур 2",
  ["Skinned Trophy 3"] = "Трофей снятия шкур 3",
  ["Skinned Trophy 4"] = "Трофей снятия шкур 4",
  ["Skinned Trophy 5"] = "Трофей снятия шкур 5",
  ["Skinning"] = "снятие шкур",
  ["Solid Ore Punchers"] = "Прочные рудные пробойники",
  ["Songwriter's Pen"] = "Перо песенника",
  ["Songwriter's Quill"] = "Писчее перо песенника",
  ["Spare Expedition Torch"] = "Запасной факел экспедиции",
  ["Spare Ink"] = "Запасные чернила",
  ["Speculative Voidstorm Crystal"] = "Необычный кристалл Бури Бездны",
  ["Spelunker's Lucky Charm"] = "Счастливый амулет спелеолога",
  ["Star Metal Deposit"] = "Залежь звёздного металла",
  ["Stats Overlay"] = "Оверлей характеристик",
  ["Supported Maps"] = "Поддерживаемые карты",
  ["Supported maps:"] = "Поддерживаемые карты:",
  ["Sweeping Harvester's Scythe"] = "Широкая коса жнеца",
  ["Tailoring"] = "портняжное дело",
  ["Template name"] = "Название шаблона",
  ["Thalassian Mana Oil"] = "Талассийское масло маны",
  ["Thalassian Skinning Knife"] = "Талассийский нож свежевателя",
  ["Thalassian Whestone"] = "Талассийский точильный камень",
  ["TomTom"] = "TomTom",
  ["Track Midnight profession knowledge with hidden-quest auto detection. Weekly quests, profession treatises, weekly drops, renown books, and one-time treasures scan automatically."] = "Отслеживает знания профессий Midnight через скрытые задания. Еженедельные задания, трактаты, еженедельный дроп, книги известности и одноразовые сокровища сканируются автоматически.",
  ["Traditions of the Haranir: Herbalism"] = "Традиции хараниров: травничество",
  ["Traditions of the Haranir: Inscription"] = "Традиции хараниров: Начертание",
  ["Traditions of the Haranir: Tailoring"] = "Традиции хараниров: портняжное дело",
  ["Trainer Weekly Quest"] = "Еженедельное задание тренера профессии",
  ["Trainer weekly quest"] = "Еженедельное задание тренера профессии",
  ["Trainer Еженедельное Quest"] = "Еженедельное задание тренера профессии",
  ["Tranquility Bloom"] = "цветок безмятежности",
  ["Treasure"] = "Сокровище",
  ["Treasures"] = "보물",
  ["Treatise"] = "Трактат",
  ["Umbral Tin"] = "теневое олово",
  ["Umbral Tin Seam"] = "Жила теневой оловянной руды",
  ["Undo Last Change"] = "Отменить последнее",
  ["Unfinished treasures"] = "Незавершённые сокровища",
  ["Unknown"] = "Неизвестно",
  ["Utility Features"] = "Утилиты",
  ["Versatility"] = "Универсальность",
  ["Vial of Eversong Oddities"] = "Флакон странностей Лесов Вечной Песни",
  ["Vial of Rootlands Oddities"] = "Флакон странностей Корнеземья",
  ["Vial of Voidstorm Oddities"] = "Флакон странностей Бури Бездны",
  ["Vial of Zul'Aman Oddities"] = "Флакон странностей Зул'Амана",
  ["Vintage Soul Gem"] = "Старинный самоцвет души",
  ["Void-Touched Eversong Diamond Fragments"] = "Осколки алмаза Вечной Песни, тронутые Бездной",
  ["Void-Touched Quill"] = "Перо, тронутое Бездной",
  ["Voidbound Argentleaf"] = "Скованный Бездной сребролист",
  ["Voidbound Azeroot"] = "Скованный Бездной азеритовый корень",
  ["Voidbound Brilliant Silver"] = "Скованное Бездной блистательное серебро",
  ["Voidbound Mana Lily"] = "Скованная Бездной маналилия",
  ["Voidbound Refulgent Copper"] = "Скованная Бездной сияющая медь",
  ["Voidbound Sanguithorn"] = "Скованный Бездной кровошип",
  ["Voidbound Tranquility Bloom"] = "Скованный Бездной цветок безмятежности",
  ["Voidbound Umbral Tin"] = "Скованная Бездной теневая оловянная руда",
  ["Voidbound Азеритовый корень"] = "Скованный Бездной азеритовый корень",
  ["Voidbound Кровошип"] = "Скованный Бездной кровошип",
  ["Voidbound Маналилия"] = "Скованная Бездной маналилия",
  ["Voidbound Сребролист"] = "Скованный Бездной сребролист",
  ["Voidbound Цветок безмятежности"] = "Скованный Бездной цветок безмятежности",
  ["Voidstorm"] = "Буря Бездны",
  ["Voidstorm Ashes"] = "Пепел Бури Бездны",
  ["Voidstorm Defense Spear"] = "Оборонительное копьё Бури Бездны",
  ["Voidstorm Leather Sample"] = "Образец кожи Бури Бездны",
  ["Waypoint"] = "Точка маршрута",
  ["Weekly"] = "주간",
  ["Weekly Quest"] = "Еженедельное задание",
  ["Weekly Sources"] = "Еженедельные источники",
  ["Weekly drop"] = "Еженедельный дроп",
  ["Weekly drops"] = "Еженедельный дроп",
  ["Weekly quest"] = "Еженедельное задание",
  ["Weekly reset"] = "Еженедельный сброс",
  ["What To Do When Nothing Works"] = "Что делать, когда ничего не работает",
  ["Whisper of the Loa: Leatherworking"] = "Шёпот лоа: Кожевничество",
  ["Whisper of the Loa: Mining"] = "Шёпот лоа: Горное дело",
  ["Whisper of the Loa: Skinning"] = "Шёпот лоа: Снятие шкур",
  ["Wild Argentleaf"] = "Дикий сребролист",
  ["Wild Azeroot"] = "Дикий азеритовый корень",
  ["Wild Brilliant Silver"] = "Дикое блистательное серебро",
  ["Wild Mana Lily"] = "Дикая маналилия",
  ["Wild Refulgent Copper"] = "Дикая сияющая медь",
  ["Wild Sanguithorn"] = "Дикий кровошип",
  ["Wild Tranquility Bloom"] = "Дикий цветок безмятежности",
  ["Wild Umbral Tin"] = "Дикая теневая оловянная руда",
  ["Wild Азеритовый корень"] = "Дикий азеритовый корень",
  ["Wild Кровошип"] = "Дикий кровошип",
  ["Wild Маналилия"] = "Дикая маналилия",
  ["Wild Сребролист"] = "Дикий сребролист",
  ["Wild Цветок безмятежности"] = "Дикий цветок безмятежности",
  ["Wooden Weaving Sowrd"] = "Деревянный ткацкий меч",
  ["Wooden Weaving Sword"] = "Деревянный ткацкий меч",
  ["Zul'Aman"] = "Зул'Аман",
  ["available"] = "доступно",
  ["day"] = "дн.",
  ["days"] = "дн.",
  ["hour"] = "ч.",
  ["hours"] = "ч.",
  ["minute"] = "мин.",
  ["minutes"] = "мин.",
  ["missing"] = "отсутствует",
  ["objective"] = "цель",
  ["objectives"] = "целей",
  ["point"] = "очко",
  ["points"] = "очков",
  ["reset"] = "сброс",
  ["selected"] = "выбранное",
  ["waypoint"] = "точка маршрута",
  ["waypoints"] = "точки маршрута",
  ["weekly reset"] = "еженедельного сброса",
  ["Алхимия"] = "연금술",
  ["Блок"] = "방패 막기",
  ["Горное дело"] = "채광",
  ["Дроп"] = "획득",
  ["Еженед."] = "주간",
  ["Еженедельно"] = "주간",
  ["Еженедельное Quest"] = "Еженедельное задание",
  ["Задание"] = "퀘스트",
  ["Известность"] = "영예",
  ["Изобилие"] = "풍요",
  ["Инженерное дело"] = "기계공학",
  ["Искусность"] = "특화",
  ["Кожевничество"] = "가죽세공",
  ["Крит"] = "치명타",
  ["Кузнечное дело"] = "대장기술",
  ["Наложение чар"] = "마법부여",
  ["Начертание"] = "주문각인",
  ["Одноразово"] = "1회",
  ["Открытия"] = "발견",
  ["Очки профессий"] = "전문 기술 점수",
  ["Парирование"] = "무기 막기",
  ["Портняжное дело"] = "재봉술",
  ["Разово"] = "1회",
  ["Скорость"] = "가속",
  ["Снятие шкур"] = "무두질",
  ["Сокровища"] = "보물",
  ["Травничество"] = "약초채집",
  ["Трактат"] = "논문",
  ["Уклонение"] = "회피",
  ["Универсальность"] = "유연성",
  ["Ювелирное дело"] = "보석세공",
  ["оч."] = "P",
  ["очков"] = "P",
  ["•"] = "-",
  ["←"] = "<-",
  ["→"] = "->",
  ["∙"] = "-",
  ["▶"] = ">",
  ["◀"] = "<",
  ["➔"] = "->",
  ["➜"] = "->",
  ["➡"] = "->",
  ["➤"] = "->",
  ["가죽세공"] = "Leatherworking",
  ["기계공학"] = "Engineering",
  ["대장기술"] = "Blacksmithing",
  ["마법부여"] = "Enchanting",
  ["무두질"] = "Skinning",
  ["보석세공"] = "Jewelcrafting",
  ["약초채집"] = "Herbalism",
  ["연금술"] = "Alchemy",
  ["재봉술"] = "Tailoring",
  ["주문각인"] = "Inscription",
  ["채광"] = "Mining",
}

local PROFESSION_NAMES = {
  ruRU = {
    ["Alchemy"] = "Алхимия",
    ["Blacksmithing"] = "Кузнечное дело",
    ["Enchanting"] = "Наложение чар",
    ["Engineering"] = "Инженерное дело",
    ["Herbalism"] = "Травничество",
    ["Inscription"] = "Начертание",
    ["Jewelcrafting"] = "Ювелирное дело",
    ["Leatherworking"] = "Кожевничество",
    ["Mining"] = "Горное дело",
    ["Skinning"] = "Снятие шкур",
    ["Tailoring"] = "Портняжное дело",
    ["Алхимия"] = "Алхимия",
    ["Горное дело"] = "Горное дело",
    ["Инженерное дело"] = "Инженерное дело",
    ["Кожевничество"] = "Кожевничество",
    ["Кузнечное дело"] = "Кузнечное дело",
    ["Наложение чар"] = "Наложение чар",
    ["Начертание"] = "Начертание",
    ["Портняжное дело"] = "Портняжное дело",
    ["Снятие шкур"] = "Снятие шкур",
    ["Травничество"] = "Травничество",
    ["Ювелирное дело"] = "Ювелирное дело",
    ["가죽세공"] = "Кожевничество",
    ["기계공학"] = "Инженерное дело",
    ["대장기술"] = "Кузнечное дело",
    ["마법부여"] = "Наложение чар",
    ["무두질"] = "Снятие шкур",
    ["보석세공"] = "Ювелирное дело",
    ["약초채집"] = "Травничество",
    ["연금술"] = "Алхимия",
    ["재봉술"] = "Портняжное дело",
    ["주문각인"] = "Начертание",
    ["채광"] = "Горное дело",
  },
  enUS = {
    ["Алхимия"] = "Alchemy",
    ["Горное дело"] = "Mining",
    ["Инженерное дело"] = "Engineering",
    ["Кожевничество"] = "Leatherworking",
    ["Кузнечное дело"] = "Blacksmithing",
    ["Наложение чар"] = "Enchanting",
    ["Начертание"] = "Inscription",
    ["Портняжное дело"] = "Tailoring",
    ["Снятие шкур"] = "Skinning",
    ["Травничество"] = "Herbalism",
    ["Ювелирное дело"] = "Jewelcrafting",
    ["가죽세공"] = "Leatherworking",
    ["기계공학"] = "Engineering",
    ["대장기술"] = "Blacksmithing",
    ["마법부여"] = "Enchanting",
    ["무두질"] = "Skinning",
    ["보석세공"] = "Jewelcrafting",
    ["약초채집"] = "Herbalism",
    ["연금술"] = "Alchemy",
    ["재봉술"] = "Tailoring",
    ["주문각인"] = "Inscription",
    ["채광"] = "Mining",
  },
  koKR = {
    ["Alchemy"] = "연금술",
    ["Blacksmithing"] = "대장기술",
    ["Enchanting"] = "마법부여",
    ["Engineering"] = "기계공학",
    ["Herbalism"] = "약초채집",
    ["Inscription"] = "주문각인",
    ["Jewelcrafting"] = "보석세공",
    ["Leatherworking"] = "가죽세공",
    ["Mining"] = "채광",
    ["Skinning"] = "무두질",
    ["Tailoring"] = "재봉술",
    ["Алхимия"] = "연금술",
    ["Горное дело"] = "채광",
    ["Инженерное дело"] = "기계공학",
    ["Кожевничество"] = "가죽세공",
    ["Кузнечное дело"] = "대장기술",
    ["Наложение чар"] = "마법부여",
    ["Начертание"] = "주문각인",
    ["Портняжное дело"] = "재봉술",
    ["Снятие шкур"] = "무두질",
    ["Травничество"] = "약초채집",
    ["Ювелирное дело"] = "보석세공",
  },
}

-- -----------------------------------------------------------------------------
-- 3. Small helpers
-- -----------------------------------------------------------------------------
local function merge(target, source)
  if type(target) ~= "table" or type(source) ~= "table" then
    return
  end
  for key, value in pairs(source) do
    target[key] = value
  end
end

local function wipeTable(tableRef)
  if type(wipe) == "function" then
    wipe(tableRef)
  elseif type(tableRef) == "table" then
    for key in pairs(tableRef) do
      tableRef[key] = nil
    end
  end
end

local function safeCall(object, methodName, ...)
  if object and type(object[methodName]) == "function" then
    return pcall(object[methodName], object, ...)
  end
  return false
end

local function refreshKnownABPMUI()
  -- Refresh only ABProfileManager components. Never scan UIParent or global game tooltips.
  if ns.UI then
    safeCall(ns.UI.MainWindow, "RefreshLocale")
    safeCall(ns.UI.ProfilePanel, "RefreshLocale")
    safeCall(ns.UI.ProfessionPanel, "Refresh")
    safeCall(ns.UI.ProfessionKnowledgeOverlay, "Refresh")
    safeCall(ns.UI.StatsOverlay, "Refresh")
    safeCall(ns.UI.SilvermoonMapOverlay, "Refresh")
    safeCall(ns.UI.UtilityPanel, "RefreshLocale")
  end
  if ns.RefreshUI then
    pcall(ns.RefreshUI, ns)
  end
end

-- -----------------------------------------------------------------------------
-- 4. Locale registration and fallback
-- -----------------------------------------------------------------------------
local function registerLocaleData()
  local Locale = ns.Locale
  if not Locale then
    return
  end

  Locale.strings = Locale.strings or {}
  Locale.classNames = Locale.classNames or {}
  Locale.specNames = Locale.specNames or {}

  Locale.strings.enUS = Locale.strings.enUS or {}
  Locale.strings.koKR = Locale.strings.koKR or {}
  Locale.strings.ruRU = Locale.strings.ruRU or {}
  Locale.classNames.ruRU = Locale.classNames.ruRU or {}
  Locale.specNames.ruRU = Locale.specNames.ruRU or {}

  Locale.strings.enUS.config_language_russian = Locale.strings.enUS.config_language_russian or "Russian"
  Locale.strings.koKR.config_language_russian = Locale.strings.koKR.config_language_russian or "러시아어"

  merge(Locale.strings.ruRU, LOCALE_STRINGS_RURU)
  merge(Locale.classNames.ruRU, CLASS_NAMES_RURU)
  merge(Locale.specNames.ruRU, SPEC_NAMES_RURU)
end

local function patchLocaleFallback()
  local Locale = ns.Locale
  if not Locale or Locale.__ABPM_RURU_FINAL_LOCALE_PATCHED then
    return
  end
  Locale.__ABPM_RURU_FINAL_LOCALE_PATCHED = true

  function Locale:IsSupportedLanguage(language)
    return SUPPORTED_LANGUAGES[language] and true or false
  end

  function Locale:GetDefaultLanguage()
    return getClientDefaultLanguage()
  end

  function Locale:NormalizeLanguage(language)
    return normalizeLanguage(language)
  end

  function Locale:GetCurrentLanguage()
    return getAddonLanguage()
  end

  function Locale:GetString(key)
    local language = self:GetCurrentLanguage()
    local bucket = self.strings and self.strings[language]
    local english = self.strings and self.strings.enUS
    return (bucket and bucket[key]) or (english and english[key]) or key
  end

  function Locale:GetClassName(classTag)
    if not classTag or classTag == "" then
      return "UNKNOWN"
    end
    local language = self:GetCurrentLanguage()
    local bucket = self.classNames and self.classNames[language]
    local english = self.classNames and self.classNames.enUS
    return (bucket and bucket[classTag]) or (english and english[classTag]) or classTag
  end

  function Locale:GetSpecName(specID, fallback)
    specID = tonumber(specID) or 0
    if specID <= 0 then
      return fallback
    end
    local language = self:GetCurrentLanguage()
    local bucket = self.specNames and self.specNames[language]
    local english = self.specNames and self.specNames.enUS
    return (bucket and bucket[specID]) or (english and english[specID]) or fallback or ("Spec " .. specID)
  end
end

-- -----------------------------------------------------------------------------
-- 5. DB language patch
-- -----------------------------------------------------------------------------
local function patchDefaultsAndDB()
  if ns.Data and ns.Data.Defaults and ns.Data.Defaults.global and ns.Data.Defaults.global.settings then
    ns.Data.Defaults.global.settings.language = getClientDefaultLanguage()
  end

  local DB = ns.DB
  if not DB or DB.__ABPM_RURU_FINAL_DB_PATCHED then
    return
  end
  DB.__ABPM_RURU_FINAL_DB_PATCHED = true

  local originalGetGlobalSettings = DB.GetGlobalSettings

  function DB:GetGlobalSettings()
    local settings = originalGetGlobalSettings and originalGetGlobalSettings(self) or nil
    if not settings then
      return settings
    end
    if not SUPPORTED_LANGUAGES[settings.language] then
      settings.language = getClientDefaultLanguage()
    end
    return settings
  end

  function DB:GetLanguage()
    local settings = self:GetGlobalSettings()
    local language = settings and settings.language or nil
    language = normalizeLanguage(language)
    if settings then
      settings.language = language
    end
    return language
  end

  function DB:SetLanguage(language)
    language = normalizeLanguage(language)
    local settings = self:GetGlobalSettings()
    if settings then
      settings.language = language
    end
    RURU.RefreshProfessionCaches()
    refreshKnownABPMUI()
    return language
  end
end

-- -----------------------------------------------------------------------------
-- 6. ConfigPanel language selector
-- -----------------------------------------------------------------------------
local function getLanguageLabel(language)
  if language == Constants.LANGUAGE.KOREAN then
    return ns.L and ns.L("config_language_korean") or "Korean"
  elseif language == Constants.LANGUAGE.RUSSIAN then
    return ns.L and ns.L("config_language_russian") or "Russian"
  end
  return ns.L and ns.L("config_language_english") or "English"
end

local function patchConfigPanel()
  local ConfigPanel = ns.UI and ns.UI.ConfigPanel
  local Widgets = ns.UI and ns.UI.Widgets
  if not ConfigPanel or not Widgets or ConfigPanel.__ABPM_RURU_FINAL_CONFIG_PATCHED then
    return
  end
  ConfigPanel.__ABPM_RURU_FINAL_CONFIG_PATCHED = true

  local originalApplyLanguage = ConfigPanel.ApplyLanguage
  function ConfigPanel:ApplyLanguage(language, refs)
    language = normalizeLanguage(language)
    if ns.DB and ns.DB.SetLanguage then
      ns.DB:SetLanguage(language)
      local message = ns.L and ns.L("config_saved_language", getLanguageLabel(language)) or ("Interface language changed to " .. language .. ".")
      local formatted = ns.Utils and ns.Utils.FormatStatusMessage and ns.Utils.FormatStatusMessage(message, "success") or message
      if refs and refs.statusText and refs.statusText.SetText then
        refs.statusText:SetText(formatted or "")
      end
      if ns.UI and ns.UI.MainWindow and ns.UI.MainWindow.SetStatus then
        pcall(ns.UI.MainWindow.SetStatus, ns.UI.MainWindow, message)
      end
      return
    end
    if originalApplyLanguage then
      return originalApplyLanguage(self, language, refs)
    end
  end

  local originalBuildControlSet = ConfigPanel.BuildControlSet
  function ConfigPanel:BuildControlSet(parent, options)
    local refs = originalBuildControlSet and originalBuildControlSet(self, parent, options) or nil
    if refs and refs.generalBox and refs.englishButton and not refs.russianButton then
      refs.russianButton = Widgets.CreateButton(refs.generalBox, "", 110, 26)
      refs.russianButton:SetPoint("LEFT", refs.englishButton, "RIGHT", 8, 0)
      refs.russianButton:SetScript("OnClick", function()
        self:ApplyLanguage(Constants.LANGUAGE.RUSSIAN, refs)
      end)
    end
    return refs
  end

  local originalBindControlSet = ConfigPanel.BindControlSet
  if originalBindControlSet then
    function ConfigPanel:BindControlSet(refs)
      originalBindControlSet(self, refs)
      if refs and refs.russianButton then
        refs.russianButton:SetScript("OnClick", function()
          self:ApplyLanguage(Constants.LANGUAGE.RUSSIAN, refs)
        end)
      end
    end
  end

  local originalRefreshControlSet = ConfigPanel.RefreshControlSet
  function ConfigPanel:RefreshControlSet(refs)
    if originalRefreshControlSet then
      originalRefreshControlSet(self, refs)
    end
    if not refs then
      return
    end
    if refs.koreanButton and refs.koreanButton.SetText then
      refs.koreanButton:SetText(ns.L("config_language_korean"))
    end
    if refs.englishButton and refs.englishButton.SetText then
      refs.englishButton:SetText(ns.L("config_language_english"))
    end
    if refs.russianButton and refs.russianButton.SetText then
      refs.russianButton:SetText(ns.L("config_language_russian"))
    end
    local current = ns.DB and ns.DB.GetLanguage and ns.DB:GetLanguage() or getAddonLanguage()
    if Widgets.SetButtonSelected then
      if refs.koreanButton then Widgets.SetButtonSelected(refs.koreanButton, current == Constants.LANGUAGE.KOREAN) end
      if refs.englishButton then Widgets.SetButtonSelected(refs.englishButton, current == Constants.LANGUAGE.ENGLISH) end
      if refs.russianButton then Widgets.SetButtonSelected(refs.russianButton, current == Constants.LANGUAGE.RUSSIAN) end
    end
  end
end

-- -----------------------------------------------------------------------------
-- 7. Status and scoped tooltip helpers
-- -----------------------------------------------------------------------------
local function patchStatusMessages()
  if not ns.Utils or ns.Utils.__ABPM_RURU_FINAL_STATUS_PATCHED then
    return
  end
  ns.Utils.__ABPM_RURU_FINAL_STATUS_PATCHED = true

  function ns.Utils.FormatStatusMessage(message, kind)
    local language = getAddonLanguage()
    message = tostring(message or "")
    if language == "ruRU" then
      if kind == "error" then return "Ошибка: " .. message end
      if kind == "success" then return "Успешно: " .. message end
      return "Инфо: " .. message
    elseif language == "enUS" then
      if kind == "error" then return "Error: " .. message end
      if kind == "success" then return "Success: " .. message end
      return "Info: " .. message
    end
    if kind == "error" then return "오류: " .. message end
    if kind == "success" then return "성공: " .. message end
    return "안내: " .. message
  end
end

local function translateProfessionText(text)
  if not isRuRU() or type(text) ~= "string" or text == "" then
    return text
  end

  local exact = OBJECTIVE_NAMES_RURU[text]
  if exact then
    return exact
  end

  local value = text
  -- ABPM helper tooltips only; this is not applied to global game tooltips.
  local replacements = {
    ["Trainer Weekly Quest"] = "Еженедельное задание тренера профессии",
    ["Weekly Quest"] = "Еженедельное задание",
    ["First discoveries"] = "Первые открытия",
    ["First Discoveries"] = "Первые открытия",
    ["Progress:"] = "Прогресс:",
    ["Pending:"] = "Ожидает:",
    ["Done:"] = "Выполнено:",
    [" objectives"] = " целей",
    [" objective"] = " цель",
    [" Points"] = " очков",
    [" Point"] = " очко",
    [" pts"] = " оч.",
    [" pt"] = " оч.",
  }
  for sourceText, ruText in pairs(replacements) do
    value = value:gsub(sourceText, ruText)
  end
  return value
end

local function patchABPMTooltipHelper()
  local Widgets = ns.UI and ns.UI.Widgets
  if not Widgets or type(Widgets.ApplyTooltip) ~= "function" or Widgets.__ABPM_RURU_FINAL_TOOLTIP_PATCHED then
    return
  end
  Widgets.__ABPM_RURU_FINAL_TOOLTIP_PATCHED = true

  local originalApplyTooltip = Widgets.ApplyTooltip
  function Widgets.ApplyTooltip(tip, ...)
    local results = { originalApplyTooltip(tip, ...) }
    if isRuRU() and tip and tip.GetName then
      local okName, name = pcall(tip.GetName, tip)
      if okName and type(name) == "string" and name ~= "" then
        for i = 1, 80 do
          local left = _G[name .. "TextLeft" .. i]
          local right = _G[name .. "TextRight" .. i]
          for _, line in ipairs({ left, right }) do
            if line and line.GetText and line.SetText then
              local okText, text = pcall(line.GetText, line)
              if okText and type(text) == "string" then
                local translated = translateProfessionText(text)
                if translated ~= text then
                  pcall(line.SetText, line, translated)
                end
              end
            end
          end
        end
        if tip.Show then pcall(tip.Show, tip) end
      end
    end
    return unpack(results)
  end
end

-- -----------------------------------------------------------------------------
-- 8. Profession Knowledge source-level localization
-- -----------------------------------------------------------------------------
local function upperFirstAsciiSafe(text)
  if type(text) ~= "string" or text == "" then
    return text
  end
  -- Cyrillic case conversion is not reliable in Lua 5.1; keep explicit map entries preferred.
  return text
end

local OBJECTIVE_BASE_RURU = {
  ["Tranquility Bloom"] = "цветок безмятежности",
  ["Sanguithorn"] = "кровошип",
  ["Azeroot"] = "азеритовый корень",
  ["Argentleaf"] = "сребролист",
  ["Mana Lily"] = "маналилия",
  ["Refulgent Copper"] = "сияющая медь",
  ["Umbral Tin"] = "теневая оловянная руда",
  ["Brilliant Silver"] = "блистательное серебро",
  ["Alchemy"] = "алхимия",
  ["Blacksmithing"] = "кузнечное дело",
  ["Engineering"] = "инженерное дело",
  ["Enchanting"] = "наложение чар",
  ["Herbalism"] = "травничество",
  ["Inscription"] = "начертание",
  ["Jewelcrafting"] = "ювелирное дело",
  ["Leatherworking"] = "кожевничество",
  ["Mining"] = "горное дело",
  ["Skinning"] = "снятие шкур",
  ["Tailoring"] = "портняжное дело",
}

local OBJECTIVE_PREFIX_RURU = {
  { pattern = "^Lush (.+)$", format = "Пышный %s" },
  { pattern = "^Lightfused (.+)$", format = "Озарённый Светом %s" },
  { pattern = "^Voidbound (.+)$", format = "Скованный Бездной %s" },
  { pattern = "^Primal (.+)$", format = "Изначальный %s" },
  { pattern = "^Wild (.+)$", format = "Дикий %s" },
  { pattern = "^Rich (.+)$", format = "Богатое %s" },
  { pattern = "^Beyond the Event Horizon: (.+)$", format = "За горизонтом событий: %s" },
  { pattern = "^Skill Issue: (.+)$", format = "Вопрос мастерства: %s" },
  { pattern = "^Whisper of the Loa: (.+)$", format = "Шёпот лоа: %s" },
  { pattern = "^Echo of Abundance: (.+)$", format = "Эхо изобилия: %s" },
  { pattern = "^Traditions of the Haranir: (.+)$", format = "Традиции хараниров: %s" },
}

local function getRuObjectiveName(name)
  if type(name) ~= "string" or name == "" then
    return name or ""
  end

  local exact = OBJECTIVE_NAMES_RURU[name]
  if exact then
    return exact
  end

  local index = name:match("^Gathered Herb Sample (%d+)$")
  if index then return "Образец собранной травы " .. index end
  index = name:match("^Mined Ore Sample (%d+)$")
  if index then return "Образец добытой руды " .. index end
  index = name:match("^Skinned Trophy (%d+)$")
  if index then return "Трофей снятия шкур " .. index end
  index = name:match("^Disenchant Drop (%d+)$")
  if index then return "Добыча от распыления " .. index end

  local seamBase = name:match("^(.+) Seam$")
  if seamBase and OBJECTIVE_BASE_RURU[seamBase] then
    return "Жила: " .. OBJECTIVE_BASE_RURU[seamBase]
  end

  for _, entry in ipairs(OBJECTIVE_PREFIX_RURU) do
    local baseName = name:match(entry.pattern)
    if baseName then
      local translatedBase = OBJECTIVE_BASE_RURU[baseName] or OBJECTIVE_NAMES_RURU[baseName]
      if translatedBase then
        return string.format(entry.format, translatedBase)
      end
    end
  end

  local base = OBJECTIVE_BASE_RURU[name]
  if base then
    return upperFirstAsciiSafe(base)
  end

  return name
end
RURU.GetRuObjectiveName = getRuObjectiveName

local function normalizeProfessionDisplayName(name)
  if type(name) ~= "string" or name == "" then
    return name
  end
  local language = getAddonLanguage()
  local bucket = PROFESSION_NAMES[language]
  return (bucket and bucket[name]) or name
end
RURU.NormalizeProfessionDisplayName = normalizeProfessionDisplayName

function RURU.RefreshProfessionCaches()
  local tracker = ns.Modules and ns.Modules.ProfessionKnowledgeTracker
  if not tracker then
    return
  end
  if tracker.evaluationCache then wipeTable(tracker.evaluationCache) end
  if tracker.sectionSummaryCache then wipeTable(tracker.sectionSummaryCache) end
  if tracker.professionSummaryCache then wipeTable(tracker.professionSummaryCache) end
  tracker.questCacheGeneration = (tonumber(tracker.questCacheGeneration) or 0) + 1
  if type(tracker.InvalidateProfessionCache) == "function" then
    pcall(tracker.InvalidateProfessionCache, tracker)
  end
end

local function patchProfessionTracker()
  local tracker = ns.Modules and ns.Modules.ProfessionKnowledgeTracker
  if not tracker or tracker.__ABPM_RURU_FINAL_TRACKER_PATCHED then
    return
  end
  tracker.__ABPM_RURU_FINAL_TRACKER_PATCHED = true

  local originalGetObjectiveDisplayName = tracker.GetObjectiveDisplayName
  function tracker:GetObjectiveDisplayName(objective)
    if not objective then
      return ""
    end
    if isRuRU() then
      return getRuObjectiveName(objective.name or "")
    end
    if originalGetObjectiveDisplayName then
      return originalGetObjectiveDisplayName(self, objective)
    end
    return objective.name or ""
  end

  local originalGetProfessionDisplayName = tracker.GetProfessionDisplayName
  function tracker:GetProfessionDisplayName(professionEntry)
    local name = nil
    if originalGetProfessionDisplayName then
      name = originalGetProfessionDisplayName(self, professionEntry)
    elseif professionEntry and professionEntry.name then
      name = professionEntry.name
    elseif professionEntry and professionEntry.definition then
      name = ns.L(professionEntry.definition.labelKey)
    end
    return normalizeProfessionDisplayName(name or "")
  end

  RURU.RefreshProfessionCaches()
end

-- -----------------------------------------------------------------------------
-- 9. Map labels, stats overlay and other source-level helpers
-- -----------------------------------------------------------------------------
function RURU.GetMapLabel(label)
  if not isRuRU() or type(label) ~= "string" then
    return label
  end
  return OBJECTIVE_NAMES_RURU[label] or label
end

local function patchScrollButtonSymbols()
  local panel = ns.UI and ns.UI.ProfilePanel
  if not panel then return end
  if panel.upButton and panel.upButton.SetText then pcall(panel.upButton.SetText, panel.upButton, "^") end
  if panel.downButton and panel.downButton.SetText then pcall(panel.downButton.SetText, panel.downButton, "v") end
end

local function patchProfilePanelRefresh()
  local panel = ns.UI and ns.UI.ProfilePanel
  if not panel or panel.__ABPM_RURU_FINAL_PROFILE_PATCHED then return end
  panel.__ABPM_RURU_FINAL_PROFILE_PATCHED = true

  local function replaceLeadingArrow(text)
    if not isRuRU() or type(text) ~= "string" or text == "" then
      return text
    end
    -- Use ASCII in ruRU because the default ruRU font can render the triangle as a square.
    return (text:gsub("^▶%s*", "> "))
  end

  local function normalizeButtonArrow(button)
    if not button or not button.GetText or not button.SetText then return end
    local okText, text = pcall(button.GetText, button)
    if not okText or type(text) ~= "string" or text == "" then return end
    local normalized = replaceLeadingArrow(text)
    if normalized ~= text then
      pcall(button.SetText, button, normalized)
    end
  end

  local originalRefreshLocale = panel.RefreshLocale
  if originalRefreshLocale then
    function panel:RefreshLocale(...)
      local results = { originalRefreshLocale(self, ...) }
      patchScrollButtonSymbols()
      return unpack(results)
    end
  end

  local originalRefreshSpecButtons = panel.RefreshSpecButtons
  if type(originalRefreshSpecButtons) == "function" then
    function panel:RefreshSpecButtons(...)
      local results = { originalRefreshSpecButtons(self, ...) }
      if self.specButtons then
        for _, button in ipairs(self.specButtons) do
          normalizeButtonArrow(button)
        end
      end
      return unpack(results)
    end
  end

  local originalPopulateRows = panel.PopulateRows
  if type(originalPopulateRows) == "function" then
    function panel:PopulateRows(...)
      local results = { originalPopulateRows(self, ...) }
      if self.templateRows then
        for _, row in ipairs(self.templateRows) do
          normalizeButtonArrow(row)
        end
      end
      return unpack(results)
    end
  end
end


-- -----------------------------------------------------------------------------
-- 10. Targeted overlay refresh helpers
-- -----------------------------------------------------------------------------
local CLASS_TEXT_BY_LANGUAGE = {
  ruRU = {
    ["Druid"] = "Друид", ["Warrior"] = "Воин", ["Paladin"] = "Паладин", ["Hunter"] = "Охотник",
    ["Rogue"] = "Разбойник", ["Priest"] = "Жрец", ["Death Knight"] = "Рыцарь смерти", ["Shaman"] = "Шаман",
    ["Mage"] = "Маг", ["Warlock"] = "Чернокнижник", ["Monk"] = "Монах", ["Demon Hunter"] = "Охотник на демонов", ["Evoker"] = "Пробудитель",
  },
  enUS = {
    ["Друид"] = "Druid", ["Воин"] = "Warrior", ["Паладин"] = "Paladin", ["Охотник"] = "Hunter",
    ["Разбойник"] = "Rogue", ["Жрец"] = "Priest", ["Рыцарь смерти"] = "Death Knight", ["Шаман"] = "Shaman",
    ["Маг"] = "Mage", ["Чернокнижник"] = "Warlock", ["Монах"] = "Monk", ["Охотник на демонов"] = "Demon Hunter", ["Пробудитель"] = "Evoker",
  },
  koKR = {
    ["Друид"] = "드루이드", ["Воин"] = "전사", ["Паладин"] = "성기사", ["Охотник"] = "사냥꾼",
    ["Разбойник"] = "도적", ["Жрец"] = "사제", ["Рыцарь смерти"] = "죽음의 기사", ["Шаман"] = "주술사",
    ["Маг"] = "마법사", ["Чернокнижник"] = "흑마법사", ["Монах"] = "수도사", ["Охотник на демонов"] = "악마사냥꾼", ["Пробудитель"] = "기원사",
    ["Druid"] = "드루이드", ["Warrior"] = "전사", ["Paladin"] = "성기사", ["Hunter"] = "사냥꾼",
    ["Rogue"] = "도적", ["Priest"] = "사제", ["Death Knight"] = "죽음의 기사", ["Shaman"] = "주술사",
    ["Mage"] = "마법사", ["Warlock"] = "흑마법사", ["Monk"] = "수도사", ["Demon Hunter"] = "악마사냥꾼", ["Evoker"] = "기원사",
  },
}

local STAT_TEXT_BY_LANGUAGE = {
  ruRU = {
    ["Crit"] = "Крит", ["Haste"] = "Скорость", ["Mastery"] = "Искусность", ["Versatility"] = "Универсальность",
    ["Dodge"] = "Уклонение", ["Parry"] = "Парирование", ["Block"] = "Блок",
  },
  enUS = {
    ["Крит"] = "Crit", ["Скорость"] = "Haste", ["Искусность"] = "Mastery", ["Универсальность"] = "Versatility",
    ["Уклонение"] = "Dodge", ["Парирование"] = "Parry", ["Блок"] = "Block",
  },
  koKR = {
    ["Крит"] = "치명", ["Скорость"] = "가속", ["Искусность"] = "특화", ["Универсальность"] = "유연",
    ["Уклонение"] = "회피", ["Парирование"] = "무기 막기", ["Блок"] = "방패 막기",
    ["Crit"] = "치명", ["Haste"] = "가속", ["Mastery"] = "특화", ["Versatility"] = "유연",
    ["Dodge"] = "회피", ["Parry"] = "무기 막기", ["Block"] = "방패 막기",
  },
}

local function translateOverlayLine(text, map)
  if type(text) ~= "string" or type(map) ~= "table" then
    return text
  end
  local value = text
  for from, to in pairs(map) do
    value = value:gsub(from, to)
  end
  return value
end

local function patchTextRegions(frame, depth, translator)
  if not frame or depth > 8 then return end
  if frame.GetRegions then
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
      if region and region.GetObjectType and region:GetObjectType() == "FontString" and region.GetText and region.SetText then
        local okText, text = pcall(region.GetText, region)
        if okText and type(text) == "string" and text ~= "" then
          local newText = translator(text)
          if type(newText) == "string" and newText ~= text then
            pcall(region.SetText, region, newText)
          end
        end
      end
    end
  end
  if frame.GetChildren then
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
      patchTextRegions(child, depth + 1, translator)
    end
  end
end

local function patchStatsOverlayText()
  local overlay = ns.UI and ns.UI.StatsOverlay
  local frame = overlay and overlay.frame
  if not frame then return end
  local language = getAddonLanguage()
  local classMap = CLASS_TEXT_BY_LANGUAGE[language] or {}
  local statMap = STAT_TEXT_BY_LANGUAGE[language] or {}
  patchTextRegions(frame, 0, function(text)
    local value = translateOverlayLine(text, classMap)
    value = translateOverlayLine(value, statMap)
    return value
  end)
end

local function patchStatsOverlayRefresh()
  local overlay = ns.UI and ns.UI.StatsOverlay
  if not overlay or overlay.__ABPM_RURU_FINAL_STATS_PATCHED then return end
  overlay.__ABPM_RURU_FINAL_STATS_PATCHED = true
  local originalRefresh = overlay.Refresh
  if type(originalRefresh) == "function" then
    function overlay:Refresh(...)
      local results = { originalRefresh(self, ...) }
      patchStatsOverlayText()
      return unpack(results)
    end
  end
end

-- -----------------------------------------------------------------------------
-- 10. Initialization
-- -----------------------------------------------------------------------------
local function applyAllPatches()
  registerLocaleData()
  patchLocaleFallback()
  patchDefaultsAndDB()
  patchConfigPanel()
  patchStatusMessages()
  patchABPMTooltipHelper()
  patchProfessionTracker()
  patchProfilePanelRefresh()
  patchStatsOverlayRefresh()
  patchStatsOverlayText()
  patchScrollButtonSymbols()
end

applyAllPatches()

if C_Timer and C_Timer.After then
  C_Timer.After(0, applyAllPatches)
  C_Timer.After(0.5, function()
    applyAllPatches()
    refreshKnownABPMUI()
  end)
end

-- Drop static locale source tables after merge. Runtime maps stay available.
LOCALE_STRINGS_RURU = nil
CLASS_NAMES_RURU = nil
SPEC_NAMES_RURU = nil
