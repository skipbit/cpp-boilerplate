# myapp

![C++23](https://img.shields.io/badge/C%2B%2B-23-blue.svg)
![CMake 3.28+](https://img.shields.io/badge/CMake-3.28%2B-blue.svg)
![Qt 6](https://img.shields.io/badge/Qt-6-blue.svg)
![License 0BSD](https://img.shields.io/badge/license-0BSD-blue.svg)

A C++ desktop application - Qt Quick, with the interface in QML - that builds,
tests and installs itself from the first commit, and whose tests run with no
screen attached. Rename it and start writing.

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

You need Qt's development packages, and the QML modules the interface imports.
On Ubuntu and Debian:

```sh
sudo apt install qt6-base-dev qt6-declarative-dev \
  qml6-module-qtqml qml6-module-qtqml-models qml6-module-qtqml-workerscript \
  qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
  qml6-module-qtquick-templates qml6-module-qtquick-window
```

The `qml6-module-*` half is not optional and is not pulled in for you on 24.04:
they are loaded at run time, so without them this builds, links, and then exits
with `module "QtQuick" is not installed`.

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
| an engine and a window, alone | links | links |
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
`clang-libc++` preset here, and the CI matrix has four rows where the other
templates have six: the two libc++ rows are left out rather than run and
reported green having built nothing. That is a smaller claim than the other
templates make, and it is made where it can be read rather than discovered.

## Make it yours

Everything is called `myapp`. Rename it:

```sh
./scripts/rename.sh yourapp
./scripts/install-hooks.sh
```

The first covers the namespace, the targets, the generated version header, the
QML module's URI and the `import` that names it, the window title, the homepage
in `project()`, and the desktop entry - its file name as well as what is inside
it. The homepage comes from the `origin` remote,
or from `--url`; with neither, the line is deleted rather than left pointing at
the template.

`--author "Your Name"` rewrites the copyright line in `LICENSE`, and the year
with it. It is never taken from your git configuration: a name written there by
mistake is harder to notice than the template author's still being there, and
0BSD asks for no attribution either way.

The second points git at `.githooks/`, which runs clang-format, clang-tidy,
actionlint, hadolint and shellcheck on the files in a commit; anything not installed is
skipped rather than treated as a failure. The dev container runs it for you.

Then replace what it shows. `catalogue` holds a list of the tools this template
uses, which is an example of the shape rather than a feature.

## How it is laid out

```
src/               the C++: what the program knows, and the one class QML binds to
qml/               the interface
test/              one test file per layer, plus one that runs the program
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

**The logic is not in the interface, and the build says so.** There are three
layers and two libraries:

| target | holds | links |
| --- | --- | --- |
| `myapp_core` | `catalogue`, `presentation` | nothing from Qt |
| `myapp_bridge` | `filtered_entries`, `startup` | `myapp_core`, `Qt6::Quick` |
| `myapp_ui` | `qml/Main.qml`, and what Qt generates from it | `myapp_bridge` |

`myapp_core` is not linked against Qt, so a `QString` in it is a compile error
rather than a review comment - it stops at `fatal error: QString: No such file
or directory`. Its tests link that library and nothing else, construct no
application object, and would keep passing if the whole interface were deleted.

`myapp_ui` is separate from `myapp_bridge` for a duller reason that turned out
to matter: a QML module target is also where Qt puts the code it generates, and
a target holding only generated code can be exempted from the warnings and the
static analysis as a whole. Mixing the two would mean choosing between judging
Qt's output and not judging yours.

That enforces one direction of the rule: what the program knows cannot reach for
the interface. The other direction - a view that quietly works out for itself
what the model already answers - no arrangement can catch. What makes it easy to
see instead is that neither `FilteredEntries` nor `Main.qml` has anywhere to put
a decision: one forwards, the other binds.

| layer | does | knows about |
| --- | --- | --- |
| `catalogue` | holds the entries, and answers which ones match | nothing |
| `presentation` | turns a result into the strings that get shown | `catalogue` |
| `filtered_entries` | offers both to QML as a property and a model | all of the above, and Qt |
| `qml/Main.qml` | says what the window looks like | `filtered_entries` |
| `startup` | assembles the program and runs it | Qt |

`FilteredEntries` answers no questions of its own. The query goes to
`catalogue`, the strings come from `presentation`, and what is left is turning
their answers into the shape a view expects. `Main.qml` contains no rule at all:
a binding is the whole wiring, and nothing in it is told when to update.

Its methods are named the way the rest of this project names things - `set_query`,
not `setQuery` - because `.clang-tidy` checks one of those conventions and
nothing checks the other. QML does not care: it binds to the property, and the
property is called `query` either way.

To add a feature: `src/thing.hpp`, `src/thing.cpp`, `test/thing_test.cpp`, and
add the source to whichever library it belongs to - which is a question worth
asking each time, because the answer is usually `myapp_core`.

## Who owns the model

`FilteredEntries` is created in `Main.qml`, not in C++:

```qml
FilteredEntries {
    id: entries
}
```

It is registered with `QML_ELEMENT`, which is why `import myapp` is enough to
name it, and the QML engine owns every object it instantiates. So nothing in
`startup.cpp` creates one and nothing deletes one - and if you find yourself
passing a C++-owned `QObject*` into QML later, that is the moment to read what
Qt says about ownership, because the answer stops being automatic.

## Testing a program with an interface

```sh
ctest --preset debug
```

Four kinds of test, and the split is the design rather than an accident.

- **`myapp_core_test`** links `myapp_core`. No Qt, no application object, no
  display. Ordinary function calls.
- **`myapp_bridge_test`** exercises `FilteredEntries` directly. It links Qt and
  still needs no application object, which is the measurement that says the
  class is a forwarder rather than a place where things happen.
- **`myapp_interface_test`** loads `Main.qml` and drives it: it types into the
  field and reads the labels, so what it checks is the bindings. It brings its
  own `main()`, because the engine needs a `QGuiApplication` first, and it sets
  `QT_QPA_PLATFORM=offscreen` before creating one - so it runs where there is no
  display, and puts no windows on one where there is.
- **`myapp.qmllint`** is to QML what clang-tidy is to the C++, and nothing else
  here reads the `.qml` files at all: to the compiler they are bytes in a
  resource. It caught an unqualified property access in this file's first
  version.
- **`myapp.starts`** runs the built program with `--self-check`, which loads the
  interface, draws once and quits. It is the only thing here that goes through
  `main()`.

`--self-check` exists for that test. A program that can only be checked by a
person watching it is a program that stops being checked.

## What Qt 6.4 cannot do

Ubuntu 24.04 ships Qt 6.4, which is the floor this template builds on, and two
things follow from it.

`startup.cpp` loads the interface by URL rather than with
`QQmlApplicationEngine::loadFromModule`, which arrived in 6.5. The URL form
works on every version and is one line longer.

`myapp.qmllint` does not run on 6.4: its qmllint cannot resolve a C++ type
registered with `QML_ELEMENT`, and reports `FilteredEntries` as unresolved.
Running it anyway would mean either ignoring its answer or writing the QML
around a tool's blind spot, so configuration says which it is and skips it. On
6.5 and newer - including the 26.04 the CI matrix builds on - it runs.

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
  checking less than you expect. The thread sanitizer needs one thing said: it
  only sees what was compiled with it, and the Qt in front of you was not. Qt
  6.10 runs the QML loader on a thread of its own, and every report from it is
  inside `libQt6Core` with no frame of ours. `test/tsan-suppressions.txt` names
  those libraries and nothing else - a race in code written here still fails the
  test, which was checked by putting one there.
- **clang-tidy** in the compile step, so a violation fails the build the same
  way a compile error does. Nothing generated is judged, by it or by the
  compiler: `myapp_ui` holds only what Qt writes, and `CMakeLists.txt` takes the
  warnings back off it and off Qt's helper targets while leaving the sanitizer
  flags on. That is not tidiness. GCC at `-O3` reports a possible null
  dereference inside Qt's own `qhash.h` through the generated resource loader,
  and `-Werror` cannot tell that file from yours.
- **qmllint**, as a test, on the versions of Qt whose qmllint can resolve a
  `QML_ELEMENT` type.
- **GoogleTest**, fetched rather than vendored. Not QTest and not QML's own test
  runner: the tests that matter most here are the ones with no Qt in them, and
  one framework for all of them is one thing to learn.
- **A pinned environment** in `.devcontainer/`, the same one CI builds against,
  with Qt and the QML modules in it and the X11 socket passed through, so a
  window opened inside the container appears on your screen.
- **Workflows**: `pr-check` and `main-check` run the matrix, the pinned build
  and the static analysis; `nightly-sanitizer` runs the address and thread
  builds overnight; `release` turns a `vX.Y.Z` tag into a GitHub release;
  `dependency-freshness` opens one issue, weekly, when a pin this started with
  falls behind.

The rows are not a fixed list. `pr-check` and `main-check` ask this project what
it can be built with and build the rows it answers with, which is why there are
four of them and not six. So no check is named for a libc++ row at all - rather
than one that builds nothing and reports success. Worth knowing before you name
a row in GitHub's required status checks: a required check nothing reports waits
forever. The job named "what this project can be built with" lists every row in
its summary, and which of them were built.

A job named "what BUILD_SHARED_LIBS=ON builds and installs" runs on every pull
request, and here it installs no shared library at all: `myapp_core`,
`myapp_bridge` and `myapp_ui` all say `STATIC`, so the flag does not reach
them, and the prefix gets the binary and the desktop entry. The Qt libraries
the program links are shared, and are the system's rather than this project's,
so they are not in that count. The job prints the number either way, zero
included, rather than letting a green tick stand for a count nobody has seen.
What it checks here is that the flag changes nothing: configure, build, test
and install still pass with it on, and the installed program asks the loader
for nothing it cannot find. If that is not a claim worth keeping, deleting the
job is a reasonable answer - nothing else in the workflow depends on it.

There is no SBOM here, for the reason the command line and service templates
have none. `install(SBOM)` refuses a target that references one it cannot
attribute, and this program links static libraries that exist for its tests and
are never installed. Measured with CMake 4.4.2:

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
