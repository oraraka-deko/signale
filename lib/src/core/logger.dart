part of signale;

String _ansiCsi = '\x1b[';
String _defaultColor = '${_ansiCsi}0m';
String _verboseSeq = '${_ansiCsi}38;5;244m';

class LogEntity {
  LogEntity(this.time, this.data, this.level);
  final DateTime time;
  final String data;
  final LogLevel level;
}

class Logger {
  Logger({this.printer = const DefaultPrinter()});
  Printable printer;
  LogLevel level = LogLevel.verbose;
  StreamController<LogEntity> _streamController = StreamController.broadcast();
  Stream<LogEntity> get stream => _streamController.stream;

  List<LogEntity> buffer = [];

  void _print(Object? object, String tag, String colorTag, LogLevel level) {
    final String data = '$object';
    data.split('\n').forEach((element) {
      final String line = '$_verboseSeq[$tag] ${_ansiCsi}1;${colorTag}m$element$_defaultColor';
      DateTime time = DateTime.now();
      buffer.add(LogEntity(time, line, level));
      printer.print(DateTime.now(), line);
      _streamController.add(LogEntity(time, line, level));
    });
  }

  /// verbose log
  void v(Object? object, {String? tag}) {
    if (level.index > LogLevel.verbose.index) {
      return;
    }
    String t = tag == null ? 'V' : '$tag';
    _print(object, t, '0', LogLevel.verbose);
  }

  /// debug log
  void d(Object? object, {String? tag}) {
    if (level.index > LogLevel.debug.index) {
      return;
    }
    String t = tag == null ? 'D' : '$tag';
    _print(object, t, '34', LogLevel.debug);
  }

  /// info log
  void i(Object? object, {String? tag}) {
    if (level.index > LogLevel.info.index) {
      return;
    }
    String t = tag == null ? 'I' : '$tag';
    _print(object, t, '32', LogLevel.info);
  }

  /// warning log
  void w(Object? object, {String? tag}) {
    if (level.index > LogLevel.warning.index) {
      return;
    }
    String t = tag == null ? 'W' : '$tag';
    _print(object, t, '33', LogLevel.warning);
  }

  /// error log
  void e(Object? object, {String? tag}) {
    if (level.index > LogLevel.error.index) {
      return;
    }
    String t = tag == null ? 'E' : '$tag';
    _print(object, t, '31', LogLevel.error);
  }

  void custom(
    Object? object, {
    int foreColor = 0,
    int? backColor,
    String? tag = 'custom',
    bool highlight = true, // 新增高亮选项
  }) {
    final String data = '$object';
    data.split('\n').forEach((element) {
      int actualBackColor = backColor ?? _calculateContrastColor(foreColor);

      // 基础样式
      String colorFmt = '\x1B[1m'; // 粗体

      // 添加高亮效果
      if (highlight && foreColor < 8) {
        // 如果是基本8色(0-7)且要求高亮，使用高亮颜色(90-97)
        colorFmt += '\x1B[${90 + foreColor}m';
      } else {
        // 否则使用256色模式
        colorFmt += '\x1B[38;5;${foreColor}m';
      }

      // 添加背景色
      colorFmt += '\x1B[48;5;${actualBackColor}m';

      String line = '$_verboseSeq[$tag] ${colorFmt}${element}\x1B[0m c:$foreColor b:$actualBackColor';

      DateTime time = DateTime.now();
      buffer.add(LogEntity(time, line, level));
      printer.print(DateTime.now(), line);
      _streamController.add(LogEntity(time, line, level));
    });
  }

  int _calculateContrastColor(int foreColor) {
    // 标准色范围 (0-15)
    if (foreColor < 16) {
      // 对于标准颜色，使用更直观的映射
      // 0-7是基本色，8-15是亮色版本
      const Map<int, int> standardColorMap = {
        0: 15, // 黑 -> 白
        1: 15, // 红 -> 白
        2: 0, // 绿 -> 黑
        3: 0, // 黄 -> 黑
        4: 15, // 蓝 -> 白
        5: 15, // 洋红 -> 白
        6: 0, // 青 -> 黑
        7: 0, // 白 -> 黑
        8: 15, // 亮黑 -> 白
        9: 0, // 亮红 -> 黑
        10: 0, // 亮绿 -> 黑
        11: 0, // 亮黄 -> 黑
        12: 15, // 亮蓝 -> 白
        13: 0, // 亮洋红 -> 黑
        14: 0, // 亮青 -> 黑
        15: 0, // 亮白 -> 黑
      };
      return standardColorMap[foreColor] ?? 0;
    }

    // 灰度范围 (232-255)
    else if (foreColor >= 232) {
      // 对灰度值进行明确的反转
      int gray = foreColor - 232; // 0-23
      int reversedGray = 23 - gray; // 23-0
      return 232 + reversedGray;
    }

    // RGB立方 (16-231)
    else {
      // 计算RGB分量
      int adjForeColor = foreColor - 16;
      int r = (adjForeColor ~/ 36) % 6;
      int g = (adjForeColor ~/ 6) % 6;
      int b = adjForeColor % 6;

      // 计算感知亮度 (使用更精确的权重)
      double luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 6;

      if (luminance > 0.5) {
        // 较亮颜色使用暗背景 (近黑色)
        return 16; // RGB(0,0,0) - 立方体起始的黑色
      } else {
        // 较暗颜色使用亮背景 (近白色)
        return 231; // RGB(5,5,5) - 立方体结束的白色
      }
    }
  }
}
