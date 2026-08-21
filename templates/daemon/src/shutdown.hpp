#pragma once

#include <chrono>

#include "service.hpp"

// Where the operating system is allowed in, and the only place. This header
// names none of its types, so nothing that includes it inherits them.

namespace mydaemon::shutdown {

/// Blocks the signals a service manager sends, so that wait() below is the only
/// place they are received. Call it once, before anything else in the process.
///
/// Two functions rather than an object with a constructor: a signal mask
/// belongs to the process, not to a scope, and a type that could be created
/// twice would be saying otherwise.
void block();

/// Waits up to `limit` for SIGTERM, SIGINT or SIGHUP.
[[nodiscard]] auto wait(std::chrono::milliseconds limit) -> service::Wakeup;

}  // namespace mydaemon::shutdown
