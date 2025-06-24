#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QUrl>
#include <QWindow>
#include <QEvent>

class DragDropManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool dragActive READ dragActive NOTIFY dragActiveChanged) // 拖动状态
public:
    explicit DragDropManager(QObject *parent = nullptr);

    bool dragActive() const;

    Q_INVOKABLE void setWindow(QWindow *window); // 设置窗口

signals:
    void dragActiveChanged();
    void filesDropped(const QList<QUrl> &urls);

protected:
    bool eventFilter(QObject *watched, QEvent *event) override; // 重写事件处理

private:
    bool m_dragActive;
    QWindow *m_window;
};
