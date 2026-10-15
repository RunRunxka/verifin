# 100% 复刻 BetterHeybox 液态玻璃底栏（原生 QWEA0 方案）

## 已核实的关键事实

1. QWEA0 折射源 = `setBackdropSource(View)` + 每帧 `View.draw()` 重录进 RenderNode（无 PixelCopy/截图）。Flutter 默认 SurfaceView 的像素不经过 View.draw → **任何 PlatformView 嵌法都采到透明，必然失败且无警告**。
2. **唯一 100% 等价路径**：Flutter 用 `FlutterTextureView`（texture 渲染模式）+ 玻璃 View 与 FlutterView **同一 ViewGroup 树** + `setBackdropSource(flutterView)` + `enableDynamicBackground(true)`。这样 Flutter 像素进入 HWUI 硬件画布，被同一个 `LENS_AGSL` RuntimeShader 链（blur → SDF 折射+色散+边缘高光）原样采样——与 BetterHeybox 在原生宿主里是**同一条渲染管线**。
3. 条目必须由原生画：QWEA0 `LiquidGlassTabBar` 自带水滴指示器与内置 tab 行（选中态、颜色由库内部 `updateTabStyles` 驱动）；Flutter 画的 tab 会在玻璃折射下变形不可读。BetterHeybox 也是隐藏宿主底栏、全部原生绘制。
4. 上次实现的 Flutter 着色器近似版**保留为降级路径**（API<33、无着色器、高对比度、原生栏初始化失败时回退），测试全部沿用。

## 架构

```
MainActivity (FlutterFragmentActivity, RenderMode.texture)
 └ FrameLayout
    ├ FlutterTextureView          ← Flutter 全部内容（tab 项不再由 Flutter 画）
    └ LiquidGlassBarOverlay(原生)  ← QWEA0 LiquidGlassTabBar（玻璃+水滴+原生 tab）
                                    backdropSource = FlutterView
```

- Flutter 侧液态玻璃样式变成「**驱动器 + 占位**」：`buildBar` 渲染几何占位（保持 occupiedHeight/避让/稳定 key 供 fallback），并通过既有 MethodChannel `verifin/app` 指挥原生栏：启用/关闭、tab 图标+标签、选中态同步。
- 原生侧点击/拖动 tab → MethodChannel 回调 Dart → Shell 切页（切页状态机仍归 Shell）；Flutter 外部切页（返回键、小组件路由）→ Dart 调 `setSelectedIndex` 同步水滴。
- 拖动切换在原生 wrapper 上按 BetterHeybox 的 nearestTabIndex 吸附实现。
- 图标/文案单一来源：Dart 把四目的地图标（选中/未选中各一）rasterize 成 PNG 经 channel 传原生，标签走 l10n 字符串。
- 明暗反色：原生 `BackdropLuminanceMeter` 用软件画布采不到 TextureView → 反色信号由 Dart 侧低频采样内容亮度（RepaintBoundary 降采样）或主题亮度驱动，经 channel 下发（实现期定，倾向主题亮度起步）。

## 实施步骤

**Phase 0 — 可行性 Spike（先证伪，风险最高处先测）**
重装工具链（上轮已按用户要求删除，自动重下：Flutter 3.47.2 → F:\flutter、Android SDK → F:\android-sdk，含 platform-36/build-tools/JDK 已在机）；起 MuMu 模拟器。做最小验证：
1. MainActivity 切 texture 渲染模式，确认 Flutter 正常渲染 + 性能可接受；
2. 引入 QWEA0 依赖（JitPack `com.github.QWEA0:liquidglass:90f4ea28e3`，MIT），裸 LiquidGlassView 覆盖在 FlutterView 上、backdrop 指向 FlutterView，验证折射真的采到 Flutter 内容。
   Spike 不过（Impeller+TextureView 不可用/性能崩坏）→ 立即汇报，停在 Phase 0，不硬上。

**Phase 1 — 原生栏骨架**
- `android/`：新建 `LiquidGlassBarController.kt`（挂载/卸载原生栏、几何按 BetterHeybox 默认值：高 60dp 自适应、距底 16dp、侧距 16dp、胶囊 cornerRadius=999、refractionHeight 60dp、bevel 16dp、dispersion 0.12、sensorHighlight）；`LiquidGlassTabBar` + 原生 tab 行。
- `settings.gradle.kts` 加 JitPack 仓库；`app/build.gradle.kts` 加依赖。
- MainActivity `createFlutterFragment()` 覆写为 texture 渲染模式；同一 channel 增加方法：`setLiquidGlassBar(enabled, tabs, selectedIndex, dark)`、`updateLiquidGlassSelection(index)`、原生→Dart `onLiquidGlassTabSelected(index)`。
- 初始化失败/SDK<33/高对比度 → 原生栏不装，Flutter fallback 生效。

**Phase 2 — 完整复刻交互**
- 图标 rasterize 通道、选中/未选中切换、水滴动画（TabBar 内置）、原生拖动吸附、明暗反色下发、键盘弹出时原生栏避让（insets 观察）、记账按钮与原生栏不重叠（Shell 既有 occupiedHeight 逻辑沿用）。
- 深浅色、快速滚动下的折射活体感（enableDynamicBackground）、进程重启后状态恢复。

**Phase 3 — 契约、文档与验收**
- 测试：既有液态玻璃 widget 测试改造为「fallback 路径」测试 + 新增驱动逻辑测试（channel 编排、几何不变）；真机验收清单（见下）。
- R8/release 构建真机验证（AGENTS.md 硬要求；必要时补 proguard keep 规则）。
- 文档：AGENTS.md 材质规范修订（液态玻璃例外区扩到原生文件清单 + TextureView 渲染模式口径）、components.md、design-system.md、ui-guidelines.md、tech-decisions.md（撤销「不引入第三方玻璃库」决策、记录 JitPack/TextureView 取舍）、known-limitations.md、CHANGELOG。

## 必须让你知道的后果（已按「不论组件如何」视为接受，仍如实列出）

1. **全 app 常驻 TextureView**：渲染模式无法按样式热切换，只要这个功能存在，所有用户（包括用默认停靠栏的）都跑 TextureView。Flutter 历史版本 TextureView 有性能回退问题，Phase 0 用真机实测把关；这影响的是整个应用，不只玻璃栏。
2. **第三方依赖与供应链**：JitPack 单点 + 上游 MIT 仓库活跃度一般；tech-decisions 里「不引入第三方玻璃库」的既有决策将被推翻（按你的明确要求）。
3. **无障碍/契约重排**：原生激活时 tab 不在 Flutter 树里，现有 `nav_item` key/Semantics 断言只覆盖 fallback；TalkBack 走原生 view。
4. 亮度自适应反色的数据源变化（原生 meter 采不到 TextureView），由 Dart 侧驱动，口径实现期定。
5. 真机验收是硬门槛：Impeller+TextureView、R8 release、性能（中端机 60fps）、深浅色、进程重启。

## 验证计划

- `dart format` / `flutter analyze` / `flutter test` 全量。
- 真机（模拟器 + 你的实体机）：折射采到 Flutter 滚动内容、水滴动画、拖动吸附、四 tab 与切页状态机、记账按钮不重叠、深浅色、键盘避让、release/R8 构建。
- Spike 结论（Phase 0 通过与否）单独汇报后再继续。