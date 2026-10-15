package top.talyra42.verifin

import android.app.Activity
import android.content.res.ColorStateList
import android.graphics.BitmapFactory
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import android.util.TypedValue
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import com.example.liquidglass.GlassMaterial
import com.example.liquidglass.LiquidGlassTabBar

/**
 * 液态玻璃底栏：100% 复刻 BetterHeybox 的原生实现。
 *
 * QWEA0 LiquidGlassTabBar（AGSL 折射 + 水滴指示器）直接挂在 FlutterView 之上、
 * 同一 ViewGroup 内；backdrop 指向 FlutterView（必须为 texture 渲染模式），
 * 玻璃的 RenderNode 每帧重录 Flutter 内容，折射与原生宿主同一条渲染管线。
 *
 * 配色：玻璃与水滴保持库的外观；选中项图标/文字用主题主色（Dart 下发两档变体），
 * 未选中项用中性墨色。两档按库的背景亮度采样（BackdropLuminanceMeter，与
 * BetterHeybox 相同）在浅底/深底之间切换。
 *
 * 初始化失败 / SDK<33 时静默不装，Flutter 侧 fallback 样式生效。
 */
class LiquidGlassBarController(private val activity: Activity) {

    /** 一个 tab：标签 + 白色剪影图标（null = 纯文字）。 */
    data class Tab(val label: String, val iconBytes: ByteArray?)

    var onTabSelected: ((Int) -> Unit)? = null

    private var tabBar: LiquidGlassTabBar? = null
    private var host: FrameLayout? = null
    private var installed = false
    private var flutterView: View? = null
    private var tabs: List<Tab> = emptyList()
    private var selectedIndex = 0
    private var bottomInsetPx = 0
    private var dark = false

    /** 主题主色的两档变体（ARGB）：浅底用 [accentOverLight]，深底用 [accentOverDark]。 */
    private var accentOverLight: Int? = null
    private var accentOverDark: Int? = null

    /** 背景采样结果：true = 底下是浅色内容。首次采样前按主题亮度估计。 */
    private var backdropOverLight = true

    private var backdropMeter: LiquidGlassBackdropSampler? = null

    /// Dart → 原生同步选中的期望值：原生回调等于该值时视为「同步引发的自反
    /// 回调」吞掉。不能用一次性布尔标记——库对「设成相同值」不触发回调，标记
    /// 会滞留并吞掉下一次真实点击（切页概率失效的根因）。
    @Volatile private var expectedInboundIndex: Int? = null

    val isActive: Boolean
        get() = installed && tabBar != null && Build.VERSION.SDK_INT >= 33

    private fun dp(v: Float): Float =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, v, activity.resources.displayMetrics)

    /** 安装玻璃底栏（重复调用 = 重装，用于几何/主题变化）。 */
    fun install(
        flutterView: View,
        tabs: List<Tab>,
        selectedIndex: Int,
        dark: Boolean,
        bottomInsetPx: Int,
        accentOverLight: Int?,
        accentOverDark: Int?,
    ) {
        if (Build.VERSION.SDK_INT < 33) return
        this.flutterView = flutterView
        this.tabs = tabs
        this.selectedIndex = selectedIndex
        this.bottomInsetPx = bottomInsetPx
        this.dark = dark
        this.accentOverLight = accentOverLight
        this.accentOverDark = accentOverDark
        try {
            uninstall()
            val content = flutterView.parent as? ViewGroup ?: return
            val frame = FrameLayout(activity)
            frame.layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT)
            val bar = LiquidGlassTabBar(activity).apply {
                layoutParams = FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    dp(BAR_HEIGHT_DP).toInt(),
                    android.view.Gravity.BOTTOM)
                cornerRadius = 999f
                material = GlassMaterial.REGULAR
                refractionHeight = dp(REFRACTION_HEIGHT_DP)
                bevelWidth = dp(BEVEL_WIDTH_DP)
                dispersionStrength = DISPERSION
                enableSensorHighlight = true
                backdropSource = flutterView
                // Flutter 内容滚动不产生 Android 滚动事件，必须常驻重录 backdrop。
                enableDynamicBackground = true
                // 玻璃与水滴的亮度基准；选中/未选中文字由 repaintTabs 按采样结果上色。
                overLight = dark
            }
            // BetterHeybox 几何默认值：高 60dp、距底 16dp、左右 16dp（胶囊悬浮）。
            (bar.layoutParams as FrameLayout.LayoutParams).apply {
                leftMargin = dp(SIDE_MARGIN_DP).toInt()
                rightMargin = dp(SIDE_MARGIN_DP).toInt()
                bottomMargin = dp(BOTTOM_OFFSET_DP).toInt() + bottomInsetPx
                width = ViewGroup.LayoutParams.MATCH_PARENT
            }
            applyTabs(bar, tabs)
            bar.selectedIndex = selectedIndex
            // 原生 tab 点击/拖动 → Dart 侧切页（Shell 状态机不变）；与 Dart
            // 同步引发的期望值相同的回调吞掉，防回环且不滞留。
            bar.onTabSelected = { index ->
                // 库在点击后已切换选中项，这里补一次墨色刷新。
                scheduleRepaint(bar)
                if (index == expectedInboundIndex) {
                    expectedInboundIndex = null
                } else {
                    onTabSelected?.invoke(index)
                }
            }
            frame.addView(bar)
            content.addView(frame)
            host = frame
            tabBar = bar
            installed = true
            backdropOverLight = !dark
            startBackdropMeter(bar)
            scheduleRepaint(bar)
        } catch (t: Throwable) {
            installed = false
            host = null
            tabBar = null
            // 静默：Flutter fallback 样式接管。
            android.util.Log.w(TAG, "install failed: $t")
        }
    }

    /** 底部 inset 变化时重装（键盘避让；几何随 Flutter 侧走）。 */
    fun updateGeometry(dark: Boolean, bottomInsetPx: Int) {
        val view = flutterView ?: return
        val themeChanged = dark != this.dark
        if (!installed || (bottomInsetPx == this.bottomInsetPx && !themeChanged)) {
            this.dark = dark
            this.bottomInsetPx = bottomInsetPx
            return
        }
        install(
            view, tabs, selectedIndex, dark, bottomInsetPx,
            accentOverLight, accentOverDark)
    }

    /// 切主题或换主题色时同步配色：更新两档主色变体并刷新选中项与未选中项的颜色。
    fun updateAppearance(dark: Boolean, accentOverLight: Int?, accentOverDark: Int?) {
        try {
            this.dark = dark
            this.accentOverLight = accentOverLight
            this.accentOverDark = accentOverDark
            tabBar?.let {
                // 玻璃与水滴的亮度基准随主题切换（不改动文字，文字由 repaintTabs 决定）。
                it.overLight = dark
                scheduleRepaint(it)
            }
        } catch (t: Throwable) {
            android.util.Log.w(TAG, "updateAppearance failed: $t")
        }
    }

    /// 有 route 盖在根页面上时隐藏原生栏（不卸载，保持折射状态），恢复时显示。
    fun setHidden(hidden: Boolean) {
        try {
            host?.visibility = if (hidden) View.GONE else View.VISIBLE
        } catch (t: Throwable) {
            android.util.Log.w(TAG, "setHidden failed: $t")
        }
    }

    private fun applyTabs(bar: LiquidGlassTabBar, tabs: List<Tab>) {
        val items = tabs.map { tab ->
            val drawable = tab.iconBytes?.let { bytes ->
                try {
                    BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                        ?.let { BitmapDrawable(activity.resources, it) }
                } catch (t: Throwable) {
                    null
                }
            }
            LiquidGlassTabBar.TabItem(tab.label, drawable)
        }
        bar.setTabs(items)
    }

    fun updateSelection(index: Int) {
        try {
            if (!installed) return
            // 库对「设成相同值」不触发回调；此时不设期望值，避免它滞留并在
            // 下次真实点击同一 index 时被误吞。
            if (index == selectedIndex) {
                expectedInboundIndex = null
                return
            }
            selectedIndex = index
            expectedInboundIndex = index
            tabBar?.let {
                it.selectedIndex = index
                scheduleRepaint(it)
            }
        } catch (t: Throwable) {
            expectedInboundIndex = null
            android.util.Log.w(TAG, "updateSelection failed: $t")
        }
    }

    fun uninstall() {
        try {
            backdropMeter?.stop()
            host?.let { (it.parent as? ViewGroup)?.removeView(it) }
        } catch (t: Throwable) {
            android.util.Log.w(TAG, "uninstall failed: $t")
        }
        backdropMeter = null
        host = null
        tabBar = null
        installed = false
    }

    /**
     * 启动背景亮度采样（与 BetterHeybox 的 startBackdropMeter 相同）。库的采样器
     * 自带滞回，isOverLight() 翻转时切回主线程刷新墨色。仅在挂到窗口后启动采样。
     */
    private fun startBackdropMeter(bar: LiquidGlassTabBar) {
        backdropMeter?.stop()
        val meter = LiquidGlassBackdropSampler(bar) {
            val overLight = backdropMeter?.isOverLight() ?: return@LiquidGlassBackdropSampler
            // SPIKE-LOG（临时，真机验证后删除）：观察采样值是否随背景变化。
            android.util.Log.i(TAG, "SPIKE sample overLight=$overLight luma=${backdropMeter?.smoothedLuminance()}")
            bar.post {
                if (tabBar === bar && overLight != backdropOverLight) {
                    backdropOverLight = overLight
                    repaintTabs(bar)
                }
            }
        }
        backdropMeter = meter
        bar.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                meter.start()
            }

            override fun onViewDetachedFromWindow(v: View) {
                meter.stop()
            }
        })
        if (bar.isAttachedToWindow) meter.start()
    }

    /// 库会在选中切换、换 tab 与采样翻转时重涂文字，所以这些时机之后都要刷新一次。
    /// 同时在下一帧补刷，覆盖库异步完成的样式更新。
    private fun scheduleRepaint(bar: LiquidGlassTabBar) {
        repaintTabs(bar)
        bar.post {
            if (tabBar === bar) repaintTabs(bar)
        }
    }

    /**
     * 选中项用主题主色变体（经库的 setSelectedTintColor，文字与图标同色），
     * 未选中项直接给文字与图标设中性墨色。
     */
    private fun repaintTabs(bar: LiquidGlassTabBar) {
        if (tabs.isEmpty()) return
        val accent = if (backdropOverLight) accentOverLight else accentOverDark
        val ink = if (backdropOverLight) INK_OVER_LIGHT else INK_OVER_DARK
        bar.selectedTintColor = accent
        val row = findTabRow(bar, tabs.size) ?: run {
            // 库内部结构不符合预期：保留库默认配色，只影响对比度，不影响功能。
            android.util.Log.w(TAG, "tab row not found; keep library ink")
            return
        }
        val current = bar.selectedIndex
        for (index in 0 until row.childCount) {
            if (index == current) continue
            val item = row.getChildAt(index) as? ViewGroup ?: continue
            item.findFirst(TextView::class.java)?.setTextColor(ink)
            item.findFirst(ImageView::class.java)?.imageTintList = ColorStateList.valueOf(ink)
        }
    }

    /// 库把每个 tab 放在同一行容器里（子节点数等于 tab 数，且每个子节点都是容器）。
    private fun findTabRow(parent: ViewGroup, count: Int): ViewGroup? {
        for (i in 0 until parent.childCount) {
            val child = parent.getChildAt(i) as? ViewGroup ?: continue
            if (child.childCount == count &&
                (0 until count).all { child.getChildAt(it) is ViewGroup }
            ) {
                return child
            }
            findTabRow(child, count)?.let { return it }
        }
        return null
    }

    private fun <T : View> ViewGroup.findFirst(type: Class<T>): T? {
        for (i in 0 until childCount) {
            val child = getChildAt(i)
            if (type.isInstance(child)) return type.cast(child)
            if (child is ViewGroup) child.findFirst(type)?.let { return it }
        }
        return null
    }

    companion object {
        private const val TAG = "LiquidGlassBar"
        const val BAR_HEIGHT_DP = 60f
        const val BOTTOM_OFFSET_DP = 16f
        const val SIDE_MARGIN_DP = 16f
        const val REFRACTION_HEIGHT_DP = 60f
        const val BEVEL_WIDTH_DP = 16f
        const val DISPERSION = 0.12f

        /// 未选中项墨色：浅底用 70% 深色墨，深底用 85% 白色墨（高于库默认，保证与玻璃底对比）。
        private val INK_OVER_LIGHT = 0xB3000000.toInt()
        private val INK_OVER_DARK = 0xD9FFFFFF.toInt()
    }
}
