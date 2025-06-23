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
    Q_PROPERTY(bool dragActive READ dragActive NOTIFY dragActiveChanged)
public:
    explicit DragDropManager(QObject *parent = nullptr);

    bool dragActive() const;

    Q_INVOKABLE void setWindow(QWindow *window);

signals:
    void dragActiveChanged();
    void filesDropped(const QList<QUrl> &urls);

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    bool m_dragActive;
    QWindow *m_window;
};
