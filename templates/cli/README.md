# mycli

![C++23](https://img.shields.io/badge/C%2B%2B-23-blue.svg)
![CMake 3.28+](https://img.shields.io/badge/CMake-3.28%2B-blue.svg)
![License 0BSD](https://img.shields.io/badge/license-0BSD-blue.svg)

A C++ command line program that builds, tests and installs itself from the first
commit. Rename it and start writing.

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

Presets: `debug` (warnings as errors), `release`, `asan`, `tsan`, `tidy`,
`clang-libc++` (clang against libc++, which needs `libc++-dev` and
`libc++abi-dev`).

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
name the program prints in its own messages, and the homepage in `project()`.
The homepage comes from the `origin` remote, or from `--url`
(`./scripts/rename.sh yourtool --url https://github.com/you/yourtool`); with
neither, the line is deleted rather than left pointing at the template.

`--author "Your Name"` rewrites the copyright line in `LICENSE`, and the year
with it. It is never taken from your git configuration: a name written there by
mistake is harder to notice than the template author's still being there, and
0BSD asks for no attribution either way.

The second points git at `.githooks/`, which runs clang-format, clang-tidy,
actionlint, hadolint and shellcheck on the files in a commit; anything not installed is
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
| `command_line` | turns `argv` into an `Outcome` | CLI11, and nothing else does |
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

The rows are not a fixed list. `pr-check` and `main-check` ask this project what
it can be built with and build the rows it answers with, so a configuration the
project refuses in `CMakeLists.txt` gets no check at all - rather than a check
that builds nothing and reports success. Worth knowing before you name a row in
GitHub's required status checks: that name disappears the day the project
refuses the configuration, and a required check nothing reports waits forever.
The job named "what this project can be built with" lists every row in its
summary, and which of them were built.

A job named "what BUILD_SHARED_LIBS=ON builds and installs" runs on every pull
request, and here it installs no shared library at all: `mycli_lib` says
`STATIC`, so the flag does not reach it, and the prefix gets the one binary.
It prints the number of libraries it read, zero included, rather than letting
a green tick stand for a count nobody has seen. What it checks here is that
the flag changes nothing: configure, build, test and install still pass with
it on, and the installed program asks the loader for nothing it cannot find.
If that is not a claim worth keeping, deleting the job is a reasonable
answer - nothing else in the workflow depends on it.

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
- [docs/standard-library.md](docs/standard-library.md) - which environments are
  supported, what their standard libraries actually provide, and how to depend
  on something outside what all of them have.
- [docs/toolchain.md](docs/toolchain.md) - what the pinned image fixes and what
  it deliberately does not, why apt packages are installed without a version,
  and the one hadolint rule that is switched off because of it.
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

A standard is not one thing, and not one thing per compiler either: it is a
compiler and a standard library, and the two disagree. On Ubuntu 24.04, GCC 13
has `std::expected` and no `<print>`; clang 18 has neither against the
libstdc++ it picks up by default, and both against libc++ - the same compiler,
a different answer. Configuration prints what the toolchain in front of you
actually has, and the code here stays inside what every environment in the
matrix provides, so `cmake --preset tidy` works on a stock machine.

To use something outside that set, ask for it in `CMakeLists.txt`, by the
feature test macro the standard gives it:

```cmake
cppbp_require_std_feature(__cpp_lib_expected 202202)
```

Configuration then stops on the environments that do not have it, naming the
environment and the way out, instead of failing later in a compile log or in
somebody else's clone. Any feature test macro works; there is no list here to
be on. [docs/standard-library.md](docs/standard-library.md) has what the
environments in the matrix actually provide, measured.

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
