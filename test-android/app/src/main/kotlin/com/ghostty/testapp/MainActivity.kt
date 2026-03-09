package com.ghostty.testapp

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.inputmethod.EditorInfo
import android.widget.EditText
import android.widget.LinearLayout
import androidx.appcompat.app.AppCompatActivity

/**
 * Test activity that hosts a ghostty terminal view and periodically injects
 * VT demo sequences to exercise the rendering pipeline. A bottom input bar
 * forwards keyboard text through the manual backend's forward_write path.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var terminalView: GhosttyTerminalView
    private val handler = Handler(Looper.getMainLooper())
    private var demoStep = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        terminalView = GhosttyTerminalView(this)
        root.addView(terminalView, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
        ))

        val input = EditText(this).apply {
            hint = "Type here and press Enter"
            imeOptions = EditorInfo.IME_ACTION_SEND
            isSingleLine = true
            setOnEditorActionListener { v, actionId, _ ->
                if (actionId == EditorInfo.IME_ACTION_SEND ||
                    actionId == EditorInfo.IME_ACTION_DONE) {
                    val text = v.text.toString()
                    if (text.isNotEmpty()) {
                        terminalView.sendText(text + "\r")
                        v.text = null
                    }
                    true
                } else false
            }
        }
        root.addView(input, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        setContentView(root)

        handler.postDelayed(demoRunnable, 1500)
    }

    override fun onDestroy() {
        handler.removeCallbacks(demoRunnable)
        super.onDestroy()
    }

    private val demoRunnable = object : Runnable {
        override fun run() {
            if (demoStep > DEMO_SEQUENCES.lastIndex) return
            terminalView.feedData(DEMO_SEQUENCES[demoStep].toByteArray())
            demoStep++
            if (demoStep <= DEMO_SEQUENCES.lastIndex) {
                handler.postDelayed(this, 300)
            }
        }
    }

    companion object {
        private const val ESC = "\u001b"
        private const val CSI = "\u001b["
        private const val OSC = "\u001b]"
        private const val ST = "\u001b\\"

        // Comprehensive VT escape sequence tests derived from xterm.js test suite.
        private val DEMO_SEQUENCES = listOf(
            // ── Clear & Title ──
            "${CSI}2J${CSI}H",
            "${OSC}0;Ghostty Android Test Suite${ST}",

            // ── 1. SGR Text Attributes ──
            "${CSI}1;4m▸ SGR Text Attributes${CSI}0m\r\n",
            "  ${CSI}1mBold${CSI}0m " +
                "${CSI}2mDim${CSI}0m " +
                "${CSI}3mItalic${CSI}0m " +
                "${CSI}4mUnderline${CSI}0m " +
                "${CSI}5mBlink${CSI}0m " +
                "${CSI}7mInverse${CSI}0m " +
                "${CSI}9mStrike${CSI}0m\r\n",
            // Combined attributes
            "  ${CSI}1;3mBold+Italic${CSI}0m " +
                "${CSI}1;4mBold+UL${CSI}0m " +
                "${CSI}2;3mDim+Italic${CSI}0m " +
                "${CSI}1;3;4;9mAll${CSI}0m\r\n",

            // ── 2. Extended Underline Styles (xterm.js 4:N) ──
            "${CSI}1;4m▸ Underline Styles${CSI}0m\r\n",
            "  ${CSI}4:1mStraight${CSI}0m " +
                "${CSI}4:2mDouble${CSI}0m " +
                "${CSI}4:3mCurly${CSI}0m " +
                "${CSI}4:4mDotted${CSI}0m " +
                "${CSI}4:5mDashed${CSI}0m\r\n",
            // Colored underlines
            "  ${CSI}4:3m${CSI}58:2::255:0:0mRedCurly${CSI}0m " +
                "${CSI}4:3m${CSI}58:2::0:255:0mGreenCurly${CSI}0m " +
                "${CSI}4:3m${CSI}58:2::0:128:255mBlueCurly${CSI}0m\r\n",

            // ── 3. ANSI 16 Colors ──
            "${CSI}1;4m▸ ANSI 16 Colors${CSI}0m\r\n",
            // Standard 8 foreground
            buildString {
                append("  FG: ")
                for (i in 30..37) append("${CSI}${i}m■")
                append("${CSI}0m ")
                // Bright 8 foreground
                for (i in 90..97) append("${CSI}${i}m■")
                append("${CSI}0m\r\n")
            },
            // Standard 8 background
            buildString {
                append("  BG: ")
                for (i in 40..47) append("${CSI}${i}m  ")
                append("${CSI}0m ")
                for (i in 100..107) append("${CSI}${i}m  ")
                append("${CSI}0m\r\n")
            },

            // ── 4. 256-Color Palette ──
            "${CSI}1;4m▸ 256-Color Palette${CSI}0m\r\n",
            // 16-231: color cube rows (show 6 rows of 36)
            buildString {
                append("  ")
                for (i in 16..51) append("${CSI}48;5;${i}m ")
                append("${CSI}0m\r\n")
            },
            buildString {
                append("  ")
                for (i in 52..87) append("${CSI}48;5;${i}m ")
                append("${CSI}0m\r\n")
            },
            buildString {
                append("  ")
                for (i in 88..123) append("${CSI}48;5;${i}m ")
                append("${CSI}0m\r\n")
            },
            buildString {
                append("  ")
                for (i in 124..159) append("${CSI}48;5;${i}m ")
                append("${CSI}0m\r\n")
            },
            buildString {
                append("  ")
                for (i in 160..195) append("${CSI}48;5;${i}m ")
                append("${CSI}0m\r\n")
            },
            buildString {
                append("  ")
                for (i in 196..231) append("${CSI}48;5;${i}m ")
                append("${CSI}0m\r\n")
            },
            // Grayscale ramp
            buildString {
                append("  ")
                for (i in 232..255) append("${CSI}48;5;${i}m ")
                append("${CSI}0m\r\n")
            },

            // ── 5. True Color (24-bit) Gradient ──
            "${CSI}1;4m▸ 24-bit True Color${CSI}0m\r\n",
            buildString {
                append("  ")
                for (i in 0..35) {
                    val r = (255 * i / 35)
                    val g = 0
                    val b = (255 - 255 * i / 35)
                    append("${CSI}48;2;${r};${g};${b}m ")
                }
                append("${CSI}0m\r\n")
            },
            buildString {
                append("  ")
                for (i in 0..35) {
                    val r = 0
                    val g = (255 * i / 35)
                    val b = 0
                    append("${CSI}48;2;${r};${g};${b}m ")
                }
                append("${CSI}0m\r\n")
            },

            // ── 6. Box Drawing & Line Art ──
            "${CSI}1;4m▸ Box Drawing${CSI}0m\r\n",
            "  ┌──────────────────────────┐\r\n",
            "  │ ${CSI}36mUnicode Box Drawing${CSI}0m     │\r\n",
            "  ├──────────┬───────────────┤\r\n",
            "  │ ${CSI}33mLeft${CSI}0m     │ ${CSI}35mRight${CSI}0m         │\r\n",
            "  └──────────┴───────────────┘\r\n",

            // ── 7. DEC Line Drawing Characters (G0 set) ──
            "${CSI}1;4m▸ DEC Line Drawing (G0)${CSI}0m\r\n",
            "  ${ESC}(0lqqqqqqqqqqqqqqqqqqqqqqqqqqk${ESC}(B\r\n",
            "  ${ESC}(0x${ESC}(B ${CSI}32mDEC Special Graphics${CSI}0m    ${ESC}(0x${ESC}(B\r\n",
            "  ${ESC}(0tqqqqqqqqqqqqqqqqqqqqqqqqqqqu${ESC}(B\r\n",
            "  ${ESC}(0x${ESC}(B Diamond:${ESC}(0`${ESC}(B Degree:${ESC}(0f${ESC}(B Bullet:${ESC}(0~${ESC}(B ${ESC}(0x${ESC}(B\r\n",
            "  ${ESC}(0mqqqqqqqqqqqqqqqqqqqqqqqqqqj${ESC}(B\r\n",

            // ── 8. Cursor Movement ──
            "${CSI}1;4m▸ Cursor Positioning${CSI}0m\r\n",
            buildString {
                // Draw dots at specific positions
                append("  ${CSI}s") // Save cursor
                append("${CSI}1C●") // Move right 1, draw
                append("${CSI}1C●")
                append("${CSI}1C●")
                append("${CSI}1C●")
                append("${CSI}1C●")
                append(" (spaced with CUF)")
                append("${CSI}u") // Restore cursor - but we moved, so just newline
                append("\r\n")
            },

            // ── 9. Insert/Delete Operations ──
            "${CSI}1;4m▸ Insert & Delete${CSI}0m\r\n",
            "  ABCDEFGHIJ${CSI}5D${CSI}3P___\r\n", // Delete 3 chars at pos 5

            // ── 10. Scrolling Region ──
            "${CSI}1;4m▸ Scroll Region Test${CSI}0m\r\n",
            buildString {
                // Simulate scroll region content
                append("  ┌─ scroll region ─┐\r\n")
                append("  │ Line A           │\r\n")
                append("  │ Line B           │\r\n")
                append("  │ Line C           │\r\n")
                append("  └──────────────────┘\r\n")
            },

            // ── 11. OSC 8 Hyperlinks ──
            "${CSI}1;4m▸ OSC 8 Hyperlinks${CSI}0m\r\n",
            "  ${OSC}8;;https://github.com/ghostty-org/ghostty${ST}${CSI}36;4mGhostty on GitHub${CSI}0m${OSC}8;;${ST}\r\n",

            // ── 12. Wide Characters (CJK) ──
            "${CSI}1;4m▸ Wide Characters (CJK)${CSI}0m\r\n",
            "  你好世界 こんにちは 안녕하세요\r\n",
            "  ${CSI}33m中文${CSI}0m${CSI}35m日本語${CSI}0m${CSI}36m한국어${CSI}0m\r\n",

            // ── 13. Emoji ──
            "${CSI}1;4m▸ Emoji${CSI}0m\r\n",
            "  🚀 🎉 🔥 ✨ 💻 🦄 🌈 ⚡ 🎨 🧪\r\n",

            // ── 14. Cursor Styles ──
            "${CSI}1;4m▸ Cursor Styles${CSI}0m\r\n",
            "  Block:${CSI}2 q█ Bar:${CSI}6 q| UL:${CSI}4 q_ Default:${CSI}0 q\r\n",

            // ── 15. Bright + Background Combos ──
            "${CSI}1;4m▸ Color Matrix${CSI}0m\r\n",
            buildString {
                val labels = arrayOf("BLK", "RED", "GRN", "YEL", "BLU", "MAG", "CYN", "WHT")
                append("     ")
                for (l in labels) append(" $l")
                append("\r\n")
                for ((bi, bg) in (40..47).withIndex()) {
                    append("  ${labels[bi]}")
                    for (fg in 30..37) {
                        append(" ${CSI}${fg};${bg}m ${labels[fg - 30]} ${CSI}0m")
                    }
                    // Only show first 3 rows to save space
                    if (bi >= 2) {
                        append("\r\n  ... (truncated)\r\n")
                        break
                    }
                    append("\r\n")
                }
            },

            // ── Final: Shell Prompt ──
            "\r\n${CSI}1;32m✓ All tests rendered${CSI}0m\r\n\r\n" +
                "${CSI}38;2;80;250;123m❯${CSI}0m ",
        )
    }
}
