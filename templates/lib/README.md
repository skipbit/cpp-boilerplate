# mylib

A C++ library that builds, tests, installs and packages itself from the first
commit. Rename it and start writing.

Generated from [cpp-boilerplate](https://github.com/skipbit/cpp-boilerplate).

## Start

```sh
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
```

CMake, a compiler and Ninja are enough; the test framework is fetched during
configuration.

Presets: `debug` (warnings as errors), `release`, `asan`, `tsan`, `tidy`.

## Make it yours

Everything is called `mylib`. Rename it:

```sh
./scripts/rename.sh yourlib
```

That covers the namespace, the target, the installed package, the generated
headers and the naming rule in `.clang-tidy`.

## How it is laid out

```
include/mylib/     public headers - declarations only
src/               implementation, plus headers nobody else can include
test/              unit tests, and a check that the installed package works
examples/          programs a reader can run
cmake/             package config, pkg-config and version templates
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
  CMake 4.3+).

## Standard

C++23, set per target with `target_compile_features`. Change one line in
`CMakeLists.txt` to move it.

Note that a standard is not a single thing: GCC 13, which Ubuntu 24.04 ships,
implements most of C++23 but not `<print>`. The CI matrix includes it, so a
feature your compilers do not have yet fails there rather than reaching a user.

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
