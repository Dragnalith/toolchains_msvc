#include <my/EventLoop.h>
#include <private/InternalStuff.h>

namespace my {

EventLoop::EventLoop(App& app) : m_app(app) {

}

void EventLoop::Run(int numberOfFrame) {
    for (int i = 0; i < numberOfFrame; i++) {
        Frame frame{ i };
        InitFrame(frame);
        m_app.Update(frame);
        m_app.Render(frame);
    }
}
}