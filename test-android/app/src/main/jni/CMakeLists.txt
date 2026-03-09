cmake_minimum_required(VERSION 3.22.1)
project("ghostty_bridge")

# Import pre-built libghostty.so
add_library(ghostty SHARED IMPORTED)
set_target_properties(ghostty PROPERTIES
    IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libghostty.so
)

# JNI bridge library
add_library(ghostty_bridge SHARED ghostty_bridge.c)

target_link_libraries(ghostty_bridge
    ghostty
    android
    log
    EGL
    GLESv3
)
