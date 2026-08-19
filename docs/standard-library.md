# The standard library, and which parts of it are here

## What is supported

Support is not "C++23". It is a set of environments, and an environment is an
operating system, a compiler and a standard library - three things, not two.
The set is the CI matrix. When this document and the matrix disagree, the
matrix is right.

Measured with `-std=gnu++23`, on the stock toolchains of each release:

| # | OS | compiler | standard library | `__cpp_concepts` | `std::expected` | `std::print` |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Ubuntu 24.04 | GCC 13.3.0 | libstdc++ 13 | 202002 | yes | **no** |
| 2 | Ubuntu 24.04 | Clang 18.1.3 | libstdc++ 13 | **201907** | **no** | **no** |
| 3 | Ubuntu 24.04 | Clang 18.1.3 | libc++ 18 | 201907 | yes | yes |
| 4 | Ubuntu 26.04 | GCC 15.2.0 | libstdc++ 15 | 202002 | yes | yes |
| 5 | Ubuntu 26.04 | Clang 21.1.8 | libstdc++ 15 | 202002 | yes | yes |
| 6 | Ubuntu 26.04 | Clang 21.1.8 | libc++ 21 | 202002 | yes | yes |

Row 2 is not an exotic environment. It is what you get by installing clang on
Ubuntu 24.04 and building, and it is what `cmake --preset tidy` uses.

Rows 2 and 3 are the same compiler. Everything that differs between them comes
from the library, which is the point of the table.

## The floor is the intersection

The code shipped here uses only what every row provides. Not because the rest
is bad, but because of what this code is: an example to be deleted and replaced.
Using the newest thing available in a file whose purpose is to be thrown away
buys very little, and costs three things - a template whose own advertised
preset fails on a stock machine, a red CI in the repository of whoever pressed
**Use this template**, and a failure that arrives as a page of compiler output
rather than as a sentence.

Your code is not the example. The floor is where the template starts, not where
your project has to stay.

## Stepping outside it

Say so in `CMakeLists.txt`:

```cmake
cppbp_require_std_feature(EXPECTED)
```

Configuration then stops, on exactly the environments that cannot provide it,
with the environment named and the ways out listed. It does not stop anywhere
else. What it costs is one line; what it buys is that the environments you have
decided not to support say so at the beginning of a build instead of the middle,
and say it in the same words to everyone who clones the repository.

`EXPECTED` and `PRINT` are the features currently checked. Both were measured
into the table above; nothing is on the list that has not been. Adding another
is a row in `cmake/modules/StandardLibraryFeatures.cmake`.

Configuration reports what it found, whether or not anything asked:

```
-- Standard library: libstdc++ (Clang 18.1.3, std::expected no, std::print no)
```

The check compiles the feature rather than comparing a version macro. It has to:
`<expected>` exists in row 2 and is empty, so a check that asks whether the
header can be included answers yes and is wrong.

## Why row 2 is missing `std::expected`

Not because Clang 18 is missing a language feature. libstdc++ declares the
contents of `<expected>` only when the compiler reports
`__cpp_concepts >= 202002L`, and Clang 18 reports `201907L` - so the header is
present and empty. The same compiler, given libc++, has `std::expected` (row 3).

It is a library's declaration condition, not a compiler's capability, and the
distinction matters when you are deciding what to do about it: there is nothing
to wait for in the compiler, and the way out is a different library.

It also expires. Clang 21 reports `202002L`, so rows 5 and 6 are unaffected and
this particular hole closes when 24.04 stops being the oldest supported release.
`std::print` is the plainer case: GCC 13 does not have `<print>` at all, and GCC
14 does.

## The way out, and why it is not the default

`cmake --preset clang-libc++` builds with clang against libc++, which is row 3,
which has everything.

It is not what clang does by default here, deliberately:

- It needs `libc++-dev` and `libc++abi-dev` installed. A template whose first
  instruction is an installation is not a starting point.
- Objects built against libc++ do not link against objects built against
  libstdc++. An installed library and the project consuming it have to agree, or
  the consumer gets a link error naming symbols nobody wrote.
- Which standard library a project runs on is a decision with consequences past
  compiling. A template should not make it quietly on your behalf.

So it is a named preset rather than a default: a thing to reach for once, on
purpose, and not something you discover you have been using.
