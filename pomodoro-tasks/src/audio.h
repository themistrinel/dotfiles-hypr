#pragma once
#include "models.h"
#include <string>

namespace Audio {
    void set_pack(const std::string& pack);

    void play_focus_start(const AppState::SoundCfg& cfg = {});
    void play_break      (const AppState::SoundCfg& cfg = {});
    void play_pause      (const AppState::SoundCfg& cfg = {});
    void play_task_done  (const AppState::SoundCfg& cfg = {});
    void play_relax      (const AppState::SoundCfg& cfg = {}); // calm long-break / task-done break
}
