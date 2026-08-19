# mycli

![C++23](https://img.shields.io/badge/C%2B%2B-23-blue.svg)
![CMake 3.28+](https://img.shields.io/badge/CMake-3.28%2B-blue.svg)
![License 0BSD](https://img.shields.io/badge/license-0BSD-blue.svg)

A C++ command line program that builds, tests, installs and packages itself from
the first commit. Rename it and start writing.

Generated from [cpp-boilerplate](https://github.com/skipbit/cpp-boilerplate),
where the template itself is developed and where issues about it belong.

There is no build badge here on purpose. **Use this template** copies this file
into your repository unchanged, and a workflow badge names the repository it
belongs to - so it would sit at the top of your README reporting somebody
else's build, green whatever yours does. The three above describe the code, and
stay true after the copy. Add your own once you have a repository:

```
[![main check](https://github.com/YOU/YOURS/actions/workflows/main-check.yml/badge.svg)](https://github.com/YOU/YOURS/actions/workflows/main-check.yml)
```

## Start

```sh
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
```

CMake, a compiler and Ninja are enough; CLI11 and the test framework are fetched
during configuration.

Presets: `debug` (warnings as errors), `release`, `asan`, `tsan`, `tidy`.

What it does out of the box, so that there is something to run:

```sh
./build/debug/mycli --words README.md
```

## Make it yours

Everything is called `mycli`. Rename it:

```sh
./scripts/rename.sh yourtool
./scripts/install-hooks.sh
```

The first covers the namespace, both targets, the generated version header, the
name the program prints in its own messages, and the homepage in `project()`. The homepage comes from the `origin` remote, or
from a second argument (`./scripts/rename.sh yourtool https://github.com/you/yourtool`);
with neither, the line is deleted rather than left pointing at the template.

The second points git at `.githooks/`, which runs clang-format, clang-tidy,
actionlint and shellcheck on the files in a commit; anything not installed is
skipped rather than treated as a failure. The dev container runs it for you.

Then replace what it counts with what your program does. `counting`, `report`
and the flags in `command_line` are an example of the shape, not a feature.

## How it is laid out

```
src/               everything, because nothing here is installed as a header
test/              one test file per source file, plus one that runs the program
cmake/             the generated version header's template
docs/              why the configuration is what it is
.devcontainer/     the pinned toolchain, used by CI and the dev container
.githooks/         the checks that run before a commit
```

There is no `include/`. A program publishes a command, not an API: no other
project compiles against these headers, so none of them is installed and
changing one breaks nobody. That is the difference from the library template,
and it is why everything sits in `src/`.

**`main()` decides nothing.** It parses, counts, prints and turns the result
into an exit status. Everything it calls lives in `mycli_lib`, a static library
that is built but never installed - because a function in a library can be
tested and a function in `main()` can only be checked by starting a process and
reading its output. That is the whole reason for the extra target.

**One feature is one header, one implementation and one test.** Three of them
here, and each one does a single thing:

| unit | does | knows about |
| --- | --- | --- |
| `command_line` | turns `argv` into an `Options` | CLI11, and nothing else does |
| `counting` | counts lines, words and bytes in a stream | nothing |
| `report` | turns counts into the line that gets printed | the other two |

`counting::count` takes a `std::istream` rather than a file name, which is what
lets its tests pass a `std::istringstream` instead of writing files. CLI11
appears in exactly one `.cpp` file and in no header, so replacing the argument
parser is a change to `command_line.cpp` and to
`cmake/modules/CommandLineDependencies.cmake`.

To add a feature: `src/thing.hpp` for the declarations, `src/thing.cpp` for the
code, `test/thing_test.cpp` for the tests, and add the source to
`add_library(mycli_lib ...)` and the test to `add_executable(mycli_test ...)`.

## What is wired in

- **Warnings** per compiler, applied per target so fetched dependencies are not
  affected. `-Werror` is on in the `debug` preset; turn it off with
  `-DCPPBP_WARNINGS_AS_ERRORS=OFF`.
- **Sanitizers** for address, undefined behaviour, threads and memory.
  Combinations that cannot work together fail configuration rather than quietly
  checking less than you expect.
- **clang-tidy** in the compile step, so a violation fails the build the same
  way a compile error does.
- **CLI11**, fetched rather than vendored.
- **GoogleTest**, the same.
- **A test that runs the program.** `mycli.runs` starts the built executable,
  feeds it a file, and checks the output and the exit status - including that a
  missing file is an error rather than a zero. The unit tests say the pieces
  work; this one says they were wired together.
- **An installed program**: `cmake --install` puts one binary in `bin/`. No
  export set, no config file: nothing finds a command with `find_package`.
- **Workflows**: `pr-check` and `main-check` run the matrix, the pinned build
  and the static analysis; `nightly-sanitizer` runs the address and thread
  builds overnight; `release` turns a `vX.Y.Z` tag into a GitHub release;
  `dependency-freshness` opens one issue, weekly, when a pin this started with
  falls behind - the ones Dependabot cannot see, because it does not read
  `FetchContent` tags or apt versions inside a `RUN` layer.
- **A pinned environment** in `.devcontainer/`, the same one CI builds against,
  so a green build means the code changed rather than the machine.

There is no SBOM here, unlike the library template. `install(SBOM)` refuses to
describe a target that links one it cannot attribute, and a dependency fetched
with `FetchContent` is never installed or exported, so CLI11 cannot be
attributed. The feature is experimental and this is worth trying again later;
exporting a dependency nobody consumes to satisfy it is not.

## Documents

- [docs/coding-style.md](docs/coding-style.md) - what `.clang-format` and
  `.clang-tidy` are set to, and why every disabled check is disabled. The list
  is enforced: `scripts/check-tidy-rationale.sh` fails the build if a check is
  switched off without a reason written down.
- [docs/versioning.md](docs/versioning.md) - semantic versioning, what a break
  means, and how a release happens.

## Releasing

```sh
./scripts/release.sh v0.2.0   # refuses a tag that disagrees with project(VERSION)
git push origin v0.2.0        # this push is the release
```

## Standard

C++23, set per target with `target_compile_features`. Change one line in
`CMakeLists.txt` to move it.

Note that a standard is not a single thing: GCC 13, which Ubuntu 24.04 ships,
implements most of C++23 but not `<print>`. The CI matrix includes it, so a
feature your compilers do not have yet fails there rather than reaching a user.
`std::expected`, which `command_line::parse` returns, is there in all of them.

## Contributing

To this repository: please don't. It is assembled from
[cpp-boilerplate](https://github.com/skipbit/cpp-boilerplate) and republished,
so anything committed here is overwritten. Issues and pull requests belong
there.

To your own copy, once you have used the template: it is yours, and none of
this applies.

## License

0BSD. Use it, change it, ship it; no attribution required. Replace this file and
`LICENSE` with your own once it is your project.
