# Contributing

## Where changes go

Here, in this repository.

Each template is also published as its own repository - `cpp-boilerplate-lib`
and, in time, its siblings. Those are build products:
`scripts/publish-template.sh` assembles one out of this repository and
force-pushes it, so anything committed there survives until the next publish
and no longer. Please do not open pull requests against them; their issue
trackers are switched off for the same reason, and this is where both belong.

If you have already pressed **Use this template**, none of this applies to you.
That copy is yours. It is a starting point rather than a dependency, so there
is nothing to send back and nothing to keep in sync.

## Building this repository

```sh
git clone https://github.com/skipbit/cpp-boilerplate
cd cpp-boilerplate
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
```

One build configures, compiles and tests every template at once, which is what
the CI does. It is also the only place some things can be checked: application
templates consume the library template through `find_package`, so building them
together is what proves the installed package actually works.

Presets: `debug` (warnings as errors), `release`, `asan`, `tsan`, `tidy`,
`clang-libc++` (clang against libc++, which needs `libc++-dev` and
`libc++abi-dev`).
CMake, a compiler and Ninja are enough; the test framework is fetched during
configuration.

Run `tidy` against a stock Ubuntu before pushing C++, not only against the
pinned image. `preset-check` installs Ubuntu's own clang-tidy on purpose - it is
what somebody typing the preset has - and the versions disagree in both
directions: 18 rejected a `std::chrono::ceil` that 21 and 22 accepted, and 21
and 22 traced a `dup(-1)` that 18 did not. A throwaway `FROM ubuntu:24.04` with
`clang-tidy` in it answers that before CI does; `cmake --build --preset tidy --
-k 0` gets all the findings rather than the first.

`.devcontainer/` holds the pinned toolchain - the same image the CI builds
against, CMake 4.4, GCC 14 and Clang 21. Open the repository in it if you want
the version of clang-tidy that decides whether the static analysis job is
green, or if you want to run the presets that need a CMake newer than your
distribution ships.

## Before you commit

```sh
./scripts/install-hooks.sh
```

Git does not run hooks that arrive with a clone, so this is a manual step, once
per clone. The dev container runs it for you. It points `core.hooksPath` at
`.githooks/`, and `.githooks/pre-commit` then runs, on the files in the commit
and not on the whole tree:

| tool | on | needs |
| --- | --- | --- |
| clang-format | `*.cpp` `*.hpp` `*.h` `*.cc` | - |
| clang-tidy | `*.cpp` `*.cc`, one at a time | a `tidy` build to read the flags from: `cmake --preset tidy` |
| actionlint | `.github/workflows/*.yml`, `ci/*.yml` | - |
| hadolint | `*Dockerfile` | - |
| shellcheck | `*.sh`, `.githooks/*` | - |
| `scripts/check-tidy-rationale.sh` | `.clang-tidy`, `docs/coding-style.md` | - |

Those patterns are written once, in `scripts/lint-paths.sh`, and the hook and
the CI job both ask it rather than carrying a copy. The second column above is
a description of that file, not a second definition of it - when they disagree,
the file is right. Two lists drift the way this one did: the hook checked `.h`
and `.cc` for months while the formatting job did not, so a file could pass a
commit that no job would ever have contradicted.

A tool that is not installed is skipped and said out loud, rather than treated
as a failure: a hook that refuses your commit because you have not installed
clang-format is a hook you will delete. `git commit --no-verify` bypasses it
once.

**CI does not skip.** All four tools are in the pinned image, the jobs run them
without asking whether they exist, and a checker that matched no files fails the
job rather than passing quietly - a check with nothing to do and a check that
found nothing look identical from outside, and only one of them is good news.
That is also why the versions are pinned: the `shellcheck` your distribution
ships is not necessarily the one deciding whether this is green.

The last row is the one that surprises people. Every check switched off in
`.clang-tidy` has to have its reason written down in `docs/coding-style.md`,
and that is checked rather than hoped for. The failure it exists to prevent is
a configuration that grows one exclusion at a time, each added to get a build
green, until nobody knows which of them still matter.

`.hadolint.yaml` switches off one check the same way, and its reason is in
`docs/toolchain.md`. Nothing enforces that one: it is a single line of
configuration next to a document written for the people who start a project
from this, so the pressure that makes `check-tidy-rationale.sh` worth its
existence is not there yet. Add a second exclusion and it will be.

## How the repository is arranged

```
cmake/modules/     shared CMake modules, used by every template
ci/                the workflows every published template gets
docs/              the reasoning behind the configuration
templates/lib/     the library template
templates/cli/     the command line template
templates/daemon/  the service template
templates/qt/      the Qt desktop template
.devcontainer/     the pinned toolchain, used by CI and the dev container
.githooks/         the checks that run before a commit
```

`templates/*/cmake/modules` is a symlink to `cmake/modules`. The monorepo keeps
one copy; the published templates get a real directory in the same place, so
their `CMakeLists.txt` needs no changes either way.

**Anything outside `templates/` is shared, so changing it changes every
template.** That is the point of the arrangement, and the thing to be careful
about: `.clang-tidy`, the CMake modules, the hooks and everything in `ci/` are
each written once and land in every published repository. A change that is only
right for one template belongs in `templates/<name>/`, where a file of the same
name wins over the shared one.

`.github/workflows/` is this repository's own CI and is not published: those
workflows build every template together, which is not a thing a single project
can do. `ci/` is the set a published template gets.

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
5. A row in the table in `README.md`, linking the repository it will be
   published to. That row is the only index there is, and publishing checks
   that it exists.

Everything else it gets for free. `scripts/publish-template.sh` is the
definition of what a published template contains: the license and the linting
configuration, the pinned environment, the hooks, the documents, the release
script, and the workflows in `ci/`. A template that needs a different version of
any of those puts its own copy in `templates/<name>/`, and that copy wins.

Application templates consume the library template through `find_package`
rather than linking it directly in the same build tree. That is deliberate: it
is the only arrangement in which a broken install rule fails a build.

## Publishing

```sh
./scripts/publish-template.sh lib            # assemble, report, throw away
./scripts/publish-template.sh lib --push     # assemble and publish
```

Without `--push` it assembles the tree, builds and tests it, prints the file
list and deletes it. Read that list. It is the answer to "what does somebody
who presses **Use this template** actually get", and it is easier to read than
the script.

The published repository is force-pushed. Three things guard that:

- The working tree has to be clean, so the recorded source commit means
  something.
- The README has to already link the repository being published. Publishing a
  template nobody can find from the table is how a template quietly stops
  existing.
- There must be no open pull request against it. A force-push would silently
  make one unmergeable.

Which gives the order: add the row and commit it, publish the template, then
push this repository. The other way round puts a link into the published README
that leads to a repository that does not exist yet.

`distribution-check.yml` runs after every push to `main` and asks, for each
directory under `templates/`, whether the repository it is published to still
matches what would be assembled now. It is the third badge in `README.md`.

That badge is red for as long as `main` contains a change to a distributed file
that has not been published, which is exactly as long as people are being given
the older thing. So red is a fact rather than a fault, and the fix is a publish
rather than a narrower comparison. It is not part of `pr-check`: a pull request
cannot be published from, so failing one on this would only teach people to
ignore it.

**A change outside `templates/` is a change to every template**, so publishing
the one you were working on does not finish it: everything already published is
behind until it is published too. Merging is not publishing, and the failing job
prints the commands.

Publishing changes nothing outside this repository. A template listed
somewhere else stays listed the way it was until that place is edited by hand,
which is a separate piece of work and one nothing here can check for you.

## What this repository does not have

No code of conduct, no security policy, no issue templates. They would be
forms rather than practice at one contributor, and a template with no runtime
has nowhere to report a vulnerability to. If somebody arrives who needs one,
that is the moment to write it.

No releases either, and so no `release.yml` in `.github/workflows/`. A `vX.Y.Z`
tag here would build nothing and publish nothing: what gets released is a
project somebody started from a template, and this is where the templates are
written rather than where one is used. `ci/release.yml` is a file this
repository ships, not one it runs.

Worth knowing before reading `docs/versioning.md`. That document is shared with
every template and is addressed to the project somebody starts, not to this
one, so the `.github/workflows/release.yml` it names is the copy a published
template carries - correct there, absent here. The step that corresponds to a
release in this repository is `scripts/publish-template.sh`: that force-push is
how a change reaches anybody.
