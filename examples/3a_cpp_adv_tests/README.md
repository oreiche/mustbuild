# Writing Tests for the Advanced C++ Project

> **Important:** Make sure that you have read and understood the previous
> example [*Advanced C++ Project*](../3_cpp_adv/README.md) first!

This example demonstrates how to extend the advanced C++ project by adding
binary tests and shell tests.

Key takeaways from this example:

1. Test targets are used to ["build" a test report](#test-concept)
2. The C/C++ rule set supports [binary tests](#binary-test-test_libgreet) and
   [shell tests](#shell-test-test_helloworld)
3. Test reports can be [combined with install rules](#combined-test-target)

## Repository structure

The repository structure remains almost identical to the previous advanced C++
project, with one exception: a new top-level directory `test` was added for
providing the test sources.

## Test concept

Tests can be added by writing specific test targets. Like most other targets,
also test targets are essentially *build targets*, i.e., they run a build
action to produce an artifact. In this case, the artifact that is being built is
a test report. Consequently, the subcommand `build` is used to run tests.

### Failing tests

Test targets are allowed to fail, i.e., their failure will not abort the build
process. Instead, failing test targets will produce a warning message and their
reports will be separately listed as "failed artifacts" at the end of the build
process.

### Tainting

All test targets are *tainted* with the string `"test"`. The way *tainting*
works is that all targets that depend on a test target must be tainted with the
string `"test"` as well (and possibly even more strings). The target analysis
will fail if this constraint is violated. It is up to the users to define with
what strings their targets are tainted with.

## Test targets

The [C/C++ rule set](https://github.com/just-buildsystem/rules-cc) supports two
types of test targets:

1. **Binary tests:** using rule
   [`["CC/test","test"]`](https://github.com/just-buildsystem/rules-cc#rule-cctest-test)
   for testing native libraries
2. **Shell tests:** using rule
   [`["shell/test","script"]`](https://github.com/just-buildsystem/rules-cc#rule-shelltest-script)
   for running shell tests

Building the test report with these rules will produce the artifacts `result`,
`stderr`, `stdout`, `time-start`, and `time-stop`. Furthermore, one additional
runfile is produced: a directory with the name of the test that also contains
all of the aformentioned artifacts. This directory is particularily useful for
the conflict-free [combining of test reports](#combined-test-target).

### Binary test `test_libgreet`

The binary test `test_libgreet` is defined in [`test/TARGETS`](./test/TARGETS),
using the rule
[`["CC/test","test"]`](https://github.com/just-buildsystem/rules-cc#rule-cctest-test).

```jsonnet
// Binary test for the "libgreet" library
test_libgreet: {
  // Uses rule ["CC/test", "test"] (test binary) from bindings "rules"
  type: ref_ext('rules', 'CC/test', 'test'),
  // Name of the test
  name: 'test_libgreet',
  // Source files
  srcs: ['test_libgreet.cpp'],
  // Depends on the public top-level (export) target "libgreet"
  'private-deps': [
    ref('', 'libgreet'),
  ],
},
```

> Note that binary tests internally refer to a *launcher*, which requires to
> create an empty module in the rule's target root at
> [`etc/flags/CC/test/TARGETS`](./etc/flags/CC/test/TARGETS).

The actual test source code can be found in
[`test_libgreet.cpp`](./test/test_libgreet.cpp).

To build the test report of target `test_libgreet` (in module `test`) and print the `stdout`, run:

```sh
$ must build test test_libgreet -P stdout
INFO: Found 6 repositories to set up
INFO: Requested target is [["@","example","test","test_libgreet"],{}]
INFO: Target tainted ["test"].
INFO: Discovered 5 actions, 3 trees, 1 blobs
INFO: Processed 5 actions, 2 cache hits.
INFO: Artifacts built, logical paths are:
        result [7ef22e9a431ad0272713b71fdc8794016c8ef12f:5:f]
        stderr [8b137891791fe96927ad78e64b0aad7bded08bdc:1:f]
        stdout [789f841ace2ee3920474232e7032e4646da0bc0a:19:f]
        time-start [82e67ac5ca861af00f38ccc825021f4cfc41aa6a:11:f]
        time-stop [82e67ac5ca861af00f38ccc825021f4cfc41aa6a:11:f]
      (1 runfiles omitted.)
All tests passed.
```

### Shell test `test_helloworld`

The shell test `test_helloworld` is defined in [`test/TARGETS`](./test/TARGETS),
using the rule
[`["shell/test","script"]`](https://github.com/just-buildsystem/rules-cc#rule-shelltest-script).

```jsonnet
// Shell test for the "helloworld" binary
test_helloworld: {
  // Uses rule ["shell/test", "script"] from bindings "rules"
  type: ref_ext('rules', 'shell/test', 'script'),
  // Name of the test
  name: 'test_helloworld',
  // Test script (the actual script is defined below)
  test: ['test_helloworld.sh'],
  // Depends on the public top-level (export) target "helloworld"
  deps: [
    ref('', 'helloworld'),
  ],
},
```

> Note that shell tests internally refer to a *launcher*, which requires to
> create an empty module in the rule's target root at
> [`etc/flags/shell/test/TARGETS`](./etc/flags/shell/test/TARGETS).

The test's actual shell script `test_helloworld.sh` is defined inline in the
same [`TARGETS`](./test/TARGETS) file using the [built-in rule
`file_gen`](https://github.com/just-buildsystem/justbuild/blob/master/doc/concepts/built-in-rules.md#file_gen).

To build the test report of target `test_helloworld` (in module `test`) and print the `stdout`, run:

```sh
$ must build test test_helloworld -P stdout
INFO: Found 6 repositories to set up
INFO: Requested target is [["@","example","test","test_helloworld"],{}]
INFO: Target tainted ["test"].
INFO: Discovered 5 actions, 4 trees, 1 blobs
INFO: Processed 5 actions, 4 cache hits.
INFO: Artifacts built, logical paths are:
        result [7ef22e9a431ad0272713b71fdc8794016c8ef12f:5:f]
        stderr [e69de29bb2d1d6434b8b29ae775ad8c2e48c5391:0:f]
        stdout [dbb1d9a1795781bb0c47944df71ae5d87fec71c3:44:f]
        time-start [b45b17627fc4be3676abb42d6658dc1156fb96f5:11:f]
        time-stop [b45b17627fc4be3676abb42d6658dc1156fb96f5:11:f]
      (1 runfiles omitted.)
SUCCESS: Got expected output 'Hello World!'
```

### Combined test target

Test reports (the output of test targets) can be combined with the [built-in
rule
`install`](https://github.com/just-buildsystem/justbuild/blob/master/doc/concepts/built-in-rules.md#install).
The `install` rule will collect the runfiles of the targets listed in its field
`deps`. An example is provided with the target `TESTS` in the top-level
[`TARGETS`](./TARGETS) file.

```jsonnet
// Installed test reports ("meta target" combining all test reports)
TESTS: {
  type: 'install',
  // Taint this target with 'test' so it can depend on other targets that are
  // tainted with 'test' (all test-targets are implicity tainted with 'test').
  tainted: 'test',
  // Dependencies (test targets to collect and combine reports from)
  deps: [
    ref('test', 'test_libgreet'),
    ref('test', 'test_helloworld'),
  ],
},
```

> Note that it is mandatory to taint this target with string `"test"` to fulfill
> the [taintness constraint](#tainting). 

Building the `TESTS` target is a convenient way to run all of the project's test
targets with a single command.

```sh
$ must build TESTS
INFO: Found 6 repositories to set up
INFO: Requested target is [["@","example","","TESTS"],{}]
INFO: Target tainted ["test"].
INFO: Discovered 8 actions, 5 trees, 2 blobs
INFO: Processed 8 actions, 8 cache hits.
INFO: Artifacts built, logical paths are:
        test_helloworld [4f0b6c7d0f4069834f98ad6522432921fa15c80e:177:t]
        test_libgreet [f3cc1f4a83eca700a36f7012b587731924dcfef6:177:t]
```

You can still access the individual artifacts of test reports directly, by
specifying the test's directory prefix, e.g., `-P test_helloworld/stdout`.

## Running memory leak checkers

Users can use the variable `CC_TEST_LAUNCHER` to specify a launcher for binary
tests. The following code creates the configuration `launcher.json`, which
specifies Valgrind as test launcher.

```sh
$ echo '{"CC_TEST_LAUNCHER": ["valgrind", "--leak-check=full", "--error-exitcode=1"]}' >launcher.json
```

To *re*build all binary test reports with Valgrind as launcher and print
`stderr` of target `test_libgreet`, run:

```sh
$ must build TESTS -c launcher.json -P test_libgreet/stderr
INFO: Found 6 repositories to set up
INFO: Requested target is [["@","example","","TESTS"],{"CC_TEST_LAUNCHER":["valgrind","--leak-check=full","--error-exitcode=1"]}]
INFO: Target tainted ["test"].
INFO: Discovered 8 actions, 5 trees, 3 blobs
INFO: Processed 8 actions, 7 cache hits.
INFO: Artifacts built, logical paths are:
        test_helloworld [4f0b6c7d0f4069834f98ad6522432921fa15c80e:177:t]
        test_libgreet [45c5877748f6fda7f8d08f8807072677b30d3fe6:177:t]
==5988== Memcheck, a memory error detector
==5988== Copyright (C) 2002-2017, and GNU GPL'd, by Julian Seward et al.
==5988== Using Valgrind-3.18.1 and LibVEX; rerun with -h for copyright info
==5988== Command: ../test
==5988== 
==5988== 
==5988== HEAP SUMMARY:
==5988==     in use at exit: 0 bytes in 0 blocks
==5988==   total heap usage: 2 allocs, 2 frees, 76,800 bytes allocated
==5988== 
==5988== All heap blocks were freed -- no leaks are possible
==5988== 
==5988== For lists of detected and suppressed errors, rerun with: -s
==5988== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```
