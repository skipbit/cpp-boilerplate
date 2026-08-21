# myapp

![C++23](https://img.shields.io/badge/C%2B%2B-23-blue.svg)
![CMake 3.28+](https://img.shields.io/badge/CMake-3.28%2B-blue.svg)
![Qt 6](https://img.shields.io/badge/Qt-6-blue.svg)
![License 0BSD](https://img.shields.io/badge/license-0BSD-blue.svg)

A C++ desktop application that builds, tests and installs itself from the first
commit - and whose tests run with no screen attached. Rename it and start
writing.

Generated from [cpp-boilerplate](https://github.com/skipbit/cpp-boilerplate),
where the template itself is developed and where issues about it belong.

There is no build badge here on purpose. **Use this template** copies this file
into your repository unchanged, and a workflow badge names the repository it
belongs to - so it would sit at the top of your README reporting somebody
else's build, green whatever yours does. The four above describe the code, and
stay true after the copy. Add your own once you have a repository:

```
[![main check](https://github.com/YOU/YOURS/actions/workflows/main-check.yml/badge.svg)](https://github.com/YOU/YOURS/actions/workflows/main-check.yml)
```

## Start

You need Qt's development package. On Ubuntu and Debian:

```sh
sudo apt install qt6-base-dev
```

Then:

```sh
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
./build/debug/myapp
```

Presets: `debug` (warnings as errors), `release`, `asan`, `tsan`, `tidy`. CMake,
a compiler, Ninja and Qt are enough; the test framework is fetched during
configuration.

## It supports four environments, not six

The other templates here are built and tested against clang with libc++ as well
as with libstdc++. **This one cannot be, and refuses to try.**

The Qt a distribution ships is built against libstdc++, and some of its
functions take or return a standard library type. Those are exported by the
shared library under a mangled name containing the standard library they were
built with, so an application compiled against libc++ asks the linker for a
symbol that is not there. Measured:

| | Ubuntu 24.04, Qt 6.4.2 | Ubuntu 26.04, Qt 6.10.2 |
| --- | --- | --- |
| widgets alone | links | links |
| `QString::fromStdString` | links | links |
| `QString::toStdString` | **fails** | **fails** |
| `QTimer::singleShot(std::chrono)` | links | **fails** |

```
undefined reference to `QString::toStdString() const'
undefined reference to `QTimer::singleShotImpl(std::__1::chrono::duration<...>)'
```

`std::__1` is libc++'s inline namespace. Qt's symbol is there under libstdc++'s
name and nothing rewrites it.

**There is no safe subset to keep to.** What fails is not "the API that crosses
the boundary" - `fromStdString` crosses it and links, because it is defined
inline in the header and needs no symbol at all. What fails is whatever your Qt
happens to define out of line, and that changes between releases: the fourth row
above links on 6.4.2 and fails on 6.10.2.

So configuring with libc++ stops, with the reason and the way out, instead of
producing a link error a hundred lines into a build. `CMakePresets.json` has no
`clang-libc++` preset here, and the CI matrix builds this template on four of
its six rows. That is a smaller claim than the other templates make, and it is
made where it can be read rather than discovered.

## Make it yours

Everything is called `myapp`. Rename it:

```sh
./scripts/rename.sh yourapp
./scripts/install-hooks.sh
```

The first covers the namespace, all three targets, the generated version header,
the window title, the homepage in `project()`, and the desktop entry - its file
name as well as what is inside it. The homepage comes from the `origin` remote,
or from `--url`; with neither, the line is deleted rather than left pointing at
the template.

`--author "Your Name"` rewrites the copyright line in `LICENSE`, and the year
with it. It is never taken from your git configuration: a name written there by
mistake is harder to notice than the template author's still being there, and
0BSD asks for no attribution either way.

The second points git at `.githooks/`, which runs clang-format, clang-tidy,
actionlint and shellcheck on the files in a commit; anything not installed is
skipped rather than treated as a failure. The dev container runs it for you.

Then replace what it shows. `catalogue` holds a list of the tools this template
uses, which is an example of the shape rather than a feature.

## How it is laid out

```
src/               everything, because nothing here is installed as a header
test/              one test file per source file, plus one that runs the program
desktop/           the desktop entry, with the name and path filled in by CMake
cmake/             the generated version header's template
docs/              why the configuration is what it is
.devcontainer/     the pinned toolchain and Qt, used by CI and the dev container
.githooks/         the checks that run before a commit
```

**`main()` creates nothing.** No window, no layout, not even the
`QApplication` - it calls one function and returns what it answers. That is not
ceremony: everything that would otherwise be written in `main()` is then in a
function, and a function can be called by a test while `main()` cannot.

**The logic is not in the widget, and the build says so.** There are two
libraries:

| target | holds | links |
| --- | --- | --- |
| `myapp_model` | `catalogue`, `presentation` | nothing from Qt |
| `myapp_ui` | `window`, `startup` | `myapp_model`, `Qt6::Widgets` |

`myapp_model` is not linked against Qt, so a `QString` in the model is a compile
error rather than a review comment - it stops at `fatal error: QString: No such
file or directory`. Its tests link that library and nothing else, construct no
`QApplication`, and would keep passing if every widget here were deleted.

That enforces one direction of the rule: the model cannot reach for a widget.
The other direction - a window that quietly works out for itself what the model
already answers - no arrangement can catch, and this one is not claiming to.
What makes it easy to see instead is that `Window` is short: every question it
asks goes to a function somewhere else, so a new one appearing inline is
visible in a way it would not be in a class that already does its own work.

| unit | does | knows about |
| --- | --- | --- |
| `catalogue` | holds the entries, and answers which ones match | nothing |
| `presentation` | turns a result into the strings that get shown | `catalogue` |
| `window` | builds the widgets and wires the one that changes | all of the above, and Qt |
| `startup` | assembles the program and runs it | `window`, `catalogue`, Qt |

`Window` decides nothing. It reads the query, asks `catalogue` what matches,
asks `presentation` how to say it, and puts the answer in widgets. Every
question it asks is answered by a function with a test next to it.

To add a feature: `src/thing.hpp`, `src/thing.cpp`, `test/thing_test.cpp`, and
add the source to whichever library it belongs to - which is a question worth
asking each time, because the answer is usually `myapp_model`.

## `new` without `delete`

`window.cpp` creates its widgets with `new` and never deletes them. That is
correct Qt, not a leak: a `QObject` given a parent is destroyed by that parent,
and the layout and widgets here are all given `this`. Holding them in a
`unique_ptr` as well would be a double free rather than an improvement.

The address sanitizer preset runs the widget tests, so this is checked rather
than asserted.

## Testing a program with a window

```sh
ctest --preset debug
```

There are three kinds of test here, and the split is deliberate.

- **`catalogue_test` and `presentation_test`** link `myapp_model`. No
  `QApplication`, no widgets, no display. They are ordinary function calls.
- **`window_test`** builds real widgets. It brings its own `main()`, because a
  `QWidget` needs a `QApplication` to exist first, and it sets
  `QT_QPA_PLATFORM=offscreen` before creating one - so it runs where there is no
  display, and puts no windows on one where there is.
- **`myapp.starts`** runs the built program with `--self-check`, which draws
  once and quits. It is the only thing here that goes through `main()`.

`--self-check` exists for that test. A program that can only be checked by a
person watching it is a program that stops being checked.

## Installing

```sh
cmake --install build/debug --prefix ~/.local
```

Two things land: the binary in `bin/`, and a desktop entry in
`share/applications/` so that a launcher can find it. The entry is generated,
because it names the program and the absolute path it was installed to; that
path is fixed when you configure, so installing to a different prefix means
configuring again rather than editing the installed copy.

## What is wired in

- **Warnings** per compiler, applied per target so Qt's own headers are not
  judged by them. `-Werror` is on in the `debug` preset; turn it off with
  `-DCPPBP_WARNINGS_AS_ERRORS=OFF`.
- **Sanitizers** for address, undefined behaviour, threads and memory.
  Combinations that cannot work together fail configuration rather than quietly
  checking less than you expect.
- **clang-tidy** in the compile step, so a violation fails the build the same
  way a compile error does. Qt's generated `moc` sources are not analysed -
  CMake excludes what it generates, so a finding here is always about a file you
  wrote.
- **GoogleTest**, fetched rather than vendored. Not QTest: the tests that matter
  most here are the ones with no Qt in them.
- **A pinned environment** in `.devcontainer/`, the same one CI builds against,
  with Qt in it and the X11 socket passed through so a window opened inside the
  container appears on your screen.
- **Workflows**: `pr-check` and `main-check` run the matrix, the pinned build
  and the static analysis; `nightly-sanitizer` runs the address and thread
  builds overnight; `release` turns a `vX.Y.Z` tag into a GitHub release;
  `dependency-freshness` opens one issue, weekly, when a pin this started with
  falls behind.

There is no SBOM here, for the reason the command line and service templates
have none. `install(SBOM)` refuses a target that references one it cannot
attribute, and this program links two static libraries that exist for its tests
and are never installed. Measured with CMake 4.4.2:

```
Target "myapp" references target "myapp_ui" which has no
install(EXPORT)/export(EXPORT) namespace and is not covered by any SBOM.
```

Whether Qt itself could be described is a question that is never reached.

## Documents

- [docs/coding-style.md](docs/coding-style.md) - what `.clang-format` and
  `.clang-tidy` are set to, and why every disabled check is disabled. The list
  is enforced: `scripts/check-tidy-rationale.sh` fails the build if a check is
  switched off without a reason written down.
- [docs/standard-library.md](docs/standard-library.md) - which environments are
  supported, what their standard libraries actually provide, and how to depend
  on something outside what all of them have. Read it with the section above in
  mind: this template supports the four rows without libc++ in them.
- [docs/versioning.md](docs/versioning.md) - semantic versioning, what a break
  means, and how a release happens.

## Releasing

```sh
./scripts/release.sh v0.2.0   # refuses a tag that disagrees with project(VERSION)
git push origin v0.2.0        # this push is the release
```

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
