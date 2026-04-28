#include "app.h"

int main(int argc, char** argv) {
    App app;
    g_app = &app;
    app.run(argc, argv);
    return 0;
}
