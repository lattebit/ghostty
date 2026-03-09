// JNI bridge between Kotlin and the ghostty C embedding API.
//
// Lifecycle:
//   1. nativeInit()          — ghostty_init + config + app
//   2. nativeCreateSurface() — ghostty_surface_new (Android platform)
//   3. nativeTick/Draw()     — per-frame rendering loop
//   4. nativeFeedData()      — inject VT byte streams
//   5. nativeSendText()      — forward keyboard input
//   6. nativeDestroy()       — tear down surface and app

#include <jni.h>
#include <android/log.h>
#include <android/native_window.h>
#include <android/native_window_jni.h>

#include "ghostty.h"

#define TAG "GhosttyBridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, TAG, __VA_ARGS__)

static ghostty_app_t g_app = NULL;
static ghostty_surface_t g_surface = NULL;
static ANativeWindow *g_window = NULL;

// --- Runtime callbacks ---

static void wakeup_cb(void *userdata) {
    (void)userdata;
}

static bool action_cb(ghostty_app_t app, ghostty_target_s target,
                       ghostty_action_s action) {
    (void)app;
    (void)target;

    if (action.tag == GHOSTTY_ACTION_FORWARD_WRITE) {
        const ghostty_action_forward_write_s *fw = &action.action.forward_write;
        // Log the forwarded write data so we can verify the manual backend
        // is correctly relaying keyboard input.
        LOGI("forward_write: %.*s", (int)fw->len, (const char *)fw->data);
        return true;
    }

    return false;
}

static void read_clipboard_cb(void *userdata, ghostty_clipboard_e clipboard,
                                void *context) {
    (void)userdata;
    (void)clipboard;
    (void)context;
}

static void confirm_read_clipboard_cb(void *userdata, const char *text,
                                       void *context,
                                       ghostty_clipboard_request_e req) {
    (void)userdata;
    (void)text;
    (void)context;
    (void)req;
}

static void write_clipboard_cb(void *userdata, ghostty_clipboard_e clipboard,
                                const ghostty_clipboard_content_s *content,
                                size_t content_len, bool confirm) {
    (void)userdata;
    (void)clipboard;
    (void)content;
    (void)content_len;
    (void)confirm;
}

static void close_surface_cb(void *userdata, bool process_active) {
    (void)userdata;
    (void)process_active;
    LOGI("close_surface requested");
}

// --- JNI methods ---

JNIEXPORT void JNICALL
Java_com_ghostty_testapp_GhosttyTerminalView_nativeInit(JNIEnv *env,
                                                         jobject thiz) {
    (void)env;
    (void)thiz;

    // Global init
    char *argv[] = {"ghostty", NULL};
    int rc = ghostty_init(1, argv);
    if (rc != GHOSTTY_SUCCESS) {
        LOGW("ghostty_init failed: %d", rc);
        return;
    }

    // Config
    ghostty_config_t config = ghostty_config_new();
    ghostty_config_finalize(config);

    // Runtime config with callbacks
    ghostty_runtime_config_s rt = {
        .userdata = NULL,
        .supports_selection_clipboard = false,
        .wakeup_cb = wakeup_cb,
        .action_cb = action_cb,
        .read_clipboard_cb = read_clipboard_cb,
        .confirm_read_clipboard_cb = confirm_read_clipboard_cb,
        .write_clipboard_cb = write_clipboard_cb,
        .close_surface_cb = close_surface_cb,
    };

    g_app = ghostty_app_new(&rt, config);
    if (!g_app) {
        LOGW("ghostty_app_new failed");
        return;
    }

    LOGI("ghostty initialized");
}

JNIEXPORT void JNICALL
Java_com_ghostty_testapp_GhosttyTerminalView_nativeCreateSurface(
    JNIEnv *env, jobject thiz, jobject surface, jfloat density) {
    (void)thiz;

    if (!g_app) return;

    // Acquire the native window from the Android Surface
    g_window = ANativeWindow_fromSurface(env, surface);
    if (!g_window) {
        LOGW("ANativeWindow_fromSurface failed");
        return;
    }

    ghostty_surface_config_s cfg = ghostty_surface_config_new();
    cfg.platform_tag = GHOSTTY_PLATFORM_ANDROID;
    cfg.platform.android.native_window = g_window;
    cfg.scale_factor = (double)density;

    g_surface = ghostty_surface_new(g_app, &cfg);
    if (!g_surface) {
        LOGW("ghostty_surface_new failed");
        ANativeWindow_release(g_window);
        g_window = NULL;
        return;
    }

    ghostty_surface_set_focus(g_surface, true);

    LOGI("surface created (density=%.1f)", density);
}

JNIEXPORT void JNICALL
Java_com_ghostty_testapp_GhosttyTerminalView_nativeTick(JNIEnv *env,
                                                         jobject thiz) {
    (void)env;
    (void)thiz;
    if (g_app) ghostty_app_tick(g_app);
}

JNIEXPORT void JNICALL
Java_com_ghostty_testapp_GhosttyTerminalView_nativeDraw(JNIEnv *env,
                                                         jobject thiz) {
    (void)env;
    (void)thiz;
    if (g_surface) ghostty_surface_draw(g_surface);
}

JNIEXPORT void JNICALL
Java_com_ghostty_testapp_GhosttyTerminalView_nativeFeedData(
    JNIEnv *env, jobject thiz, jbyteArray data) {
    (void)thiz;
    if (!g_surface) return;

    jsize len = (*env)->GetArrayLength(env, data);
    jbyte *bytes = (*env)->GetByteArrayElements(env, data, NULL);
    ghostty_surface_feed_data(g_surface, (const uint8_t *)bytes, (size_t)len);
    (*env)->ReleaseByteArrayElements(env, data, bytes, JNI_ABORT);
}

JNIEXPORT void JNICALL
Java_com_ghostty_testapp_GhosttyTerminalView_nativeSendText(
    JNIEnv *env, jobject thiz, jstring text) {
    (void)thiz;
    if (!g_surface) return;

    const char *str = (*env)->GetStringUTFChars(env, text, NULL);
    size_t len = (*env)->GetStringUTFLength(env, text);
    ghostty_surface_text(g_surface, str, len);
    (*env)->ReleaseStringUTFChars(env, text, str);
}

JNIEXPORT void JNICALL
Java_com_ghostty_testapp_GhosttyTerminalView_nativeSetSize(
    JNIEnv *env, jobject thiz, jint width, jint height) {
    (void)env;
    (void)thiz;
    if (g_surface) {
        ghostty_surface_set_size(g_surface, (uint32_t)width, (uint32_t)height);
    }
}

JNIEXPORT void JNICALL
Java_com_ghostty_testapp_GhosttyTerminalView_nativeDestroy(JNIEnv *env,
                                                            jobject thiz) {
    (void)env;
    (void)thiz;

    if (g_surface) {
        ghostty_surface_free(g_surface);
        g_surface = NULL;
    }
    if (g_app) {
        ghostty_app_free(g_app);
        g_app = NULL;
    }
    if (g_window) {
        ANativeWindow_release(g_window);
        g_window = NULL;
    }

    LOGI("ghostty destroyed");
}
