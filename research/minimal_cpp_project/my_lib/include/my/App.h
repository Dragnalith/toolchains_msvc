#pragma once

namespace my {

struct Frame;

class App {
public:
    virtual ~App();
    virtual void Update(Frame& frame) = 0;
    virtual void Render(const Frame& frame) = 0;
};

}