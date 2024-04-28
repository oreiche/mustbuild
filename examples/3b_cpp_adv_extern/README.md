# Adding External Libraries to the Advanced C++ Project

> **Important:** Make sure that you have read and understood the previous
> example [*Advanced C++ Project*](../3_cpp_adv/README.md) first!

This example demonstrates how to import and build external libraries for using
them in the advanced C++ project.

Key takeaways from this example:

1. Externals can be imported via the [multi-repository
   configuration](#multi-repository-configuration)
2. Externals can be built as [native targets](#native-target-fmt)
3. Externals can be built as [foreign targets](#foreign-target-gtest_main),
   using *foreign build tools*

## Repository structure

The repository structure remains almost identical to the previous advanced C++
project, with one exception: a new *target root* `etc/extern` was added, which
contains the targets for building external libraries.

## Multi-repository configuration

Looking at the multi-repository configuration
[`etc/repos.json`](./etc/repos.json), you can see that the additional root
(`root/extern`) was used to create the repositories

1. `fmtlib`: the [modern formatter library](https://github.com/fmtlib/fmt)
2. `gtest`: the [Google testing and mocking
   framework](https://github.com/google/googletest)

The main repository `example` imports both of them via the open names `fmtlib`
and `gtest`, which themselves import `rules/toolchain` (rules that include the
toolchain definition) via the open name `rules`.

    ┌─────────────────┐ rules    ┌─────────────────┐
    │     example     |<─────────┤   rules/flags   |<──── root/flags
    └─────────────────┘          └─────────────────┘
             ▲ {fmtlib,gtest}             ▲ toolchain
             |                            |
    ┌────────┴────────┐ rules    ┌────────┴────────┐
    │ {fmtlib,gtest}  |<─────────┤ rules/toolchain |<──── root/toolchain
    └─────────────────┘          └─────────────────┘
             ▲
             |
        root/extern

## External library targets

The build descriptions for external libraries are located in the *targets root*
`etc/extern`. This *targets root* is an overlay to the source directory of the
repository. Therefore, the containing `*.TARGETS` files can reference source
files as if they are located in the same directory, mimicking the same directory
structure.

### Native target `fmt`

A *native target* uses Mustbuild for building. Although the repository `fmtlib`
comes with its own build system, the library is small enough to provide a
*native build description* for it by using the native rule
[`["CC","library"]`](https://github.com/just-buildsystem/rules-cc#rule-cc-library).
The *native target* `fmt` is described in
[`etc/extern/fmtlib.TARGETS`](./etc/extern/fmtlib.TARGETS).

```jsonnet
// Native target "fmt"
fmt: {
  // Use rule ["CC", "library"] from binding "rules"
  type: ref_ext('rules', 'CC', 'library'),
  // We want to read variable 'DEBUG'.
  arguments_config: 'DEBUG',
  // Library name: libfmt.a
  name: 'fmt',
  // Library type: static
  shared: false,
  // Public headers
  hdrs: [ref('include', 'public_headers')],
  // Source files
  srcs: ['src/os.cc', 'src/format.cc'],
  // Private compile flags (depends on 'DEBUG')
  'private-cflags': select(var('DEBUG'),
                           ['-O0', '-g'],
                           ['-O2', '-DNDEBUG']),
},
```

The target directly references the external source files `src/os.cc` and
`src/format.cc`. Additional local compile flags are set depending on the
variable `DEBUG`.

To build the target, you have to set the main repository to `fmtlib`, because
this target is technically not part of the `example` repository.

```sh
$ must --main fmtlib build fmt
INFO: Found 5 repositories to set up
INFO: Requested target is [["@","fmtlib","","fmt"],{}]
INFO: Discovered 3 actions, 1 trees, 0 blobs
INFO: Processed 3 actions, 0 cache hits.
INFO: Artifacts built, logical paths are:
        libfmt.a [123b5f9d93f7deaa9cb444009b6ef98325cb4bc7:266088:f]
      (1 runfiles omitted.)
```

In this example project, the target `greet` (defined in 
[`libs/greet/TARGETS`](./libs/greet/TARGETS)) uses the external library `fmt` if
variable `USE_FMTLIB` is true. This becomes evident when building the top-level
target `LIBS`, which installs `libgreet` including its dependency `libfmt.a`.

```sh
$ must build LIBS -D'{"USE_FMTLIB":true}'
INFO: Found 9 repositories to set up
INFO: Requested target is [["@","example","","LIBS"],{"USE_FMTLIB":true}]
INFO: Discovered 5 actions, 2 trees, 1 blobs
INFO: Processed 5 actions, 3 cache hits.
INFO: Artifacts built, logical paths are:
        include/greet/greet.hpp [cff6acf4df51e55e9283e956840a772616ce05d8:133:f]
        lib/greet/libgreet.a [abf39695fcab74ba19b3684d5a52716277055033:2104:f]
        lib/libfmt.a [123b5f9d93f7deaa9cb444009b6ef98325cb4bc7:266088:f]
        share/pkgconfig/greet.pc [a431bb34beebef273bac537c2e18a3377488842a:234:f]
```

> Note that when building with `{"BUILD_SHARED":true}`, the library `libfmt.a`
> disappears, because all of `libgreet`'s private dependencies are *eaten up*
> by the shared object.

### Foreign target `gtest_main`

*Foreign targets* are not built directly by Mustbuild. Instead, Mustbuild calls
a *foreign build tool* and collects the produced
artifacts. Currently supported foreign build rules are:

- [`["CC/foreign/make","library"]`](https://github.com/just-buildsystem/rules-cc#rule-ccforeignmake-library) for building with GNU Make
- [`["CC/foreign/cmake","library"]`](https://github.com/just-buildsystem/rules-cc#rule-ccforeigncmake-library) for building with CMake
- [`["CC/foreign/shell","library"]`](https://github.com/just-buildsystem/rules-cc#rule-ccforeignshell-library) for building using custom shell commands

The complexity of the `gtest` repository justifies using CMake. The *foreign
target* `gtest_main` is described in
[`etc/extern/gtest.TARGETS`](./etc/extern/gtest.TARGETS).


```jsonnet
// Foreign target "gtest_main"
gtest_main: {
  // Use rule ["CC/foreign/cmake", "library"] from binding "rules"
  type: ref_ext('rules', 'CC/foreign/cmake', 'library'),
  // We want to read variable 'DEBUG'.
  arguments_config: 'DEBUG',
  // Library name
  name: 'gtest_main',
  // Project directory (includes CMakeLists.txt)
  project: [tree('.')],
  // CMake defines (-Dxxx)
  defines: _gtest_defines('DEBUG'),
  // Produced library files
  out_libs: 'libgtest_main.a',
  // Dependencies
  deps: ['gtest'],
},
```

The target directly references the entire source tree `tree('.')`, including all
`CMakeLists.txt` files. Depending on variable `DEBUG`, the build option
`CMAKE_BUILD_TYPE` is set to either `Debug` or `Release`.

To build the target, you have to set the main repository to `gtest`, because
this target is technically not part of the `example` repository.

> Note that for building this target, `cmake` must be available in `PATH`. The
> settings can be adjusted in
> [`etc/toolchain/CC/foreign/TARGETS`](./etc/toolchain/CC/foreign/TARGETS).

```sh
$ must --main gtest build gtest_main
INFO: Found 5 repositories to set up
INFO: Requested target is [["@","gtest","","gtest_main"],{}]
INFO: Discovered 5 actions, 0 trees, 1 blobs
INFO: Processed 2 actions, 0 cache hits, 3 omitted.
INFO: Artifacts built, logical paths are:
        libgtest_main.a [3ab2c3a25eb17f3fab2ad0960357a0ac4fe41dc7:3086:f]
```

In this example project, the target `test_libgreet` (defined in
[`test/TARGETS`](./test/TARGETS)) uses the external library `gtest_main`. This
is clearly visible when looking at the produced test report.

```sh
$ must build TESTS -P test_libgreet/stdout
INFO: Found 9 repositories to set up
INFO: Requested target is [["@","example","","TESTS"],{}]
INFO: Target tainted ["test"].
INFO: Discovered 13 actions, 6 trees, 3 blobs
INFO: Processed 13 actions, 11 cache hits.
INFO: Artifacts built, logical paths are:
        test_helloworld [4f0b6c7d0f4069834f98ad6522432921fa15c80e:177:t]
        test_libgreet [1021990d001bb43b3db8c032df4943160b8d2a7a:177:t]
Running main() from /home/user/.cache/just/protocol-dependent/generation-0/exec_root/a5484da2d0ea457cdfc01ea0b45ee4464cdc20fe.6404-127520892503616/build_root/source/googletest/src/gtest_main.cc
[==========] Running 1 test from 1 test suite.
[----------] Global test environment set-up.
[----------] 1 test from GreetTest
[ RUN      ] GreetTest.output
[       OK ] GreetTest.output (0 ms)
[----------] 1 test from GreetTest (0 ms total)

[----------] Global test environment tear-down
[==========] 1 test from 1 test suite ran. (0 ms total)
[  PASSED  ] 1 test.
```

## Intellisense support for externals

For code analysis (intellisense, linters, etc.), all external headers that are
included by the main project must be accessible. As those are only visible to
the build (within build actions), a target needs to be defined that installs
those headers for you.

In the top-level [`TARGETS`](./TARGETS) file, the target `DEV` uses rule
[`["CC","install-with-deps"]`](https://github.com/just-buildsystem/rules-cc#rule-cc-install-with-deps)
to install the public headers (`hdrs-only`) of all externals.

```jsonnet
// Installed headers of external libraries (for development/intellisense)
DEV: {
  type: ref_ext('rules', 'CC', 'install-with-deps'),
  'hdrs-only': true,
  targets: [
    ref_ext('fmtlib', '', 'fmt'),
    ref_ext('gtest', '', 'gtest_main'),
  ],
},
```

This target builds all externals and installs their public headers to a location
of your choice. This location must be added to the search paths of your IDE or
linter.

```sh
$ must install DEV -o .ext/include
INFO: Found 9 repositories to set up
INFO: Requested target is [["@","example","","DEV"],{}]
INFO: Discovered 8 actions, 1 trees, 1 blobs
INFO: Processed 2 actions, 2 cache hits, 6 omitted.
INFO: Artifacts can be found in:
        .ext/include/fmt [a9d20ba6a8bbb01b278b596fe5e8157b03082a97:461:t]
        .ext/include/gtest [5225df8651dadc1506b58cdda5df06be7375b986:560:t]
# add .ext/include to your IDE's search paths
```
