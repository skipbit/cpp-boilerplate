# cpp-boilerplate

[![main check](https://github.com/skipbit/cpp-boilerplate/actions/workflows/main-check.yml/badge.svg)](https://github.com/skipbit/cpp-boilerplate/actions/workflows/main-check.yml)
[![nightly sanitizer](https://github.com/skipbit/cpp-boilerplate/actions/workflows/nightly-sanitizer.yml/badge.svg)](https://github.com/skipbit/cpp-boilerplate/actions/workflows/nightly-sanitizer.yml)
![C++23](https://img.shields.io/badge/C%2B%2B-23-blue.svg)
![CMake 3.28+](https://img.shields.io/badge/CMake-3.28%2B-blue.svg)
![License 0BSD](https://img.shields.io/badge/license-0BSD-blue.svg)

Starting points for C++ projects, so that the first day is spent on the problem
rather than on CMake.

Each template builds, tests and installs itself from the first commit, and the
library one packages itself as well.
Warnings, sanitizers, static analysis and a test framework are already wired in,
and the structure is meant to be kept: public headers declare, `src/` implements,
one feature means one header, one implementation and one test.

## Which one do I want?

| template | for | repository |
| --- | --- | --- |
| `lib` | a library other code links against | [skipbit/cpp-boilerplate-lib](https://github.com/skipbit/cpp-boilerplate-lib) |
| `cli` | a command line tool | [skipbit/cpp-boilerplate-cli](https://github.com/skipbit/cpp-boilerplate-cli) |
| `daemon` | a long-running process | planned |
| `qt` | a Qt desktop application | planned |

Each template is also published as its own repository, so that GitHub's
**Use this template** button gives you that one and nothing else. This
repository is where they are developed: the shared CMake modules, the linting
configuration and the CI live here once instead of four times.

## Start

Press **Use this template** on the repository for the one you want - the table
above links them. Then:

```sh
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
```

Nothing else has to be installed first: CMake, a compiler and Ninja are enough,
and the test framework is fetched during configuration.

Presets: `debug` (warnings as errors), `release`, `asan`, `tsan`, `tidy`.

To build this repository instead - every template at once, which is what the CI
does - see [CONTRIBUTING.md](CONTRIBUTING.md).

## What is wired in

- **Warnings** per compiler, applied per target so fetched dependencies are not
  affected. `-Werror` is a switch, not a decision made for you.
- **Sanitizers** for address, undefined behaviour, threads and memory.
  Combinations that cannot work together fail configuration instead of quietly
  checking less than you think.
- **clang-tidy** in the compile step, so a violation fails the build the same
  way a compile error does.
- **GoogleTest**, fetched rather than vendored.
- **An installable package**: an export set, a config file, a version file and
  a `pkg-config` file. A test installs the library into a scratch prefix and
  builds a separate project against it with `find_package`, because a library
  that passes its own tests can still be impossible to consume.
- **An SBOM** in SPDX 3.0.1, off by default. See below.
- **Hooks** that run clang-format, clang-tidy, actionlint and shellcheck on the
  files in a commit: `./scripts/install-hooks.sh`. Anything not installed is
  skipped rather than treated as a failure.
- **A release path**: a `vX.Y.Z` tag builds, tests, and publishes a GitHub
  release. `scripts/release.sh` refuses to make a tag that disagrees with
  `project(VERSION)`.

## Supported environments

Verified in CI on every change:

| | compilers | standard library |
| --- | --- | --- |
| Ubuntu 24.04 LTS | GCC 13, Clang 18 | libstdc++, libc++ |
| Ubuntu 26.04 LTS | GCC 15, Clang 21 | libstdc++, libc++ |

The stock toolchains are used deliberately: if it needs a compiler you do not
have yet, it is not a starting point.

A second set of jobs builds in a pinned image
(`.devcontainer/Dockerfile`, CMake 4.4 and Clang 21), so that a green build
means the code changed rather than the environment. The dev container uses the
same image.

The language standard is C++23, set per target with `target_compile_features`.
Which is less than it sounds: a standard is a compiler and a standard library,
and on Ubuntu 24.04 they disagree. GCC 13 has `std::expected` and no `<print>`;
clang 18 has neither against the libstdc++ it picks up by default, and both
against libc++. Nor is one library simply ahead: libc++ has `mdspan` and no
`stacktrace`, libstdc++ the reverse, on both releases. That is why the table
above has a standard library column, and why the matrix runs six combinations
rather than four.

The templates stay inside what all six provide, and
`cppbp_require_std_feature(__cpp_lib_expected 202202)` is how code that
replaces them says it needs more: configuration stops where the feature is
absent rather than the build failing later somewhere else. See
[docs/standard-library.md](docs/standard-library.md), which has the
measurements.

## SBOM

`install(SBOM)` writes an SPDX 3.0.1 document describing the installed targets:

```sh
cmake -S . -B build -DMYLIB_GENERATE_SBOM=ON
cmake --build build
cmake --install build --prefix /tmp/prefix
# /tmp/prefix/lib/sbom/mylib/mylib.spdx.json
```

It is off by default because it needs CMake 4.3 or newer, which no current
Ubuntu LTS ships, and because the feature is still experimental: the key that
unlocks it can change between CMake releases. CI exercises this path on every
change, so a changed key shows up as a failing job rather than a document that
silently stopped being written.

## Documents

- [docs/coding-style.md](docs/coding-style.md) - what `.clang-format` and
  `.clang-tidy` are set to, and **why every disabled check is disabled**. That
  list is checked: `scripts/check-tidy-rationale.sh` fails the build if a check
  is switched off without a reason written down.
- [docs/standard-library.md](docs/standard-library.md) - which environments are
  supported, what their standard libraries actually provide, and how to depend
  on something outside what all of them have.
- [docs/versioning.md](docs/versioning.md) - semantic versioning against the API
  and the ABI, what breaks a C++ library, and how a release happens.

## Repository layout

```
cmake/modules/     shared CMake modules, used by every template
ci/                the workflows every published template gets
docs/              the reasoning behind the configuration
templates/lib/     the library template
templates/cli/     the command line template
.devcontainer/     the pinned toolchain, used by CI and the dev container
.githooks/         the checks that run before a commit
```

`templates/*/cmake/modules` is a symlink to `cmake/modules`. The monorepo keeps
one copy; the published templates get a real directory in the same place, so
their `CMakeLists.txt` needs no changes either way.

## How dependencies are pinned

Three kinds, three places. Putting them all in one file would mean every
template shares a cache and a diff with every other one.

| kind | examples | where it lives | kept current by |
| --- | --- | --- | --- |
| toolchain | CMake, GCC, Clang, ninja | `.devcontainer/Dockerfile` | `dependency-freshness`, weekly |
| system libraries | Qt, OpenGL | `templates/<name>/.devcontainer/` | the template that needs them |
| source dependencies | GoogleTest, CLI11 | `FetchContent` in `cmake/modules/` | `dependency-freshness`, weekly |
| actions, base images | `actions/checkout`, `ubuntu:24.04` | workflows, `FROM` lines | Dependabot |

Dependabot reads the last row and nothing else: it does not know what a
`FetchContent` tag is, and it cannot see a version pinned inside a `RUN` layer.
The `dependency-freshness` job covers the rest by asking the upstream
repositories directly and opening a single, updated issue when something is
behind.

## Contributing

Issues and pull requests belong here, in this repository: the per-template
repositories are generated from this one, so anything committed there is
overwritten the next time they are published.

[CONTRIBUTING.md](CONTRIBUTING.md) has the rest - how to build the whole
repository, what runs before a commit, and how a template is added and
published.

## License

0BSD. Use it, change it, ship it; no attribution required. The point of a
template is that it becomes your code, and carrying someone else's copyright
notice into your project is friction rather than credit.
