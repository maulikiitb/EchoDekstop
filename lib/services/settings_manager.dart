import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../ytmusic/ytmusic.dart';

Box _box = Hive.box('SETTINGS');

class SettingsManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final List<ThemeMode> _themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark
  ];
  late Map<String, String> _location;
  late Map<String, String> _language;
  bool _autofetchSongs = true;
  final List<AudioQuality> _audioQualities = [
    AudioQuality.high,
    AudioQuality.low
  ];

  AudioQuality _streamingQuality = AudioQuality.high;
  AudioQuality _downloadQuality = AudioQuality.high;
  bool _skipSilence = false;
  Color? _accentColor;
  bool _amoledBlack = true;
  bool _dynamicColors = false;
  bool _equalizerEnabled = false;
  List<double> _equalizerBandsGain = [];
  bool _loudnessEnabled = false;
  double _loudnessTargetGain = 0.0;

  // Desktop customisation
  double _textScale = 1.0;
  int _sidebarStyle = 0; // 0 = auto, 1 = compact, 2 = expanded
  double _cornerRadius = 20.0;
  bool _keyboardShortcuts = true;

  double get textScale => _textScale;
  int get sidebarStyle => _sidebarStyle;
  double get cornerRadius => _cornerRadius;
  bool get keyboardShortcuts => _keyboardShortcuts;

  ThemeMode get themeMode => _themeMode;
  List<ThemeMode> get themeModes => _themeModes;
  Map<String, String> get location => _location;
  List<Map<String, String>> get locations => _countries;
  Map<String, String> get language => _language;
  bool get autofetchSongs => _autofetchSongs;
  List<Map<String, String>> get languages => _languages;
  List<AudioQuality> get audioQualities => _audioQualities;
  AudioQuality get streamingQuality => _streamingQuality;
  AudioQuality get downloadQuality => _downloadQuality;
  bool get skipSilence => _skipSilence;

  Color? get accentColor => _accentColor;
  bool get amoledBlack => _amoledBlack;
  bool get dynamicColors => _dynamicColors;
  bool get equalizerEnabled => _equalizerEnabled;
  List<double> get equalizerBandsGain => _equalizerBandsGain;
  bool get loudnessEnabled => _loudnessEnabled;
  double get loudnessTargetGain => _loudnessTargetGain;

  Map get settings => _box.toMap();
  SettingsManager() {
    _init();
  }
  _init() {
    _themeMode = _themeModes[_box.get('THEME_MODE', defaultValue: 0)];
    _language = _languages.firstWhere((language) =>
        language['value'] == _box.get('LANGUAGE', defaultValue: 'en-IN'));
    _autofetchSongs = _box.get('AUTOFETCH_SONGS', defaultValue: true);
    _accentColor = _box.get('ACCENT_COLOR') != null
        ? Color(_box.get('ACCENT_COLOR'))
        : null;
    _amoledBlack = _box.get('AMOLED_BLACK', defaultValue: true);
    _dynamicColors = _box.get('DYNAMIC_COLORS', defaultValue: false);

    _location = _countries.firstWhere((country) =>
        country['value'] == _box.get('LOCATION', defaultValue: 'IN'));

    _streamingQuality =
        _audioQualities[_box.get('STREAMING_QUALITY', defaultValue: 0)];
    _downloadQuality =
        _audioQualities[_box.get('DOWNLOAD_QUALITY', defaultValue: 0)];
    _skipSilence = _box.get('SKIP_SILENCE', defaultValue: false);
    _equalizerEnabled = _box.get('EQUALIZER_ENABLED', defaultValue: false);
    _loudnessEnabled = _box.get('LOUDNESS_ENABLED', defaultValue: false);
    _loudnessTargetGain = _box.get('LOUDNESS_TARGET_GAIN', defaultValue: 0.0);
    _equalizerBandsGain =
        _box.get('EQUALIZER_BANDS_GAIN', defaultValue: []).cast<double>();
    _textScale =
        (_box.get('TEXT_SCALE', defaultValue: 1.0) as num).toDouble();
    _sidebarStyle = _box.get('SIDEBAR_STYLE', defaultValue: 0);
    _cornerRadius =
        (_box.get('CORNER_RADIUS', defaultValue: 20.0) as num).toDouble();
    _keyboardShortcuts = _box.get('KEYBOARD_SHORTCUTS', defaultValue: true);
  }

  set textScale(double v) {
    _box.put('TEXT_SCALE', v);
    _textScale = v;
    notifyListeners();
  }

  set sidebarStyle(int v) {
    _box.put('SIDEBAR_STYLE', v);
    _sidebarStyle = v;
    notifyListeners();
  }

  set cornerRadius(double v) {
    _box.put('CORNER_RADIUS', v);
    _cornerRadius = v;
    notifyListeners();
  }

  set keyboardShortcuts(bool v) {
    _box.put('KEYBOARD_SHORTCUTS', v);
    _keyboardShortcuts = v;
    notifyListeners();
  }

  // ---- Look & feel (stored directly in the settings box) ----
  double _d(String k, double def) =>
      (_box.get(k, defaultValue: def) as num).toDouble();
  void _set(String k, Object? v) {
    _box.put(k, v);
    notifyListeners();
  }

  /// 0 solid, 1 gradient, 2 aurora, 3 album art
  int get backgroundStyle => _box.get('BACKGROUND_STYLE', defaultValue: 3);
  set backgroundStyle(int v) => _set('BACKGROUND_STYLE', v);
  bool get backgroundAnimated =>
      _box.get('BACKGROUND_ANIMATED', defaultValue: true);
  set backgroundAnimated(bool v) => _set('BACKGROUND_ANIMATED', v);
  double get backgroundDim => _d('BACKGROUND_DIM', 0.6);
  set backgroundDim(double v) => _set('BACKGROUND_DIM', v);

  bool get glassEnabled => _box.get('GLASS_ENABLED', defaultValue: true);
  set glassEnabled(bool v) => _set('GLASS_ENABLED', v);
  double get glassBlur => _d('GLASS_BLUR', 18);
  set glassBlur(double v) => _set('GLASS_BLUR', v);
  double get glassOpacity => _d('GLASS_OPACITY', 0.22);
  set glassOpacity(double v) => _set('GLASS_OPACITY', v);

  String get fontFamily => _box.get('FONT_FAMILY', defaultValue: 'Poppins');
  set fontFamily(String v) => _set('FONT_FAMILY', v);
  double get letterSpacing => _d('LETTER_SPACING', 0);
  set letterSpacing(double v) => _set('LETTER_SPACING', v);
  double get wordSpacing => _d('WORD_SPACING', 0);
  set wordSpacing(double v) => _set('WORD_SPACING', v);

  /// 0 none, 1 mica, 2 acrylic, 3 tabbed (Windows only)
  int get windowMaterial => _box.get('WINDOW_MATERIAL', defaultValue: 0);
  set windowMaterial(int v) => _set('WINDOW_MATERIAL', v);

  double get lyricsScale => _d('LYRICS_SCALE', 1.0);
  set lyricsScale(double v) => _set('LYRICS_SCALE', v);
  double get lyricsGlow => _d('LYRICS_GLOW', 1.0);
  set lyricsGlow(double v) => _set('LYRICS_GLOW', v);

  /// Recolour the whole UI from the current song's artwork.
  bool get artAccent => _box.get('ART_ACCENT', defaultValue: false);
  set artAccent(bool v) => _set('ART_ACCENT', v);

  /// 0 left, 1 centre, 2 right
  int get lyricsAlign => _box.get('LYRICS_ALIGN', defaultValue: 1);
  set lyricsAlign(int v) => _set('LYRICS_ALIGN', v);

  double get playbackSpeed => _d('PLAYBACK_SPEED', 1.0);
  set playbackSpeed(double v) => _set('PLAYBACK_SPEED', v);

  /// Restores every appearance option to its default.
  void resetAppearance() {
    for (final k in [
      'THEME_MODE', 'ACCENT_COLOR', 'AMOLED_BLACK', 'DYNAMIC_COLORS',
      'TEXT_SCALE', 'SIDEBAR_STYLE', 'CORNER_RADIUS', 'BACKGROUND_STYLE',
      'BACKGROUND_ANIMATED', 'BACKGROUND_DIM', 'GLASS_ENABLED', 'GLASS_BLUR',
      'GLASS_OPACITY', 'FONT_FAMILY', 'LETTER_SPACING', 'WORD_SPACING',
      'WINDOW_MATERIAL', 'LYRICS_SCALE', 'LYRICS_GLOW', 'ART_ACCENT', 'LYRICS_ALIGN'
    ]) {
      _box.delete(k);
    }
    _init();
    notifyListeners();
  }

  setThemeMode(ThemeMode mode) async {
    _box.put('THEME_MODE', _themeModes.indexOf(mode));
    _themeMode = mode;

    notifyListeners();
  }

  set location(Map<String, String> value) {
    _box.put('LOCATION', value['value']);
    _location = value;
    GetIt.I<YTMusic>().refreshContext();
    notifyListeners();
  }

  set language(Map<String, String> value) {
    _box.put('LANGUAGE', value['value']);
    _language = value;
    GetIt.I<YTMusic>().refreshContext();
    notifyListeners();
  }

  set autofetchSongs(bool value) {
    _box.put('AUTOFETCH_SONGS', value);
    _autofetchSongs = value;
    notifyListeners();
  }

  set streamingQuality(AudioQuality value) {
    _box.put('STREAMING_QUALITY', _audioQualities.indexOf(value));
    _streamingQuality = value;
    notifyListeners();
  }

  set downloadQuality(AudioQuality value) {
    _box.put('DOWNLOAD_QUALITY', _audioQualities.indexOf(value));
    _downloadQuality = value;
    notifyListeners();
  }

  set skipSilence(bool value) {
    _box.put('SKIP_SILENCE', value);
    _skipSilence = value;
    notifyListeners();
  }

  set accentColor(Color? color) {
    int? c = color?.value;
    _box.put('ACCENT_COLOR', c);
    _accentColor = color;
    notifyListeners();
  }

  set amoledBlack(bool val) {
    _box.put('AMOLED_BLACK', val);
    _amoledBlack = val;
    notifyListeners();
  }

  set dynamicColors(bool isMaterial) {
    _box.put('DYNAMIC_COLORS', isMaterial);
    _dynamicColors = isMaterial;
    notifyListeners();
  }

  set equalizerEnabled(bool enabled) {
    _box.put('EQUALIZER_ENABLED', enabled);
    _equalizerEnabled = enabled;
    notifyListeners();
  }

  set equalizerBandsGain(List<double>? value) {
    if (value != null) {
      _box.put('EQUALIZER_BANDS_GAIN', value);
      _equalizerBandsGain = value;
      notifyListeners();
    }
  }

  Future<void> setEqualizerBandsGain(int index, double value) async {
    _equalizerBandsGain[index] = value;
    await _box.put('EQUALIZER_BANDS_GAIN', equalizerBandsGain);
    notifyListeners();
  }

  set loudnessEnabled(enabled) {
    _box.put('LOUDNESS_ENABLED', enabled);
    _loudnessEnabled = enabled;
    notifyListeners();
  }

  set loudnessTargetGain(double value) {
    _box.put('LOUDNESS_TARGET_GAIN', value);
    _loudnessTargetGain = value;
    notifyListeners();
  }

  Future<void> setSettings(Map value) async {
    await Future.forEach(value.entries, (entry) async {
      await _box.put(entry.key, entry.value);
    });
    notifyListeners();
    _init();
  }
}

bool getDarkness(int themeMode) {
  if (themeMode == 0) {
    return MediaQueryData.fromView(
                    WidgetsBinding.instance.platformDispatcher.views.first)
                .platformBrightness ==
            Brightness.dark
        ? true
        : false;
  } else if (themeMode == 2) {
    return true;
  }
  return false;
}

enum AudioQuality { high, low }

List<Map<String, String>> _countries = [
  {"name": "Algeria", "value": "DZ"},
  {"name": "Argentina", "value": "AR"},
  {"name": "Australia", "value": "AU"},
  {"name": "Austria", "value": "AT"},
  {"name": "Azerbaijan", "value": "AZ"},
  {"name": "Bahrain", "value": "BH"},
  {"name": "Bangladesh", "value": "BD"},
  {"name": "Belarus", "value": "BY"},
  {"name": "Belgium", "value": "BE"},
  {"name": "Bolivia", "value": "BO"},
  {"name": "Bosnia and Herzegovina", "value": "BA"},
  {"name": "Brazil", "value": "BR"},
  {"name": "Bulgaria", "value": "BG"},
  {"name": "Cambodia", "value": "KH"},
  {"name": "Canada", "value": "CA"},
  {"name": "Chile", "value": "CL"},
  {"name": "Colombia", "value": "CO"},
  {"name": "Costa Rica", "value": "CR"},
  {"name": "Croatia", "value": "HR"},
  {"name": "Cyprus", "value": "CY"},
  {"name": "Czechia", "value": "CZ"},
  {"name": "Denmark", "value": "DK"},
  {"name": "Dominican Republic", "value": "DO"},
  {"name": "Ecuador", "value": "EC"},
  {"name": "Egypt", "value": "EG"},
  {"name": "El Salvador", "value": "SV"},
  {"name": "Estonia", "value": "EE"},
  {"name": "Finland", "value": "FI"},
  {"name": "France", "value": "FR"},
  {"name": "Georgia", "value": "GE"},
  {"name": "Germany", "value": "DE"},
  {"name": "Ghana", "value": "GH"},
  {"name": "Greece", "value": "GR"},
  {"name": "Guatemala", "value": "GT"},
  {"name": "Honduras", "value": "HN"},
  {"name": "Hong Kong", "value": "HK"},
  {"name": "Hungary", "value": "HU"},
  {"name": "Iceland", "value": "IS"},
  {"name": "India", "value": "IN"},
  {"name": "Indonesia", "value": "ID"},
  {"name": "Iraq", "value": "IQ"},
  {"name": "Ireland", "value": "IE"},
  {"name": "Israel", "value": "IL"},
  {"name": "Italy", "value": "IT"},
  {"name": "Jamaica", "value": "JM"},
  {"name": "Japan", "value": "JP"},
  {"name": "Jordan", "value": "JO"},
  {"name": "Kazakhstan", "value": "KZ"},
  {"name": "Kenya", "value": "KE"},
  {"name": "Kuwait", "value": "KW"},
  {"name": "Laos", "value": "LA"},
  {"name": "Latvia", "value": "LV"},
  {"name": "Lebanon", "value": "LB"},
  {"name": "Libya", "value": "LY"},
  {"name": "Liechtenstein", "value": "LI"},
  {"name": "Lithuania", "value": "LT"},
  {"name": "Luxembourg", "value": "LU"},
  {"name": "Malaysia", "value": "MY"},
  {"name": "Malta", "value": "MT"},
  {"name": "Mexico", "value": "MX"},
  {"name": "Moldova", "value": "MD"},
  {"name": "Montenegro", "value": "ME"},
  {"name": "Morocco", "value": "MA"},
  {"name": "Nepal", "value": "NP"},
  {"name": "Netherlands", "value": "NL"},
  {"name": "New Zealand", "value": "NZ"},
  {"name": "Nicaragua", "value": "NI"},
  {"name": "Nigeria", "value": "NG"},
  {"name": "North Macedonia", "value": "MK"},
  {"name": "Norway", "value": "NO"},
  {"name": "Oman", "value": "OM"},
  {"name": "Pakistan", "value": "PK"},
  {"name": "Panama", "value": "PA"},
  {"name": "Papua New Guinea", "value": "PG"},
  {"name": "Paraguay", "value": "PY"},
  {"name": "Peru", "value": "PE"},
  {"name": "Philippines", "value": "PH"},
  {"name": "Poland", "value": "PL"},
  {"name": "Portugal", "value": "PT"},
  {"name": "Puerto Rico", "value": "PR"},
  {"name": "Qatar", "value": "QA"},
  {"name": "Romania", "value": "RO"},
  {"name": "Russia", "value": "RU"},
  {"name": "Saudi Arabia", "value": "SA"},
  {"name": "Senegal", "value": "SN"},
  {"name": "Serbia", "value": "RS"},
  {"name": "Singapore", "value": "SG"},
  {"name": "Slovakia", "value": "SK"},
  {"name": "Slovenia", "value": "SI"},
  {"name": "South Africa", "value": "ZA"},
  {"name": "South Korea", "value": "KR"},
  {"name": "Spain", "value": "ES"},
  {"name": "Sri Lanka", "value": "LK"},
  {"name": "Sweden", "value": "SE"},
  {"name": "Switzerland", "value": "CH"},
  {"name": "Taiwan", "value": "TW"},
  {"name": "Tanzania", "value": "TZ"},
  {"name": "Thailand", "value": "TH"},
  {"name": "Tunisia", "value": "TN"},
  {"name": "Turkey", "value": "TR"},
  {"name": "Uganda", "value": "UG"},
  {"name": "Ukraine", "value": "UA"},
  {"name": "United Arab Emirates", "value": "AE"},
  {"name": "United Kingdom", "value": "GB"},
  {"name": "United States", "value": "US"},
  {"name": "Uruguay", "value": "UY"},
  {"name": "Venezuela", "value": "VE"},
  {"name": "Vietnam", "value": "VN"},
  {"name": "Yemen", "value": "YE"},
  {"name": "Zimbabwe", "value": "ZW"}
];

List<Map<String, String>> _languages = [
  {"name": "Afrikaans", "value": "af"},
  {"name": "Azərbaycan", "value": "az"},
  {"name": "Bahasa Indonesia", "value": "id"},
  {"name": "Bahasa Malaysia", "value": "ms"},
  {"name": "Bosanski", "value": "bs"},
  {"name": "Català", "value": "ca"},
  {"name": "Čeština", "value": "cs"},
  {"name": "Dansk", "value": "da"},
  {"name": "Deutsch", "value": "de"},
  {"name": "Eesti", "value": "et"},
  {"name": "English (India)", "value": "en-IN"},
  {"name": "English (UK)", "value": "en-GB"},
  {"name": "English (US)", "value": "en"},
  {"name": "Español (España)", "value": "es"},
  {"name": "Español (Latinoamérica)", "value": "es-419"},
  {"name": "Español (US)", "value": "es-US"},
  {"name": "Euskara", "value": "eu"},
  {"name": "Filipino", "value": "fil"},
  {"name": "Français", "value": "fr"},
  {"name": "Français (Canada)", "value": "fr-CA"},
  {"name": "Galego", "value": "gl"},
  {"name": "Hrvatski", "value": "hr"},
  {"name": "IsiZulu", "value": "zu"},
  {"name": "Íslenska", "value": "is"},
  {"name": "Italiano", "value": "it"},
  {"name": "Kiswahili", "value": "sw"},
  {"name": "Latviešu valoda", "value": "lv"},
  {"name": "Lietuvių", "value": "lt"},
  {"name": "Magyar", "value": "hu"},
  {"name": "Nederlands", "value": "nl"},
  {"name": "Norsk", "value": "no"},
  {"name": "O‘zbek", "value": "uz"},
  {"name": "Polski", "value": "pl"},
  {"name": "Português", "value": "pt-PT"},
  {"name": "Português (Brasil)", "value": "pt"},
  {"name": "Română", "value": "ro"},
  {"name": "Shqip", "value": "sq"},
  {"name": "Slovenčina", "value": "sk"},
  {"name": "Slovenščina", "value": "sl"},
  {"name": "Srpski", "value": "sr-Latn"},
  {"name": "Suomi", "value": "fi"},
  {"name": "Svenska", "value": "sv"},
  {"name": "Tiếng Việt", "value": "vi"},
  {"name": "Türkçe", "value": "tr"},
  {"name": "Беларуская", "value": "be"},
  {"name": "Български", "value": "bg"},
  {"name": "Кыргызча", "value": "ky"},
  {"name": "Қазақ Тілі", "value": "kk"},
  {"name": "Македонски", "value": "mk"},
  {"name": "Монгол", "value": "mn"},
  {"name": "Русский", "value": "ru"},
  {"name": "Српски", "value": "sr"},
  {"name": "Українська", "value": "uk"},
  {"name": "Ελληνικά", "value": "el"},
  {"name": "Հայերեն", "value": "hy"},
  {"name": "עברית", "value": "iw"},
  {"name": "اردو", "value": "ur"},
  {"name": "العربية", "value": "ar"},
  {"name": "فارسی", "value": "fa"},
  {"name": "नेपाली", "value": "ne"},
  {"name": "मराठी", "value": "mr"},
  {"name": "हिन्दी", "value": "hi"},
  {"name": "অসমীয়া", "value": "as"},
  {"name": "বাংলা", "value": "bn"},
  {"name": "ਪੰਜਾਬੀ", "value": "pa"},
  {"name": "ગુજરાતી", "value": "gu"},
  {"name": "ଓଡ଼ିଆ", "value": "or"},
  {"name": "தமிழ்", "value": "ta"},
  {"name": "తెలుగు", "value": "te"},
  {"name": "ಕನ್ನಡ", "value": "kn"},
  {"name": "മലയാളം", "value": "ml"},
  {"name": "සිංහල", "value": "si"},
  {"name": "ภาษาไทย", "value": "th"},
  {"name": "ລາວ", "value": "lo"},
  {"name": "ဗမာ", "value": "my"},
  {"name": "ქართული", "value": "ka"},
  {"name": "አማርኛ", "value": "am"},
  {"name": "ខ្មែរ", "value": "km"},
  {"name": "中文 (简体)", "value": "zh-CN"},
  {"name": "中文 (繁體)", "value": "zh-TW"},
  {"name": "中文 (香港)", "value": "zh-HK"},
  {"name": "日本語", "value": "ja"},
  {"name": "한국어", "value": "ko"}
];
