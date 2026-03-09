package com.ghostty.testapp

import android.content.Context
import android.opengl.GLSurfaceView
import android.util.AttributeSet
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

/**
 * A GLSurfaceView that hosts a ghostty terminal surface.
 *
 * EGL context creation and thread management are handled by GLSurfaceView.
 * All native calls are dispatched on the GL thread via [queueEvent].
 */
class GhosttyTerminalView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : GLSurfaceView(context, attrs) {

    private val density = context.resources.displayMetrics.density

    init {
        setEGLContextClientVersion(3)
        setRenderer(TerminalRenderer())
        renderMode = RENDERMODE_CONTINUOUSLY
    }

    /** Feed raw VT byte data into the terminal (called from any thread). */
    fun feedData(data: ByteArray) {
        queueEvent { nativeFeedData(data) }
    }

    /** Send keyboard text to the terminal (called from any thread). */
    fun sendText(text: String) {
        queueEvent { nativeSendText(text) }
    }

    private inner class TerminalRenderer : Renderer {
        override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
            nativeInit()
            nativeCreateSurface(holder.surface, density)
        }

        override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
            nativeSetSize(width, height)
        }

        override fun onDrawFrame(gl: GL10?) {
            nativeTick()
            nativeDraw()
        }
    }

    override fun onDetachedFromWindow() {
        queueEvent { nativeDestroy() }
        super.onDetachedFromWindow()
    }

    companion object {
        init {
            System.loadLibrary("ghostty_bridge")
        }
    }

    // JNI methods implemented in ghostty_bridge.c
    private external fun nativeInit()
    private external fun nativeCreateSurface(surface: android.view.Surface, density: Float)
    private external fun nativeTick()
    private external fun nativeDraw()
    private external fun nativeFeedData(data: ByteArray)
    private external fun nativeSendText(text: String)
    private external fun nativeSetSize(width: Int, height: Int)
    private external fun nativeDestroy()
}
