package top.talyra42.verifin;

import com.example.liquidglass.BackdropLuminanceMeter;
import com.example.liquidglass.LiquidGlassView;

import kotlin.Unit;

/**
 * 包装库的 BackdropLuminanceMeter。
 *
 * 该类在 QWEA0 库中是 Kotlin `internal`：字节码为 public，但 Kotlin 代码无法引用，
 * 因此用 Java 包装（与 BetterHeybox 的做法相同）。不使用反射，R8 无需额外 keep 规则。
 */
final class LiquidGlassBackdropSampler {

    private final BackdropLuminanceMeter meter;

    /**
     * @param view 被采样的玻璃视图（底栏自身，其 backdrop 为 Flutter 内容）
     * @param onSample 每次采样回调后调用，调用方在其中读取 [#isOverLight]
     */
    LiquidGlassBackdropSampler(LiquidGlassView view, Runnable onSample) {
        this.meter = new BackdropLuminanceMeter(view, luma -> {
            onSample.run();
            return Unit.INSTANCE;
        });
    }

    /** 库自带滞回的「底下是否为浅色内容」结果。 */
    boolean isOverLight() {
        return meter.isOverLight();
    }

    /** 平滑后的背景亮度（0–1），仅用于诊断。 */
    float smoothedLuminance() {
        return meter.getSmoothedLuminance();
    }

    void start() {
        meter.start();
    }

    void stop() {
        meter.stop();
    }
}
