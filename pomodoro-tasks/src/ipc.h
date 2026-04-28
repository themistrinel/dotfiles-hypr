#pragma once
#include <string>
#include <functional>

// Parses a JSON action message from the WebView and dispatches it.
// Returns a JS snippet to evaluate (may be empty).
using JSEval = std::function<void(std::string)>;

void ipc_dispatch(const std::string& json_msg, JSEval eval);
