"use strict";

(function (global) {
  const LANG_KEY = "tooo-lang";

  const PIC_SERIES_LABELS = {
    en: {
      "визуальные искусства": "visual arts",
      музыка: "music",
      img_1: "images 1",
      img_2: "images 2",
      img_4: "images 4",
    },
  };

  const STRINGS = {
    ru: {
      pageTitle: "Игра",
      noData1:
        "Нет данных для игры. Добавьте папку pics с подпапками-сериями; в каждой серии файлы 1.png … 8.png (класс = номер в имени). Имя папки = название набора в игре.",
      noData2:
        "Запустите build-game-data.ps1 или launch.bat. Старые img_* можно перенести скриптом migrate-legacy-img-to-pics.ps1.",
      howMeasure: "Как мы измеряем сложность",
      rowsAria: "Выбор строки или клавиши 1–8",
      message: "Сообщение",
      tasks: "Заданий",
      errors: "Ошибок",
      tasksShort: "Зад.",
      errorsShort: "Ош.",
      next: "Далее",
      series: "Серии",
      seriesHint:
        "Нажмите название — игра только из этой серии (слов или картинок). Можно отметить галочками несколько серий в обоих разделах и нажать ОК — сначала пойдут выбранные словесные серии, затем картиночные.",
      allSeries: "Все серии и картинки",
      cancel: "Отмена",
      ok: "ОК",
      writeAuthor: "Написать автору",
      feedbackHint:
        "Кнопка «Почта» откроет письмо на jfeldman777@gmail.com (или черновик на GitHub). Текст ниже попадёт в тело письма или в описание задачи.",
      feedbackLabel: "Сообщение",
      feedbackPlaceholder: "Текст сообщения…",
      close: "Закрыть",
      copy: "Скопировать",
      mail: "Почта",
      supportTitle: "Поддержать автора",
      supportIntro:
        "Если вам понравились игры, вы можете поблагодарить автора — перечислить ему любую сумму. Спасибо, что играете.",
      supportRussia: "Для тех, кто в России",
      supportPhone: "Телефон для перевода (в т.ч. СБП):",
      supportPayee: "Получатель: Яков Ф.",
      supportOthers: "Для всех остальных",
      supportPaypalAddr: "Адрес получателя:",
      supportPaypalHint:
        "В приложении или на сайте PayPal укажите этот e-mail у получателя платежа.",
      book: "Книга",
      seriesList: "Список серий",
      seriesFabTitle: "Серии (слова и картинки)",
      summarize: "Подвести итог",
      feedbackFabTitle: "Форма обратной связи — написать автору",
      donateAria: "Поддержать автора — донат",
      donateTitle: "Поддержать автора (Сбербанк, PayPal)",
      wordSeries: "Словесные серии",
      picSeries: "Картиночные серии",
      seriesN: "Серия {n}",
      seriesNHint: "Серия {n} — «{hint}»",
      setN: "Набор {n}",
      setMeta: "Набор: {id} · картинок: {n}",
      briefingTitle: "Как мы измеряем сложность",
      briefingP1:
        "Мы с детства, сами того не замечая, делим ситуации на классы сложности. Этих классов восемь, и я обозначил их номерами и квадратами с пиктограммой.",
      briefingP2:
        "Ваша задача — отнести ситуацию на картинке к одному из классов; то же самое — с фразами и ключевыми словами. Выбрав класс слева, нажмите на клавишу.",
      gotIt: "Понятно",
      end: "КОНЕЦ",
      again: "СНАЧАЛА",
      downloadLog: "Скачать log.txt",
      reviewErrors: "Повторить случаи с ошибками ({n})",
      wrongKey: "Не та клавиша",
      correct: "Верно!",
      wrongRow: "Не та строка",
      keyN: "Клавиша {n}",
      hintN: "Подсказка {n}",
      seriesColon: "серия: {name}",
      reviewProg: "Повтор ошибок · {cur} из {total}",
      stepProg: "Шаг {cur} из 8 — нажмите правильную клавишу",
      pickSeries: "Отметьте хотя бы одну серию…",
      feedbackPage: "Страница: {page}",
      feedbackEmpty: "(сообщение без текста)",
      feedbackSubject: "Игра tooo — обратная связь",
      copied: "Скопировано",
      copyFail: "Не удалось скопировать",
      bookPageTitle: "Книга",
      toc: "Оглавление",
      tocHint:
        'В каждой строке кнопка с «T» — титул (<code>book/book-titles.json</code>). При первом сохранении выберите папку <code>book</code> проекта; заголовки дублируются в браузере и не пропадут после F5.',
      edit: "Редактировать",
      save: "Сохранить",
      newTxt: "Новая текстовая страница",
      newImg: "Новая картинка PNG",
      pickPng: "Выбрать PNG",
      pageTitleDialog: "Титул страницы",
      back: "Назад",
      forward: "Вперёд",
      toToc: "К оглавлению",
      toGame: "К игре",
    },
    en: {
      pageTitle: "Game",
      noData1:
        "No game data. Add a pics folder with series subfolders; each series needs 1.png … 8.png (class = number in the filename). Folder name = set title in the game.",
      noData2:
        "Run build-game-data.ps1 or launch.bat. Legacy img_* folders can be migrated with migrate-legacy-img-to-pics.ps1.",
      howMeasure: "How we measure complexity",
      rowsAria: "Choose a row or keys 1–8",
      message: "Message",
      tasks: "Tasks",
      errors: "Errors",
      tasksShort: "Tasks",
      errorsShort: "Err.",
      next: "Next",
      series: "Series",
      seriesHint:
        "Click a title to play only that series (words or pictures). Or tick several series in both sections and press OK — selected word series first, then picture series.",
      allSeries: "All series and pictures",
      cancel: "Cancel",
      ok: "OK",
      writeAuthor: "Write to the author",
      feedbackHint:
        "Mail opens a message to jfeldman777@gmail.com (or a GitHub draft). The text below goes into the email body or issue description.",
      feedbackLabel: "Message",
      feedbackPlaceholder: "Message text…",
      close: "Close",
      copy: "Copy",
      mail: "Mail",
      supportTitle: "Support the author",
      supportIntro:
        "If you enjoyed the games, you can thank the author with any amount. Thanks for playing.",
      supportRussia: "For those in Russia",
      supportPhone: "Phone for transfer (incl. SBP):",
      supportPayee: "Payee: Yakov F.",
      supportOthers: "For everyone else",
      supportPaypalAddr: "Payee address:",
      supportPaypalHint:
        "In the PayPal app or website, enter this e-mail as the payment recipient.",
      book: "Book",
      seriesList: "Series list",
      seriesFabTitle: "Series (words and pictures)",
      summarize: "Show summary",
      feedbackFabTitle: "Feedback form — write to the author",
      donateAria: "Support the author — donate",
      donateTitle: "Support the author (Sberbank, PayPal)",
      wordSeries: "Word series",
      picSeries: "Picture series",
      seriesN: "Series {n}",
      seriesNHint: "Series {n} — “{hint}”",
      setN: "Set {n}",
      setMeta: "Set: {id} · images: {n}",
      briefingTitle: "How we measure complexity",
      briefingP1:
        "From childhood, often without noticing, we sort situations into complexity classes. There are eight of them; I mark them with numbers and icon squares.",
      briefingP2:
        "Your task is to assign the picture to one of the classes — and the same for phrases and keywords. Choose a class on the left, then press the key.",
      gotIt: "Got it",
      end: "THE END",
      again: "AGAIN",
      downloadLog: "Download log.txt",
      reviewErrors: "Retry mistaken cases ({n})",
      wrongKey: "Wrong key",
      correct: "Correct!",
      wrongRow: "Wrong row",
      keyN: "Key {n}",
      hintN: "Hint {n}",
      seriesColon: "series: {name}",
      reviewProg: "Error review · {cur} of {total}",
      stepProg: "Step {cur} of 8 — press the correct key",
      pickSeries: "Select at least one series…",
      feedbackPage: "Page: {page}",
      feedbackEmpty: "(empty message)",
      feedbackSubject: "tooo game — feedback",
      copied: "Copied",
      copyFail: "Could not copy",
      bookPageTitle: "Book",
      toc: "Contents",
      tocHint:
        'Each row\u2019s \u201cT\u201d button sets the page title (<code>book/book-titles.json</code>). On first save, pick the project\u2019s <code>book</code> folder \u2014 titles are also cached in the browser, so they survive a refresh.',
      edit: "Edit",
      save: "Save",
      newTxt: "New text page",
      newImg: "New PNG image",
      pickPng: "Choose PNG",
      pageTitleDialog: "Page title",
      back: "Back",
      forward: "Forward",
      toToc: "Contents",
      toGame: "To game",
    },
  };

  function detectLang() {
    const fromUrl = new URLSearchParams(location.search).get("lang");
    if (fromUrl === "en" || fromUrl === "ru") return fromUrl;
    try {
      const saved = localStorage.getItem(LANG_KEY);
      if (saved === "en" || saved === "ru") return saved;
    } catch (e) {}
    return "ru";
  }

  let currentLang = detectLang();

  function t(key, vars) {
    const table = STRINGS[currentLang] || STRINGS.ru;
    let text = table[key] ?? STRINGS.ru[key] ?? key;
    if (vars) {
      text = text.replace(/\{(\w+)\}/g, function (_, name) {
        return vars[name] != null ? String(vars[name]) : "{" + name + "}";
      });
    }
    return text;
  }

  function setLang(lang) {
    if (lang !== "ru" && lang !== "en") return;
    currentLang = lang;
    try {
      localStorage.setItem(LANG_KEY, lang);
    } catch (e) {}
    document.documentElement.lang = lang;
    applyStatic();
    if (typeof global.toooOnLangChange === "function") {
      global.toooOnLangChange(lang);
    }
  }

  function picSeriesLabel(id) {
    const raw = id != null ? String(id).trim() : "";
    if (!raw) return "";
    const map = PIC_SERIES_LABELS[currentLang];
    if (map && map[raw]) return map[raw];
    return raw;
  }

  function wordsUrl() {
    return currentLang === "en" ? "txt2img/words.en.txt" : "txt2img/words.txt";
  }

  function bookUrl() {
    const base = "book.html";
    return currentLang === "en" ? base + "?lang=en" : base + "?lang=ru";
  }

  function applyStatic() {
    document.title = t("pageTitle");
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      const key = el.getAttribute("data-i18n");
      if (key) el.textContent = t(key);
    });
    document.querySelectorAll("[data-i18n-html]").forEach(function (el) {
      const key = el.getAttribute("data-i18n-html");
      if (key) el.innerHTML = t(key);
    });
    document.querySelectorAll("[data-i18n-title]").forEach(function (el) {
      const key = el.getAttribute("data-i18n-title");
      if (key) el.title = t(key);
    });
    document.querySelectorAll("[data-i18n-aria]").forEach(function (el) {
      const key = el.getAttribute("data-i18n-aria");
      if (key) el.setAttribute("aria-label", t(key));
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach(function (el) {
      const key = el.getAttribute("data-i18n-placeholder");
      if (key) el.setAttribute("placeholder", t(key));
    });
    document.querySelectorAll("[data-lang-set]").forEach(function (btn) {
      const active = btn.getAttribute("data-lang-set") === currentLang;
      btn.classList.toggle("is-active", active);
      btn.setAttribute("aria-pressed", String(active));
    });
    const bookFab = document.getElementById("book-fab");
    if (bookFab) bookFab.href = bookUrl();
  }

  global.toooI18n = {
    t: t,
    getLang: function () {
      return currentLang;
    },
    setLang: setLang,
    applyStatic: applyStatic,
    picSeriesLabel: picSeriesLabel,
    wordsUrl: wordsUrl,
    bookUrl: bookUrl,
    LANG_KEY: LANG_KEY,
  };

  document.documentElement.lang = currentLang;
})(window);
