#pragma once

namespace myapp::startup {

/// Builds what the program is made of, and runs it.
///
/// Here rather than in main() because main() cannot be called: this can, which
/// is what lets test/run-app.sh check that the pieces fit together by running
/// them rather than by reading them.
[[nodiscard]] auto run(int argc, char** argv) -> int;

}  // namespace myapp::startup
