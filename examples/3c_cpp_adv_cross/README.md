# Cross-Compiling the Advanced C++ Project

> **Important:** Make sure that you have read and understood the previous
> example [*Advanced C++ Project*](../3_cpp_adv/README.md) first!

This example demonstrates how to add cross-compilation to the advanced C++
project.

Key takeaways from this example:

1. How to define a [toolchain for cross-compilation](#defining-a-cross-toolchain)
2. Which [architecture variables](#architecture-variables) are supported by the
   C/C++ rule set
3. How does the [*architecture config transition*](#architecture-config-transition) affect the build

## Defining a cross toolchain

To support cross-compilation, the toolchain definition in
[`etc/toolchain/CC/TARGETS`](./etc/toolchain/CC/TARGETS) was extended by a new
dispatch target `cross_toolchain`.

```jsonnet
// Dispatch target for cross toolchains
cross_toolchain: {
  type: ref('CC', 'defaults'),
  arguments_config: ['TOOLCHAIN_CONFIG'],
  base:
    // Dispatch on TOOLCHAIN_CONFIG['FAMILY'] ('gnu' if unset)
    //   'gnu'   -> target gcc
    //   'clang' -> target clang
    //   *       -> fail
    case(
      expr=_utils.get('FAMILY', 'TOOLCHAIN_CONFIG', default='gnu'),
      case={
        gnu: ['cross_gcc'],
        clang: ['cross_clang'],
      },
      default=fail('cross-compiliation requires family "gnu" or "clang"'),
    ),
},
```

Here, similar to the native toolchain definition, using [expression
`case()`](../../doc/must-lang.md#case) on variable `TOOLCHAIN_CONFIG["FAMILY"]`
the dispatch for the cross-compiler is performed. The actual cross-compiler
definition is again rather simple.

```jsonnet
// Compiler gcc for cross-compilation
cross_gcc: {
  type: ref('CC', 'defaults'),
  arguments_config: ['TARGET_ARCH', 'OS'],
  CC: join([ _utils.cross_prefix('TARGET_ARCH', 'OS', _cross_defaults),
             '-gcc']),
  CXX: join([ _utils.cross_prefix('TARGET_ARCH', 'OS', _cross_defaults),
              '-g++']),
  AR: 'ar',
  PATH: ['/bin', '/usr/bin'],
},
```

The target reads variables `TARGET_ARCH` and `OS` to compute a *cross-prefix*.
Default values for those variables are `'x86_64'` and `'linux'`, which produce
the cross-prefix `'x86_64-linux-gnu'`. This cross-prefix is
[joined](../../doc/must-lang.md#join) with either `'-gcc'` or `'-g++'` to define
the compiler name.

The actual implementation of the `cross_prefix()` helper function, can be found
in
[`etc/toolchain/CC/utils.libsonnet`](./etc/toolchain/CC/utils.libsonnet). It
depends on this implementation which architectures are supported. Users may want
to extend it with additional architectures. Supported architectures in this
example are:

- `x86`: 32 Bit Intel/AMD
- `x86_64`: 64 Bit Intel/AMD
- `arm`: 32 Bit ARM
- `arm64`: 64 Bit ARM

To use cross-compilation, simply set the variable `TARGET_ARCH` to one of the
supported architectures for building a target.

```sh
$ must build -D'{"TARGET_ARCH":"arm64"}'
INFO: Found 9 repositories to set up
INFO: Requested target is [["@","example","","APPS"],{"TARGET_ARCH":"arm64"}]
INFO: Discovered 4 actions, 2 trees, 0 blobs
INFO: Processed 4 actions, 0 cache hits.
INFO: Artifacts built, logical paths are:
        bin/helloworld [0154c3134ba171e86540bfdae5fd4911ea3e39ae:15920:x]
```

> Note that you need to have a working cross-compiler installed. Also note that
> some systems use a different cross-prefix. For instance on RedHat, you might
> need to set `{"OS":"redhat-linux"}` as well.

It might come as a surprise that  `TESTS` can still be successfully run, even
when setting `TARGET_ARCH` to an architecture different from the build host
(which runs the tests).

```sh
$ must build TESTS -D '{"TARGET_ARCH":"arm64"}'
INFO: Found 9 repositories to set up
INFO: Requested target is [["@","example","","TESTS"],{"TARGET_ARCH":"arm64"}]
INFO: Target tainted ["test"].
INFO: Discovered 13 actions, 6 trees, 3 blobs
INFO: Processed 13 actions, 13 cache hits.
INFO: Artifacts built, logical paths are:
        test_helloworld [78bdf795158282ebb82dc1a323c9377ab7e25527:177:t]
        test_libgreet [ef1636e09269555f476e0d550a2eda45daa61da6:177:t]
```

The reason for that is that the [C/C++ test
rules](https://github.com/just-buildsystem/rules-cc/tree/master?tab=readme-ov-file#rule-cctest-test) ignore `TARGET_ARCH` and instead are only
sensitive to `HOST_ARCH`. A detailed explanation why this is the case is
provided in the [*architecture config
transition*](#architecture-config-transition) section below.

## Architecture variables

In Mustbuild, there are no *per se* predefined variables. However, the [C/C++
rule set](https://github.com/just-buildsystem/rules-cc) uses the following
architecture variables for building.

| Variable | Meaning | Default value |
|:-|:-|:-:|
| `ARCH` | Unqualified base architecture | None |
| `HOST_ARCH` | Architecture of the build host | *derived from `ARCH`* |
| `TARGET_ARCH` | Architecture to build for | *derived from `ARCH`* |
| `BUILD_ARCH` | Architecture to generate code for (compilers) | *derived from `ARCH`* |

The `ARCH` variable is used to initialize all other architecture variables. If
your toolchain does not fallback to a working default architecture, you have to
set this variable to the architecture of the build host.

The `HOST_ARCH` variable specifies the architecture of the build host and is
derived from `ARCH` or can be set manually. Whenever an executable is built that
is input to an action (running on the build host), this variable is used to
determine for which architecture to build for. Typical examples for such
executables are tests and toolchains (which are also subject to [*architecture
config transition*](#architecture-config-transition) described below).

The `TARGET_ARCH` variable specifies the architecture to build for and is
derived from `ARCH` or can be set manually. Depending on this variable, the
dispatch which compiler to use for building is usually performed.

The `BUILD_ARCH` variable specifies the architecture to generate code for and is
derived from `ARCH` or can be set manually. This variable is only relevant for
building code generators (compilers) from source. Such a code generator may be
built for a specific `TARGET_ARCH`, while itself generating code for a different
`BUILD_ARCH` (e.g., a cross-compiler built from source).

## Architecture config transition

In general, the term [*config
transition*](https://github.com/just-buildsystem/justbuild/blob/master/doc/concepts/rules.md#implicit-dependencies-and-config-transitions)
refers to *implicitly modifying the configuration of a dependent target*. Rules
will perform a config transition implicitly if needed. It is up to the rule
developer to define config transitions wherever necessary.

Regarding cross-compilation, the [C/C++ rule
set](https://github.com/just-buildsystem/rules-cc) defines an *architecture
config transition* (called [`for
host`](https://github.com/just-buildsystem/rules-cc/blob/master/rules/transitions/EXPRESSIONS#L1)).
This config transition ensures two constraints:

1. A dependency that needs to execute on the build host is configured to be
   built for the build host architecture.  
   ⇨ `HOST_ARCH` becomes the dependency's `TARGET_ARCH`

2. A dependent code generator that needs to compile for the target architecture
   is configured to be built with support for generating code for this
   architecture.  
   ⇨ `TARGET_ARCH` becomes the dependency's `BUILD_ARCH`

The remaining architecture variables `ARCH` and `HOST_ARCH` are forwarded to the
dependency without any modifications.

        ┌─────────────────┐          ┌─────────────────┐
        │     target      |<─────────┤   dependency    |
        └─────────────────┘          └─────────────────┘

    Architecture config transition:
         ARCH=x86_64       ─────────> ARCH=x86_64
         HOST_ARCH=x86_64  ────┬────> HOST_ARCH=x86_64
         TARGET_ARCH=arm64 ──┐ └────> TARGET_ARCH=x86_64
         BUILD_ARCH=null     └──────> BUILD_ARCH=arm64

The [C/C++ rule set](https://github.com/just-buildsystem/rules-cc) uses this
architecture config transition in two scenarios

1. For targets in field `deps` of test rules
    - [`["CC/test","test"]`](https://github.com/just-buildsystem/rules-cc#rule-cctest-test)
    - [`["shell/test","script"]`](https://github.com/just-buildsystem/rules-cc#rule-shelltest-script)
2. For targets in field `toolchain` of default rules
    - [`["CC","defaults"]`](https://github.com/just-buildsystem/rules-cc#rule-cc-defaults)
    - [`["CC/proto","defaults"]`](https://github.com/just-buildsystem/rules-cc#rule-ccproto-defaults)
    - [`["CC/foreign","defaults"]`](https://github.com/just-buildsystem/rules-cc#rule-ccforeign-defaults)

For example, even when running the test `test_helloworld` with
`-D'{"TARGET_ARCH":"arm64"}'`, the depending `helloworld` binary will still be
built for `x86_64` (unless `HOST_ARCH` was set to a different architecture as
well).

        ┌─────────────────┐ deps     ┌─────────────────┐
        │ test_helloworld |<─────────┤   helloworld    |
        └─────────────────┘          └─────────────────┘

    Architecture config transition:
         ARCH=x86_64       ─────────> ARCH=x86_64
         HOST_ARCH=x86_64  ────┬────> HOST_ARCH=x86_64
         TARGET_ARCH=arm64     └────> TARGET_ARCH=x86_64
