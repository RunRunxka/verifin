import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/app_theme.dart';
import 'package:verifin/app/common_widgets.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/local_storage/local_storage.dart';

import 'support/test_harness.dart';

double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  useTestDatabases();

  test('主题风格标识可往返，未知值回退 Veri', () {
    expect(
      ThemeStylePreference.fromStorage(ThemeStylePreference.miuix.name),
      ThemeStylePreference.miuix,
    );
    expect(
      ThemeStylePreference.fromStorage(ThemeStylePreference.veri.name),
      ThemeStylePreference.veri,
    );
    expect(ThemeStylePreference.fromStorage(null), ThemeStylePreference.veri);
    expect(
      ThemeStylePreference.fromStorage('hyperos'),
      ThemeStylePreference.veri,
    );
  });

  test('Veri 默认取值保持不变', () {
    final theme = buildVeriFinTheme(Brightness.light);
    final tokens = theme.extension<VeriThemeTokens>()!;

    expect(theme.scaffoldBackgroundColor, veriCanvasLight);
    expect(theme.colorScheme.primary, veriRoyal);
    expect(theme.colorScheme.surface, veriCanvasLight);
    expect(tokens.contentSurface, veriSurfaceLight);
    expect(tokens.cardRadius, veriCardRadius);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Roboto');
  });

  test('Miuix 使用 HyperOS 表面、固定蓝、MiSans 与更大圆角', () {
    final light = buildVeriFinTheme(
      Brightness.light,
      style: ThemeStylePreference.miuix,
      colorPreference: const ThemeColorPreference(
        mode: ThemeColorMode.custom,
        customColorValue: 0xFFB3261E,
      ),
    );
    final lightTokens = light.extension<VeriThemeTokens>()!;

    expect(light.scaffoldBackgroundColor, veriMiuixCanvasLight);
    expect(light.colorScheme.surface, veriMiuixElevatedLight);
    expect(light.colorScheme.primary, veriMiuixPrimaryLight);
    expect(light.colorScheme.onPrimary, Colors.white);
    expect(lightTokens.contentSurface, veriMiuixCardLight);
    expect(lightTokens.altSurface, veriMiuixAltLight);
    expect(lightTokens.cardRadius, veriMiuixCardRadius);
    expect(lightTokens.panelRadius, veriMiuixPanelRadius);
    expect(lightTokens.controlRadius, veriMiuixControlRadius);
    expect(light.textTheme.bodyMedium?.fontFamily, veriMiuixFontFamily);

    final dark = buildVeriFinTheme(
      Brightness.dark,
      style: ThemeStylePreference.miuix,
    );
    expect(dark.scaffoldBackgroundColor, veriMiuixCanvasDark);
    expect(dark.colorScheme.primary, veriMiuixPrimaryDark);
    expect(
      dark.extension<VeriThemeTokens>()!.contentSurface,
      veriMiuixCardDark,
    );
  });

  test('Miuix 语义色在画布与卡片上达到正文级 AA', () {
    const lightSurfaces = <Color>[veriMiuixCardLight, veriMiuixCanvasLight];
    const lightSemantics = <Color>[
      veriMiuixExpenseLight,
      veriMiuixIncomeLight,
      veriMiuixWarningLight,
      veriMiuixBlueLight,
    ];
    for (final color in lightSemantics) {
      for (final surface in lightSurfaces) {
        expect(
          _contrast(color, surface),
          greaterThanOrEqualTo(4.5),
          reason:
              '#${color.toARGB32().toRadixString(16)} 在 '
              '#${surface.toARGB32().toRadixString(16)} 上对比度不足',
        );
      }
    }

    const darkSurfaces = <Color>[veriMiuixCardDark, veriMiuixCanvasDark];
    const darkSemantics = <Color>[
      veriMiuixExpenseDark,
      veriMiuixIncomeDark,
      veriMiuixWarningDark,
      veriMiuixBlueDark,
    ];
    for (final color in darkSemantics) {
      for (final surface in darkSurfaces) {
        expect(
          _contrast(color, surface),
          greaterThanOrEqualTo(4.5),
          reason:
              '#${color.toARGB32().toRadixString(16)} 在 '
              '#${surface.toARGB32().toRadixString(16)} 上对比度不足',
        );
      }
    }
  });

  test('veriSemanticFor 按风格切换语义色', () {
    expect(veriSemanticFor(Brightness.light, veriExpense), veriExpenseOnLight);
    expect(
      veriSemanticFor(
        Brightness.light,
        veriExpense,
        ThemeStylePreference.miuix,
      ),
      veriMiuixExpenseLight,
    );
    expect(
      veriSemanticFor(Brightness.dark, veriIncome, ThemeStylePreference.miuix),
      veriMiuixIncomeDark,
    );
    // 非语义色不参与映射。
    expect(
      veriSemanticFor(Brightness.light, veriRoyal, ThemeStylePreference.miuix),
      veriRoyal,
    );
  });

  testWidgets('Miuix 卡片使用连续曲率与深色卡片表面', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVeriFinTheme(
          Brightness.dark,
          style: ThemeStylePreference.miuix,
        ),
        home: const Scaffold(body: VeriCard(child: Text('content'))),
      ),
    );
    expect(tester.takeException(), isNull);
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(VeriCard),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as ShapeDecoration;
    expect(decoration.color, veriMiuixCardDark);
    expect(
      (decoration.shape as ContinuousRectangleBorder).borderRadius,
      BorderRadius.circular(veriMiuixCardRadius),
    );
  });

  test('MiSans 字体资源随包发布', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final regular = await rootBundle.load('assets/fonts/MiSans-Regular.ttf');
    final demibold = await rootBundle.load('assets/fonts/MiSans-Demibold.ttf');
    expect(regular.lengthInBytes, greaterThan(1000000));
    expect(demibold.lengthInBytes, greaterThan(1000000));
  });

  testWidgets('设置页切换 Miuix 后隐藏主题色并持久化', (tester) async {
    final store = LocalKeyValueStore();
    final controller = await pumpApp(tester, store);

    await tapBottomTab(tester, 3);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('主题风格'));
    await tester.tap(find.text('主题风格'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Miuix'));
    await tester.pumpAndSettle();

    // Miuix 固定 HyperOS 蓝，主题色设置不再出现；保存前不落盘。
    expect(find.text('主题色'), findsNothing);
    expect(controller.themeStylePreference, ThemeStylePreference.veri);

    await tester.fling(firstVerticalScrollable(), const Offset(0, 1200), 1000);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();
    expect(controller.themeStylePreference, ThemeStylePreference.miuix);

    // 主题子树已按 Miuix 重建：画布与字体都换成新令牌。
    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(theme.scaffoldBackgroundColor, veriMiuixCanvasLight);
    expect(theme.textTheme.bodyMedium?.fontFamily, veriMiuixFontFamily);

    await tester.pumpWidget(const SizedBox.shrink());
    final restarted = await pumpApp(tester, store);
    expect(restarted.themeStylePreference, ThemeStylePreference.miuix);
  });
}
