#pragma once
#include "models.h"
#include <string>

// Loads/saves AppState to data/tasks.json relative to the binary's working dir.
namespace TaskStore {
    AppState load();
    void     save(const AppState&);
    std::string new_id();
}
