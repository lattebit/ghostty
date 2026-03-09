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

        // Start injecting demo VT data after a short delay to allow the
        // surface to initialize.
        handler.postDelayed(demoRunnable, 1000)
    }

    override fun onDestroy() {
        handler.removeCallbacks(demoRunnable)
        super.onDestroy()
    }

    private val demoRunnable = object : Runnable {
        override fun run() {
            feedDemoData()
            if (demoStep <= DEMO_SEQUENCES.lastIndex) {
                handler.postDelayed(this, 500)
            }
        }
    }

    private fun feedDemoData() {
        if (demoStep > DEMO_SEQUENCES.lastIndex) return
        terminalView.feedData(DEMO_SEQUENCES[demoStep].toByteArray())
        demoStep++
    }

    companion object {
        // VT escape sequences that exercise various terminal capabilities.
        private val DEMO_SEQUENCES = listOf(
            // Clear screen and move to home
            "\u001b[2J\u001b[H",
            // Bold white title
            "\u001b[1mGhostty Android Test\u001b[0m\r\n\r\n",
            // Basic ANSI colors
            "\u001b[31mRed \u001b[32mGreen \u001b[34mBlue \u001b[33mYellow\u001b[0m\r\n",
            // 256-color palette sample
            "\u001b[38;5;208mOrange(208) \u001b[38;5;129mPurple(129) \u001b[38;5;51mCyan(51)\u001b[0m\r\n",
            // 24-bit true color
            "\u001b[38;2;255;105;180mHotPink \u001b[38;2;0;255;127mSpringGreen\u001b[0m\r\n",
            // Background colors
            "\r\n\u001b[41m Red BG \u001b[42m Green BG \u001b[44m Blue BG \u001b[0m\r\n",
            // Cursor positioning
            "\r\n\u001b[1;4mTerminal capabilities working!\u001b[0m\r\n",
            // Simulated shell prompt
            "\r\n\u001b[32mghostty\u001b[0m:\u001b[34m~\u001b[0m\$ ",
        )
    }
}
