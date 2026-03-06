#include "MyApp.h"
#include <my/Frame.h>
#include <my/Log.h>

void MyApp::Update(my::Frame& frame) {
    MY_LOG("Frame {}: MyApp::Update", frame.frameNumber);
}

void MyApp::Render(const my::Frame& frame) {
    MY_LOG("Frame {}: MyApp::Render", frame.frameNumber);
}