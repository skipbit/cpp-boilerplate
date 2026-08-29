# mylib

![C++23](https://img.shields.io/badge/C%2B%2B-23-blue.svg)
![CMake 3.28+](https://img.shields.io/badge/CMake-3.28%2B-blue.svg)
![License 0BSD](https://img.shields.io/badge/license-0BSD-blue.svg)

A C++ library that builds, tests, installs and packages itself from the first
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

CMake, a compiler and Ninja are enough; the test framework is fetched during
configuration.

Presets: `debug` (warnings as errors), `release`, `asan`, `tsan`, `tidy`,
`clang-libc++` (clang against libc++, which needs `libc++-dev` and
`libc++abi-dev`).

## Make it yours

Everything is called `mylib`. Rename it:

```sh
./scripts/rename.sh yourlib
./scripts/install-hooks.sh
```

The first covers the namespace, the target, the installed package, the
generated headers and the homepage in `project()`. Not `.clang-tidy`: its rules
are about case, so there is no name in it to change. The homepage comes from the
`origin` remote, or from `--url`
(`./scripts/rename.sh yourlib --url https://github.com/you/yourlib`); with
neither, the line is deleted rather than left pointing at the template, because
CMake writes it into the installed SBOM.

`--author "Your Name"` rewrites the copyright line in `LICENSE`, and the year
with it. It is never taken from your git configuration: a name written there by
mistake is harder to notice than the template author's still being there, and
0BSD asks for no attribution either way.

The second points git at `.githooks/`, which runs clang-format, clang-tidy,
actionlint, hadolint and shellcheck on the files in a commit; anything not installed is
skipped rather than treated as a failure. The dev container runs it for you.

## How it is laid out

```
include/mylib/     public headers - declarations only
src/               implementation, plus headers nobody else can include
test/              unit tests, and a check that the installed package works
examples/          programs a reader can run
cmake/             package config, pkg-config and version templates
docs/              why the configuration is what it is
.devcontainer/     the pinned toolchain, used by CI and the dev container
.githooks/         the checks that run before a commit
```

**One feature is one header, one implementation and one test.** There is no
umbrella `<mylib/mylib.hpp>`: a header that pulls in everything becomes a header
that everything depends on.

**Public headers declare; `src/` implements.** Anything under `src/` is never
installed, so changing it is never a breaking change for anyone.

To add a feature: `include/mylib/thing.hpp` for the declarations, `src/thing.cpp`
for the code, `test/thing_test.cpp` for the tests, and add the header and source
to `target_sources` in `CMakeLists.txt`.

## What is wired in

- **Warnings** per compiler, applied per target so fetched dependencies are not
  affected. `-Werror` is on in the `debug` preset; turn it off with
  `-DCPPBP_WARNINGS_AS_ERRORS=OFF`.
- **Sanitizers** for address, undefined behaviour, threads and memory.
  Combinations that cannot work together fail configuration rather than quietly
  checking less than you expect.
- **clang-tidy** in the compile step, so a violation fails the build the same
  way a compile error does.
- **GoogleTest**, fetched rather than vendored.
- **An installable package**: an export set, a config file, a version file and
  a `pkg-config` file, so consumers can `find_package(mylib)` and link
  `mylib::mylib`.
- **A test that consumes the installed package.** `mylib.install-consume`
  installs into a scratch prefix and builds a separate project against it. A
  library that passes its own tests can still be impossible to use; this is the
  check that notices.
- **An SBOM** in SPDX 3.0.1, off by default (`-DMYLIB_GENERATE_SBOM=ON`, needs
  CMake 4.3+, experimental).
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

A job named "what BUILD_SHARED_LIBS=ON builds and installs" is the only one
that builds `mylib` as a shared library; every other build here leaves it
static, which is what `BUILD_SHARED_LIBS` defaults to. The export header, the
hidden visibility and `SOVERSION` do nothing in a static build, so forgetting
the export macro on a new public function - the ordinary mistake in a library
written this way - passes every other check and fails this one. Green means
that it configured, built, tested and installed with `BUILD_SHARED_LIBS=ON`,
that every shared library it installed carries a versioned SONAME, and that
nothing installed asks the loader for a library that is not there. Installing
nothing is a failure, and it prints how many libraries it read: a check whose
subject is missing looks like one that found nothing wrong.

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
- [docs/versioning.md](docs/versioning.md) - semantic versioning against the API
  and the ABI, what breaks a C++ library, and how a release happens.

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

For a library there is a second rule on top of that one: **a public header may
only name what every supported environment has.** What a header requires
travels to whoever includes it, and their standard library is not yours to
choose - `target_compile_features(mylib PUBLIC cxx_std_23)` asks a consumer for
a standard, and a standard is exactly what does not settle this. Inside `src/`,
which nobody installs, ask for what you like, by the feature test macro the
standard gives it:

```cmake
cppbp_require_std_feature(__cpp_lib_expected 202202)
```

Configuration then stops on the environments that do not have it, naming the
environment and the way out. Any feature test macro works; there is no list
here to be on. [docs/standard-library.md](docs/standard-library.md) has what
the environments in the matrix actually provide, measured.

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
