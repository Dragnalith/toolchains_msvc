#pragma once

#include <my/App.h>

namespace my {

class EventLoop {
public:
    EventLoop(App& app);
    void Run(int numberOfFrame);
private:
    App& m_app;
};

}