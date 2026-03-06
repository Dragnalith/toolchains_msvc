#include <my/App.h>

class MyApp : public my::App {
public:
    void Update(my::Frame& frame) override;
    void Render(const my::Frame& frame) override;
};