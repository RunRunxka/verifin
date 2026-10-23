import 'dart:ui' show lerpDouble;

import 'package:anchored_menu/anchored_menu.dart';
import 'package:flutter/material.dart';

import 'models.dart';

// 画布与内容基色：一律实体填色，不模拟玻璃折射或模糊。
const Color veriCanvasLight = Color(0xFFF3F5F8);
const Color veriCanvasDark = Color(0xFF101318);

/// 内容卡片（与资产封面）的深色基色。
const Color veriCardSurfaceDark = Color(0xFF1A1F27);

/// 卡片圆角半径。卡内需要自行裁圆角（例如样式预览这类整宽内容）时用它。
const double veriCardRadius = 16;

/// 内容卡片与资产封面共用的实体基色。
Color veriContentSurfaceColor(Brightness brightness) =>
    brightness == Brightness.dark ? veriCardSurfaceDark : veriSurfaceLight;

/// 浮动元件（底部导航、快捷按钮、锚点菜单）的实体基色。
///
/// 比画布和内容卡片更亮一档，靠表面色差 + 描边 + 阴影表达层级，
/// 不需要模糊或渐变。
Color veriElevatedSurfaceColor(Brightness brightness) =>
    brightness == Brightness.dark ? veriSurfaceRaisedDark : veriSurfaceLight;

/// 深色下高于卡片的浮动表面色。
const Color veriSurfaceRaisedDark = Color(0xFF232A35);

const Color veriMint = Color(0xFF34DBCB);
const Color veriCyan = Color(0xFF34C2DB);
const Color veriBlue = Color(0xFF3498DB);
const Color veriRoyal = Color(0xFF346EDB);
const Color veriNavigationUnselected = Color(0xFFADADAD);
const Color veriIndigo = Color(0xFF3445DB);
const Color veriInk = Color(0xFF151922);
const Color veriLine = Color(0xFFE1E8F1);
const Color veriExpense = Color(0xFFE84D6A);
const Color veriIncome = Color(0xFF12B8A6);
const Color veriWarning = Color(0xFFFFB33E);
// 浅色底语义色变体。上面的亮色在白底上对比度不足（veriIncome 2.49:1、veriWarning 1.78:1、
// veriBlue 3.15:1、veriExpense 3.68:1，均低于正文级 AA 要求的 4.5:1）。以下变体保持原色相、
// 只压暗明度，在 #FFFFFF 与 #F3F5F8 上均 ≥ 4.5:1。深色主题继续用亮色。
const Color veriExpenseOnLight = Color(0xFFC2334F);
const Color veriIncomeOnLight = Color(0xFF0B7A6C);
const Color veriBlueOnLight = Color(0xFF1F6FC4);
const Color veriWarningOnLight = Color(0xFF8A5A00);

// Miuix（HyperOS）主题令牌。浅色语义色按与 Veri 相同的规则压暗，保证在
// #FFFFFF 卡片与 #F7F7F7 画布上达到正文级 AA（4.5:1）。
const Color veriMiuixCanvasLight = Color(0xFFF7F7F7);
const Color veriMiuixCanvasDark = Color(0xFF242424);
const Color veriMiuixCardLight = Color(0xFFFFFFFF);
const Color veriMiuixCardDark = Color(0xFF2E2E2E);
const Color veriMiuixElevatedLight = Color(0xFFFFFFFF);
const Color veriMiuixElevatedDark = Color(0xFF333333);
const Color veriMiuixAltLight = Color(0xFFF0F0F0);
const Color veriMiuixAltDark = Color(0xFF434343);
const Color veriMiuixLineLight = Color(0xFFE0E0E0);
const Color veriMiuixLineDark = Color(0xFF393939);
const Color veriMiuixOutlineLight = Color(0xFFD9D9D9);
const Color veriMiuixOutlineDark = Color(0xFF404040);
const Color veriMiuixPrimaryLight = Color(0xFF3482FF);
const Color veriMiuixPrimaryDark = Color(0xFF277AF7);
const Color veriMiuixExpenseLight = Color(0xFFC33A2B);
const Color veriMiuixExpenseDark = Color(0xFFFF7A6E);
const Color veriMiuixIncomeLight = Color(0xFF0B7F43);
const Color veriMiuixIncomeDark = Color(0xFF3DDC84);
const Color veriMiuixWarningLight = Color(0xFFA05A00);
const Color veriMiuixWarningDark = Color(0xFFFFB84D);
const Color veriMiuixBlueLight = Color(0xFF1A67D6);
const Color veriMiuixBlueDark = Color(0xFF5AA0FF);
const double veriMiuixCardRadius = 20;
const double veriMiuixPanelRadius = 28;
const double veriMiuixSheetRadius = 28;
const double veriMiuixControlRadius = 16;
const double veriMiuixChipRadius = 10;
const String veriMiuixFontFamily = 'MiSans';

const Color veriSurfaceLight = Color(0xFFFFFFFF);
const Color veriSurfaceDark = Color(0xFF0E1117);
const Color veriSurfaceAltLight = Color(0xFFF5F8FC);
const Color veriSurfaceAltDark = Color(0xFF151A22);
const double veriRadiusSm = 6;
const double veriRadiusMd = 12;
const double veriRadiusLg = 16;
const double veriRadiusXl = 24;
const double veriHeaderHeight = 56;
const double veriPageMaxWidth = 440;

/// 当前主题风格解析后的颜色与几何令牌。
///
/// 页面与组件一律经 [of] 取当前风格；纯取色函数没有 `BuildContext` 时用
/// [veriSemanticFor] 的可选风格参数。`Veri` 令牌保持原有取值，`Miuix` 使用
/// HyperOS 的中性表面、固定蓝色与语义色。
@immutable
class VeriThemeTokens extends ThemeExtension<VeriThemeTokens> {
  const VeriThemeTokens({
    required this.style,
    required this.canvas,
    required this.contentSurface,
    required this.elevatedSurface,
    required this.altSurface,
    required this.subtleSurface,
    required this.line,
    required this.outline,
    required this.expense,
    required this.income,
    required this.blue,
    required this.warning,
    required this.cardRadius,
    required this.panelRadius,
    required this.sheetRadius,
    required this.controlRadius,
    required this.fontFamily,
  });

  factory VeriThemeTokens.forStyle(
    ThemeStylePreference style,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    if (style == ThemeStylePreference.miuix) {
      return VeriThemeTokens(
        style: style,
        canvas: isDark ? veriMiuixCanvasDark : veriMiuixCanvasLight,
        contentSurface: isDark ? veriMiuixCardDark : veriMiuixCardLight,
        elevatedSurface: isDark
            ? veriMiuixElevatedDark
            : veriMiuixElevatedLight,
        altSurface: isDark ? veriMiuixAltDark : veriMiuixAltLight,
        subtleSurface: isDark ? veriMiuixAltDark : veriMiuixAltLight,
        line: isDark ? veriMiuixLineDark : veriMiuixLineLight,
        outline: isDark ? veriMiuixOutlineDark : veriMiuixOutlineLight,
        expense: isDark ? veriMiuixExpenseDark : veriMiuixExpenseLight,
        income: isDark ? veriMiuixIncomeDark : veriMiuixIncomeLight,
        blue: isDark ? veriMiuixBlueDark : veriMiuixBlueLight,
        warning: isDark ? veriMiuixWarningDark : veriMiuixWarningLight,
        cardRadius: veriMiuixCardRadius,
        panelRadius: veriMiuixPanelRadius,
        sheetRadius: veriMiuixSheetRadius,
        controlRadius: veriMiuixControlRadius,
        fontFamily: veriMiuixFontFamily,
      );
    }
    return VeriThemeTokens(
      style: style,
      canvas: isDark ? veriCanvasDark : veriCanvasLight,
      contentSurface: isDark ? veriCardSurfaceDark : veriSurfaceLight,
      elevatedSurface: isDark ? veriSurfaceRaisedDark : veriSurfaceLight,
      altSurface: isDark ? veriSurfaceAltDark : veriSurfaceLight,
      subtleSurface: isDark ? veriSurfaceAltDark : veriSurfaceAltLight,
      line: isDark ? Colors.white10 : veriLine,
      outline: (isDark ? Colors.white : veriInk).withValues(alpha: 0.045),
      expense: isDark ? veriExpense : veriExpenseOnLight,
      income: isDark ? veriIncome : veriIncomeOnLight,
      blue: isDark ? veriBlue : veriBlueOnLight,
      warning: isDark ? veriWarning : veriWarningOnLight,
      cardRadius: veriCardRadius,
      panelRadius: veriRadiusXl,
      sheetRadius: veriRadiusXl,
      controlRadius: veriRadiusMd,
      fontFamily: 'Roboto',
    );
  }

  final ThemeStylePreference style;
  final Color canvas;
  final Color contentSurface;
  final Color elevatedSurface;

  /// 胶囊、分段控件轨道、反馈卡片等「中性浅底」。
  final Color altSurface;

  /// 比 [altSurface] 更接近画布的分区底色（月份切换、AI 面板等）。
  final Color subtleSurface;

  final Color line;
  final Color outline;
  final Color expense;
  final Color income;
  final Color blue;
  final Color warning;
  final double cardRadius;
  final double panelRadius;
  final double sheetRadius;
  final double controlRadius;
  final String fontFamily;

  static VeriThemeTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<VeriThemeTokens>() ??
        VeriThemeTokens.forStyle(ThemeStylePreference.veri, theme.brightness);
  }

  @override
  VeriThemeTokens copyWith({
    ThemeStylePreference? style,
    Color? canvas,
    Color? contentSurface,
    Color? elevatedSurface,
    Color? altSurface,
    Color? subtleSurface,
    Color? line,
    Color? outline,
    Color? expense,
    Color? income,
    Color? blue,
    Color? warning,
    double? cardRadius,
    double? panelRadius,
    double? sheetRadius,
    double? controlRadius,
    String? fontFamily,
  }) => VeriThemeTokens(
    style: style ?? this.style,
    canvas: canvas ?? this.canvas,
    contentSurface: contentSurface ?? this.contentSurface,
    elevatedSurface: elevatedSurface ?? this.elevatedSurface,
    altSurface: altSurface ?? this.altSurface,
    subtleSurface: subtleSurface ?? this.subtleSurface,
    line: line ?? this.line,
    outline: outline ?? this.outline,
    expense: expense ?? this.expense,
    income: income ?? this.income,
    blue: blue ?? this.blue,
    warning: warning ?? this.warning,
    cardRadius: cardRadius ?? this.cardRadius,
    panelRadius: panelRadius ?? this.panelRadius,
    sheetRadius: sheetRadius ?? this.sheetRadius,
    controlRadius: controlRadius ?? this.controlRadius,
    fontFamily: fontFamily ?? this.fontFamily,
  );

  @override
  VeriThemeTokens lerp(ThemeExtension<VeriThemeTokens>? other, double t) {
    if (other is! VeriThemeTokens) return this;
    return VeriThemeTokens(
      style: t < 0.5 ? style : other.style,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      contentSurface: Color.lerp(contentSurface, other.contentSurface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      altSurface: Color.lerp(altSurface, other.altSurface, t)!,
      subtleSurface: Color.lerp(subtleSurface, other.subtleSurface, t)!,
      line: Color.lerp(line, other.line, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      income: Color.lerp(income, other.income, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      panelRadius: lerpDouble(panelRadius, other.panelRadius, t)!,
      sheetRadius: lerpDouble(sheetRadius, other.sheetRadius, t)!,
      controlRadius: lerpDouble(controlRadius, other.controlRadius, t)!,
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
    );
  }
}

/// 当前主题风格。
ThemeStylePreference veriThemeStyleOf(BuildContext context) =>
    VeriThemeTokens.of(context).style;

/// 指定风格与明暗下的画布色；没有 `BuildContext` 的纯计算用它。
Color veriCanvasForStyle(ThemeStylePreference style, Brightness brightness) {
  if (style == ThemeStylePreference.miuix) {
    return brightness == Brightness.dark
        ? veriMiuixCanvasDark
        : veriMiuixCanvasLight;
  }
  return brightness == Brightness.dark ? veriCanvasDark : veriCanvasLight;
}

/// 指定风格与明暗下的分割线色；纯计算（金额环轨底等）用它。
///
/// Veri 保持预算环轨底既有的固定 [veriLine]，不随明暗切换，避免改变现有观感。
Color veriLineForStyle(ThemeStylePreference style, Brightness brightness) {
  if (style == ThemeStylePreference.miuix) {
    return brightness == Brightness.dark
        ? veriMiuixLineDark
        : veriMiuixLineLight;
  }
  return veriLine;
}

/// 内容卡片表面色（按当前风格）。
Color veriContentSurface(BuildContext context) =>
    VeriThemeTokens.of(context).contentSurface;

/// 浮动元件表面色（按当前风格）。
Color veriElevatedSurface(BuildContext context) =>
    VeriThemeTokens.of(context).elevatedSurface;

/// 中性浅底（胶囊、分段轨道、反馈卡片）。
Color veriAltSurface(BuildContext context) =>
    VeriThemeTokens.of(context).altSurface;

/// 接近画布的分区底色（月份切换、AI 面板）。
Color veriSubtleSurface(BuildContext context) =>
    VeriThemeTokens.of(context).subtleSurface;

/// 卡片外形：Miuix 使用连续曲率（squircle 近似），Veri 保持普通圆角。
OutlinedBorder veriCardShape(BuildContext context) {
  final tokens = VeriThemeTokens.of(context);
  final borderRadius = BorderRadius.circular(tokens.cardRadius);
  if (tokens.style == ThemeStylePreference.miuix) {
    return ContinuousRectangleBorder(borderRadius: borderRadius);
  }
  return RoundedRectangleBorder(borderRadius: borderRadius);
}

/// 底部弹层外形。Miuix 统一使用 [VeriThemeTokens.sheetRadius]，Veri 沿用调用方
/// 传入的圆角（既有的 16/24 两档不能合并）。
OutlinedBorder veriSheetShape(
  BuildContext context, {
  double veriRadius = veriRadiusXl,
}) {
  final tokens = VeriThemeTokens.of(context);
  final isMiuix = tokens.style == ThemeStylePreference.miuix;
  final radius = isMiuix ? tokens.sheetRadius : veriRadius;
  final borderRadius = BorderRadius.vertical(top: Radius.circular(radius));
  if (isMiuix) {
    return ContinuousRectangleBorder(borderRadius: borderRadius);
  }
  return RoundedRectangleBorder(borderRadius: borderRadius);
}

/// 语义色在当前明暗下的实际取值：深色底用原亮色，浅色底用加深变体。
/// 只对四个语义色生效，其它颜色原样返回。
Color veriSemantic(BuildContext context, Color semanticColor) {
  final tokens = Theme.of(context).extension<VeriThemeTokens>();
  if (tokens == null) {
    return veriSemanticFor(Theme.of(context).brightness, semanticColor);
  }
  return switch (semanticColor) {
    veriExpense => tokens.expense,
    veriIncome => tokens.income,
    veriBlue => tokens.blue,
    veriWarning => tokens.warning,
    _ => semanticColor,
  };
}

/// [veriSemantic] 的无 `BuildContext` 版本，供纯取色函数使用。
///
/// [style] 默认 Veri；Miuix 风格下换成 HyperOS 语义色（浅色同样压暗到 AA）。
Color veriSemanticFor(
  Brightness brightness,
  Color semanticColor, [
  ThemeStylePreference style = ThemeStylePreference.veri,
]) {
  if (style == ThemeStylePreference.miuix) {
    final isDark = brightness == Brightness.dark;
    return switch (semanticColor) {
      veriExpense => isDark ? veriMiuixExpenseDark : veriMiuixExpenseLight,
      veriIncome => isDark ? veriMiuixIncomeDark : veriMiuixIncomeLight,
      veriBlue => isDark ? veriMiuixBlueDark : veriMiuixBlueLight,
      veriWarning => isDark ? veriMiuixWarningDark : veriMiuixWarningLight,
      _ => semanticColor,
    };
  }
  if (brightness == Brightness.dark) {
    return semanticColor;
  }
  return switch (semanticColor) {
    veriExpense => veriExpenseOnLight,
    veriIncome => veriIncomeOnLight,
    veriBlue => veriBlueOnLight,
    veriWarning => veriWarningOnLight,
    _ => semanticColor,
  };
}

Color _onCustomPrimary(Color color) =>
    ThemeData.estimateBrightnessForColor(color) == Brightness.light
    ? Colors.black
    : Colors.white;

ThemeData buildVeriFinTheme(
  Brightness brightness, {
  ThemeColorPreference colorPreference = ThemeColorPreference.defaultValue,
  ThemeStylePreference style = ThemeStylePreference.veri,
}) {
  final isDark = brightness == Brightness.dark;
  final tokens = VeriThemeTokens.forStyle(style, brightness);
  final isMiuix = style == ThemeStylePreference.miuix;
  // Miuix 固定使用 HyperOS 蓝，不读取主题色，也不跟随系统动态色。
  final useSystemColors =
      !isMiuix && colorPreference.mode == ThemeColorMode.system;
  final useExactPrimary = isMiuix || !useSystemColors;
  final seedColor = isMiuix
      ? (isDark ? veriMiuixPrimaryDark : veriMiuixPrimaryLight)
      : colorPreference.mode == ThemeColorMode.custom
      ? Color(colorPreference.customColorValue)
      : veriRoyal;
  final seedScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
    // Default and custom modes keep the chosen primary exact. Material still
    // generates supporting container/secondary roles from the same hue, while
    // onPrimary is chosen for readable foreground text.
    primary: useExactPrimary ? seedColor : null,
    onPrimary: useExactPrimary
        ? (isMiuix ? Colors.white : _onCustomPrimary(seedColor))
        : null,
  );
  final canvas = tokens.canvas;
  final colorScheme = seedScheme.copyWith(
    // Miuix 的弹层/对话框使用比画布更亮一档的表面；Veri 保持 surface == 画布。
    surface: isMiuix ? tokens.elevatedSurface : canvas,
    surfaceContainerHighest: seedScheme.surfaceContainerHighest,
    onSurface: isDark
        ? (isMiuix ? const Color(0xFFF2F2F2) : const Color(0xFFF0F3F8))
        : (isMiuix ? Colors.black : veriInk),
    onSurfaceVariant: isMiuix
        ? (isDark
              ? Colors.white.withValues(alpha: 0.60)
              : Colors.black.withValues(alpha: 0.60))
        : seedScheme.onSurfaceVariant,
    outline: isMiuix ? tokens.outline : seedScheme.outline,
    outlineVariant: isMiuix ? tokens.line : seedScheme.outlineVariant,
  );

  final baseTheme = ThemeData(
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(),
    brightness: brightness,
    colorScheme: colorScheme,
    useSystemColors: useSystemColors,
    scaffoldBackgroundColor: canvas,
    fontFamily: tokens.fontFamily,
    visualDensity: VisualDensity.compact,
    dividerTheme: DividerThemeData(
      color: isMiuix ? tokens.line : (isDark ? Colors.white10 : veriLine),
      thickness: 0.8,
      space: 1,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: seedScheme.primary,
        foregroundColor: seedScheme.onPrimary,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.controlRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        // 对话框的「取消 / 不保存 / 删除」都走这个主题：必须保留至少 48×44 的
        // 可点区域，否则单手操作容易误触。
        minimumSize: const Size(48, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: seedScheme.primary,
      foregroundColor: seedScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(isMiuix ? tokens.cardRadius : veriRadiusLg),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isMiuix
          ? tokens.altSurface
          : (isDark ? veriSurfaceAltDark : veriSurfaceLight),
      selectedColor: seedScheme.primary.withValues(alpha: 0.14),
      secondarySelectedColor: seedScheme.primary.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        color: isDark ? Colors.white.withValues(alpha: 0.86) : veriInk,
        fontSize: 12,
      ),
      secondaryLabelStyle: TextStyle(
        color: isDark ? Colors.white.withValues(alpha: 0.88) : veriInk,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isMiuix ? tokens.line : (isDark ? Colors.white10 : veriLine),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          isMiuix ? veriMiuixChipRadius : veriRadiusSm,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isMiuix
          ? tokens.altSurface
          : (isDark ? veriCardSurfaceDark : veriSurfaceLight),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        borderSide: BorderSide(color: seedScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        borderSide: BorderSide(color: tokens.expense),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        borderSide: BorderSide(color: tokens.expense, width: 1.4),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        borderSide: BorderSide.none,
      ),
    ),
  );

  return baseTheme.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      tokens,
      AnchoredMenuThemeData(
        surfaceColor: tokens.elevatedSurface,
        borderColor: isMiuix
            ? tokens.line
            : (isDark ? Colors.white.withValues(alpha: 0.12) : veriLine),
        foregroundColor: colorScheme.onSurface,
        selectedColor: colorScheme.primary,
        panelBorderRadius: BorderRadius.circular(tokens.panelRadius),
        itemBorderRadius: BorderRadius.circular(
          isMiuix ? veriMiuixCardRadius : veriRadiusLg,
        ),
        minWidth: 168,
      ),
    ],
    textTheme: baseTheme.textTheme.copyWith(
      displayLarge: baseTheme.textTheme.displayLarge?.copyWith(
        fontSize: 38,
        height: 1.05,
        letterSpacing: 0,
      ),
      displayMedium: baseTheme.textTheme.displayMedium?.copyWith(
        fontSize: 32,
        height: 1.08,
        letterSpacing: 0,
      ),
      displaySmall: baseTheme.textTheme.displaySmall?.copyWith(
        fontSize: 26,
        height: 1.12,
        letterSpacing: 0,
      ),
      headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
        fontSize: 21,
        height: 1.18,
        letterSpacing: 0,
      ),
      headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
        fontSize: 19,
        height: 1.2,
        letterSpacing: 0,
      ),
      titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
        fontSize: 17,
        height: 1.25,
        letterSpacing: 0,
      ),
      titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
        fontSize: 14,
        height: 1.25,
        letterSpacing: 0,
      ),
      titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
        fontSize: 13,
        height: 1.25,
        letterSpacing: 0,
      ),
      bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
        fontSize: 14,
        height: 1.35,
        letterSpacing: 0,
      ),
      bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.35,
        letterSpacing: 0,
      ),
      bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.35,
        letterSpacing: 0,
      ),
      labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
        fontSize: 12,
        height: 1.25,
        letterSpacing: 0,
      ),
      labelMedium: baseTheme.textTheme.labelMedium?.copyWith(
        fontSize: 11,
        height: 1.25,
        letterSpacing: 0,
      ),
      labelSmall: baseTheme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        height: 1.2,
        letterSpacing: 0,
      ),
    ),
  );
}
