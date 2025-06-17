/*
 * 视频播放器
 * author: 05兰寅银 朱灿银 周俊
 * 兰寅银: 2023051604042 email: lan_yinyin@qq.com
 * 朱灿银: 2023051604043 email: 2892825621@qq.com
 * 周俊: 2023051604055 email: zhoujun1108@126.com
 * date: 2025.06-2025.07
 */

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon("/usr/share/icons/breeze/places/24/folder-videos.svg"));
    app.setApplicationName("Video Player");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("VideoPlayer", "Main");

    return app.exec();
}
