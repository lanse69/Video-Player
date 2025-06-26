cmake_minimum_required(VERSION 3.30.3)

project(Video-Player VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Multimedia MultimediaWidgets QuickDialogs2 QuickDialogs2QuickImpl)

qt_standard_project_setup(REQUIRES 6.9)

qt_add_executable(appVideo-Player)

qt_add_qml_module(appVideo-Player
    URI VideoPlayer
    VERSION 1.0
    SOURCES
        main.cpp
        mediaengine.h mediaengine.cpp
        playlistmodel.h playlistmodel.cpp
        capturemanager.h capturemanager.cpp
        dragdropmanager.h dragdropmanager.cpp
        danmu.h danmu.cpp
        font.h font.cpp
        danmutrack.h danmutrack.cpp
        danmumanager.h danmumanager.cpp
        downloadmanager.h downloadmanager.cpp
    QML_FILES
        Main.qml
        Actions.qml
        Dialogs.qml
        Player.qml
        Playlist.qml
        Content.qml
        ControlBar.qml
        Danmu.qml
        DanmuRender.js
    RESOURCES resources.qrc
)

source_group("QML_Files" FILES
    Main.qml
    Actions.qml
    Dialogs.qml
    Player.qml
    Playlist.qml
    Content.qml
    ControlBar.qml
    Danmu.qml
    DanmuRender.js
)

target_compile_features(appVideo-Player PRIVATE cxx_std_23)

target_link_libraries(appVideo-Player
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::Multimedia
        Qt6::MultimediaWidgets
        Qt6::QuickDialogs2
        Qt6::QuickDialogs2QuickImpl
)

set_target_properties(appVideo-Player PROPERTIES
    AUTORCC TRUE
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appVideo-Player
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
install(TARGETS appVideo-Player
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

pkg_check_modules(AVCODEC REQUIRED libavcodec)
pkg_check_modules(AVFORMAT REQUIRED libavformat)
pkg_check_modules(AVUTIL REQUIRED libavutil)
pkg_check_modules(SWSCALE REQUIRED libswscale)
pkg_check_modules(AVFILTER REQUIRED libavfilter)

# 链接 FFmpeg 库
target_link_libraries(appVideo-Player
    PRIVATE
    ${AVCODEC_LIBRARIES}
    ${AVFORMAT_LIBRARIES}
    ${AVUTIL_LIBRARIES}
    ${SWSCALE_LIBRARIES}
    ${AVFILTER_LIBRARIES}
)

# 安装应用程序图标
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-16.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/16x16/apps
        RENAME video-player.png
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-22.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/22x22/apps
        RENAME video-player.png
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-32.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/32x32/apps
        RENAME video-player.png
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-44.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/44x44/apps
        RENAME video-player.png
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-48.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/48x48/apps
        RENAME video-player.png
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-64.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/64x64/apps
        RENAME video-player.png
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-128.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/128x128/apps
        RENAME video-player.png
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-150.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/150x150/apps
        RENAME video-player.png
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-256.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/256x256/apps
        RENAME video-player.png
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-310.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/310x310/apps
        RENAME video-player.png
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/video-player-512.png
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/512x512/apps
        RENAME video-player.png
)

# 安装启动脚本
install(PROGRAMS ${CMAKE_CURRENT_SOURCE_DIR}/scripts/video-player.sh
        DESTINATION ${CMAKE_INSTALL_BINDIR}
        RENAME video-player.sh
)

# 安装桌面启动文件
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/video-player.desktop
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications
)










































# set(CMAKE_CXX_STANDARD_REQUIRED ON) # Globally preventing the fallback behaviour of C++ standard
#qt_add_executable(Video-Player)  //Creates and finalizes an application target of a platform-specific type.
#This command performs the following tasks:
#    1. Create a CMake target of the appropriate type for the target platform.
#    2. Link the target to the Qt::Core library.
#    3. Handle finalization of the CMake target.

# set(CMAKE_CXX_STANDARD_REQUIRED ON) # Globally preventing the fallback behaviour of C++ standard

# qt_standard_project_setup()  #set(CMAKE_AUTOUIC ON)  set(CMAKE_AUTOMOC ON)






# cmake_minimum_required(VERSION 3.16)
#
# project(Video-Player VERSION 0.1 LANGUAGES CXX)
#
# @if !true
# set(CMAKE_AUTOMOC ON)
# @endif
# set(CMAKE_CXX_STANDARD_REQUIRED ON)
#
# find_package(Qt6 REQUIRED COMPONENTS Quick)
#
# @if true
# @if true
# qt_standard_project_setup(REQUIRES 6.9)
# @else
# qt_standard_project_setup()
# @endif
# @endif
#
# qt_add_executable(appVideo-Player
#     main.cpp
# )
#
# qt_add_qml_module(appVideo-Player
#     URI Video-Player
#     VERSION 1.0
#     QML_FILES
#         Main.qml
# )
#
# # Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# # If you are developing for iOS or macOS you should consider setting an
# # explicit, fixed bundle identifier manually though.
# set_target_properties(appVideo-Player PROPERTIES
# #    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appVideo-Player
#     MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
#     MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
#     MACOSX_BUNDLE TRUE
#     WIN32_EXECUTABLE TRUE
# )
#
# target_link_libraries(appVideo-Player
#     PRIVATE Qt6::Quick
# )
#
# include(GNUInstallDirs)
# install(TARGETS appVideo-Player
#     BUNDLE DESTINATION .
#     LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
#     RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
# )
