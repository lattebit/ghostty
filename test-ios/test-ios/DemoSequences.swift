/// VT escape sequence test suite (matching the Android test app).
enum DemoSequences {
    private static let ESC = "\u{1b}"
    private static let CSI = "\u{1b}["
    private static let OSC = "\u{1b}]"
    private static let ST  = "\u{1b}\\"

    static let all: [String] = [
        // Clear & Title
        "\(CSI)2J\(CSI)H",
        "\(OSC)0;Ghostty iOS Test Suite\(ST)",

        // 1. SGR Text Attributes
        "\(CSI)1;4m\u{25b8} SGR Text Attributes\(CSI)0m\r\n",
        "  \(CSI)1mBold\(CSI)0m \(CSI)2mDim\(CSI)0m \(CSI)3mItalic\(CSI)0m \(CSI)4mUnderline\(CSI)0m \(CSI)5mBlink\(CSI)0m \(CSI)7mInverse\(CSI)0m \(CSI)9mStrike\(CSI)0m\r\n",
        "  \(CSI)1;3mBold+Italic\(CSI)0m \(CSI)1;4mBold+UL\(CSI)0m \(CSI)2;3mDim+Italic\(CSI)0m \(CSI)1;3;4;9mAll\(CSI)0m\r\n",

        // 2. Extended Underline Styles
        "\(CSI)1;4m\u{25b8} Underline Styles\(CSI)0m\r\n",
        "  \(CSI)4:1mStraight\(CSI)0m \(CSI)4:2mDouble\(CSI)0m \(CSI)4:3mCurly\(CSI)0m \(CSI)4:4mDotted\(CSI)0m \(CSI)4:5mDashed\(CSI)0m\r\n",
        "  \(CSI)4:3m\(CSI)58:2::255:0:0mRedCurly\(CSI)0m \(CSI)4:3m\(CSI)58:2::0:255:0mGreenCurly\(CSI)0m \(CSI)4:3m\(CSI)58:2::0:128:255mBlueCurly\(CSI)0m\r\n",

        // 3. ANSI 16 Colors
        "\(CSI)1;4m\u{25b8} ANSI 16 Colors\(CSI)0m\r\n",
        {
            var s = "  FG: "
            for i in 30...37 { s += "\(CSI)\(i)m\u{25a0}" }
            s += "\(CSI)0m "
            for i in 90...97 { s += "\(CSI)\(i)m\u{25a0}" }
            s += "\(CSI)0m\r\n"
            return s
        }(),
        {
            var s = "  BG: "
            for i in 40...47 { s += "\(CSI)\(i)m  " }
            s += "\(CSI)0m "
            for i in 100...107 { s += "\(CSI)\(i)m  " }
            s += "\(CSI)0m\r\n"
            return s
        }(),

        // 4. 256-Color Palette (first + last rows)
        "\(CSI)1;4m\u{25b8} 256-Color Palette\(CSI)0m\r\n",
        {
            var s = "  "
            for i in 16...51 { s += "\(CSI)48;5;\(i)m " }
            s += "\(CSI)0m\r\n"
            return s
        }(),
        {
            var s = "  "
            for i in 232...255 { s += "\(CSI)48;5;\(i)m " }
            s += "\(CSI)0m\r\n"
            return s
        }(),

        // 5. True Color (24-bit) Gradient
        "\(CSI)1;4m\u{25b8} 24-bit True Color\(CSI)0m\r\n",
        {
            var s = "  "
            for i in 0...35 {
                let r = 255 * i / 35
                let b = 255 - 255 * i / 35
                s += "\(CSI)48;2;\(r);0;\(b)m "
            }
            s += "\(CSI)0m\r\n"
            return s
        }(),

        // 6. Box Drawing
        "\(CSI)1;4m\u{25b8} Box Drawing\(CSI)0m\r\n",
        "  \u{250c}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2510}\r\n",
        "  \u{2502} \(CSI)36mUnicode Box Drawing\(CSI)0m     \u{2502}\r\n",
        "  \u{2514}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2518}\r\n",

        // 7. Wide Characters (CJK)
        "\(CSI)1;4m\u{25b8} Wide Characters (CJK)\(CSI)0m\r\n",
        "  \u{4f60}\u{597d}\u{4e16}\u{754c} \u{3053}\u{3093}\u{306b}\u{3061}\u{306f} \u{c548}\u{b155}\u{d558}\u{c138}\u{c694}\r\n",
        "  \(CSI)33m\u{4e2d}\u{6587}\(CSI)0m\(CSI)35m\u{65e5}\u{672c}\u{8a9e}\(CSI)0m\(CSI)36m\u{d55c}\u{ad6d}\u{c5b4}\(CSI)0m\r\n",

        // 8. Emoji
        "\(CSI)1;4m\u{25b8} Emoji\(CSI)0m\r\n",
        "  \u{1f680} \u{1f389} \u{1f525} \u{2728} \u{1f4bb} \u{1f984} \u{1f308} \u{26a1} \u{1f3a8} \u{1f9ea}\r\n",

        // Final: Shell Prompt
        "\r\n\(CSI)1;32m\u{2713} All tests rendered\(CSI)0m\r\n\r\n\(CSI)38;2;80;250;123m\u{276f}\(CSI)0m ",
    ]
}
