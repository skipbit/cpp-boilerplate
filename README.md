# cpp-boilerplate

Starting points for C++ projects, so that the first day is spent on the problem
rather than on CMake.

Each template builds, tests, installs and packages itself from the first commit.
Warnings, sanitizers, static analysis and a test framework are already wired in,
and the structure is meant to be kept: public headers declare, `src/` implements,
one feature means one header, one implementation and one test.

## Which one do I want?

| template | for | status |
| --- | --- | --- |
| `lib` | a library other code links against | ready |
| `cli` | a command line tool | planned |
| `daemon` | a long-running process | planned |
| `qt` | a Qt desktop application | planned |

Each template is also published as its own repository, so that GitHub's
**Use this template** button gives you that one and nothing else. This
repository is where they are developed: the shared CMake modules, the linting
configuration and the CI live here once instead of four times.

## Quick start

```sh
git clone https://github.com/skipbit/cpp-boilerplate
cd cpp-boilerplate
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
```

Nothing else has to be installed first: CMake, a compiler and Ninja are enough,
and the test framework is fetched during configuration.

Presets: `debug` (warnings as errors), `release`, `asan`, `tsan`, `tidy`.

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
Ubuntu 24.04 is in the matrix, so anything its GCC 13 does not implement yet
(`std::print`, for one) fails there rather than reaching you later.

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

## Repository layout

```
cmake/modules/     shared CMake modules, used by every template
templates/lib/     the library template
.devcontainer/     the pinned toolchain, used by CI and the dev container
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

## Adding a template

A template is a directory under `templates/` that builds on its own:

1. `templates/<name>/CMakeLists.txt` with its own `project()` call, so the
   published repository builds without a parent.
2. `ln -s ../../../cmake/modules templates/<name>/cmake/modules`, so it uses
   the shared modules rather than a copy of them.
3. An `option()` and an `add_subdirectory()` in the top-level `CMakeLists.txt`.
4. If it needs system libraries, `templates/<name>/.devcontainer/Dockerfile`
   building `FROM` the shared toolchain image. The environment then travels
   with the template when it is published.

Application templates consume the library template through `find_package`
rather than linking it directly in the same build tree. That is deliberate: it
is the only arrangement in which a broken install rule fails a build.

## Contributing

Issues and pull requests belong here, in this repository. The per-template
repositories are generated from this one, so changes made there are overwritten
the next time they are published.

## License

0BSD. Use it, change it, ship it; no attribution required. The point of a
template is that it becomes your code, and carrying someone else's copyright
notice into your project is friction rather than credit.
