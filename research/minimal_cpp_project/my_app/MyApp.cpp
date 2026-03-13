#include "MyApp.h"
#include <my/Frame.h>
#include <my/Log.h>
#include <my_dyn_lib/Helpers.h>

void MyApp::Update(my::Frame& frame) {
    MY_LOG("Frame {}: MyApp::Update", frame.frameNumber);
    MY_LOG("RUN: Square({}) = {}", frame.frameNumber, my_dyn::Square(frame.frameNumber));
}

void MyApp::Render(const my::Frame& frame) {
    MY_LOG("Frame {}: MyApp::Render", frame.frameNumber);
}