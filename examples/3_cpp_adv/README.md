# Advanced C++ Project

This advanced example C++ project demonstrates how executables and libraries can
be built with specific compiler flags and toolchain definitions.

Key takeaways from this example:

1. Use [separate repositories](#multi-repository-configuration) to specify [compile flags](#compile-flags) and [toolchains](#toolchain-definition)
2. Always provide [export targets](#export-targets)
3. *Staging* must be considered for [debugging](#debugging-your-code)

## Repository structure

The top-level directory contains Mustbuild files (`TARGETS` and `repos.json`),
directories for C/C++ sources, and the directory `etc` for additional *target
roots* (set of `TARGETS` files).

```
3_cpp_adv/          # Workspace root
|
├── TARGETS         # Mustbuild top-level targets
├── repos.json      # Mustbuild multi-repository configuration
├── apps/           # Application sources
├── libs/           # Library sources
└── etc/            # Mustbuild target roots
    |
    ├── flags/      # Targets for compiler flags
    └── toolchain/  # Targets for toolchain definition
```

The directory `etc` contains two *target roots* :

1. `etc/flags`: contains targets for setting the project's [compile
   flags](#compile-flags)
2. `etc/toolchain`: contains targets for [defining the
   toolchain](#toolchain-definition) to use

## Multi-repository configuration

Looking at the multi-repository configuration
[`etc/repos.json`](./etc/repos.json), you can see that the two additional roots
(`root/flags` and `root/toolchain`) were used to create the repositories

1. `rules/flags`: rules that include the compile flags
2. `rules/toolchain`: rules that include the toolchain definition

The main repository `example` imports `rules/flags` via the open name `rules`,
which inherits the definitions from `rules/toolchain` via the open name
`toolchain`.

    ┌─────────────────┐ rules    ┌─────────────────┐
    │     example     |<─────────┤   rules/flags   |<──── root/flags
    └─────────────────┘          └─────────────────┘
                                          ▲ toolchain
                                          |
                                 ┌────────┴────────┐
                                 │ rules/toolchain |<──── root/toolchain
                                 └─────────────────┘

It is technically not required to split flags and toolchain definitions into two
separate repositories. However, it is considered good practice to do so, because
in this way the toolchain can easily be replaced later.

> Imagine someone importing this project into their own project. They can easily
> remap this project's toolchain to their own toolchain, because it was properly
> separated.

## Compile flags

You can find the compile flags for this project in
[`etc/flags/CC/TARGETS`](./etc/flags/CC/TARGETS), which implements the
`defaults` target using the rule
[`["CC","defaults"]`](https://github.com/just-buildsystem/rules-cc?tab=readme-ov-file#rule-cc-defaults).

```jsonnet
defaults: {
  type: ref('CC', 'defaults'),
  // We want to read variable 'DEBUG'.
  arguments_config: ['DEBUG'],
  // Inherit flags from toolchain settings (see etc/toolchain/CC/TARGETS).
  base: [ref_ext('toolchain', 'CC', 'defaults')],
  // Set flags for C and C++ (additional to flags from toolchain settings)
  ADD_CFLAGS: select(var('DEBUG'), _cflags_dbg, _cflags_rel),
  ADD_CXXFLAGS: select(var('DEBUG'), _cxxflags_dbg, _cxxflags_rel),
},
```

The C and C++ compile flags are specified using the fields `ADD_CFLAGS` and
`ADD_CXXFLAGS`. Using the [`select()` expression](../../doc/must-lang.md#select)
on variable `DEBUG`, either debug or release flags are being set. Note that the
actual flags are coming from local Jsonnet variables defined above.

To see if the compile flags are correctly used, run Mustbuild with `--log-limit
5` to see all action commands.

```sh
$ must build --log-limit 5                      # uses -O2 -DNDEBUG
$ must build --log-limit 5 -D'{"DEBUG":true}'   # uses -O0 -g
```

The actual compilers used have been set from open name `toolchain`, which is
used as `base` to inherit toolchain settings from.

## Toolchain definition

You can find the toolchain definition for this project in
[`etc/toolchain/CC/TARGETS`](./etc/toolchain/CC/TARGETS), which also implements
the `defaults` target using the rule
[`["CC","defaults"]`](https://github.com/just-buildsystem/rules-cc?tab=readme-ov-file#rule-cc-defaults).

```jsonnet
defaults: {
  type: ref('CC', 'defaults'),
  arguments_config: ['TOOLCHAIN_CONFIG'],
  base:
    // Dispatch on TOOLCHAIN_CONFIG['FAMILY'] ('generic' if unset)
    //   'generic' -> target generic
    //   'gnu'     -> target gcc
    //   'clang'   -> target clang
    //   *         -> fail
    case(expr=_utils.get('FAMILY', 'TOOLCHAIN_CONFIG', default='generic'),
         case={
           generic: ['native_generic'],
           gnu: ['native_gcc'],
           clang: ['native_clang'],
         },
         default=fail('unsupported compiler family'),
    ),
},
```

Here the [`case()` expression](../../doc/must-lang.md#case) on variable
`TOOLCHAIN_CONFIG["FAMILY"]` is used to perform the dispatch on which compiler
definition to use. The actual compiler definition is fairly simple.

```jsonnet
// Compiler gcc for native compilation
native_gcc: {
  type: ref('CC', 'defaults'),
  CC: 'gcc',
  CXX: 'g++',
  AR: 'ar',
  PATH: ['/bin', '/usr/bin'],
},
```

To see if the specified toolchain is correctly used, run Mustbuild with
`--log-limit 5` to see all action commands.

```sh
$ must build --log-limit 5                                           # uses c++
$ must build --log-limit 5 -D'{"TOOLCHAIN_CONFIG":{"FAMILY":"gnu"}}' # uses g++
```

## Top-level targets

The top-level targets are defined in the workspace root's [`TARGETS`](./TARGETS)
file. It usually contains *export* and *install* targets.

### Export targets

Export targets are *public targets*, which are intended to be consumed by other
projects that are importing this project. Therefore, those targets are only
accepting a specific set of variables (specified in `flexible_config`). All
other variables will be ignored.

Export targets provided by this project are:

- `helloworld`: the main binary
- `libgreet`: the greeter library used by `helloworld`

Important variables accepted by these targets are:

|Variable|Supported Values|Default Value|
|-|:-:|:-:|
| `DEBUG` | true, false | false |
| `TOOLCHAIN_CONFIG["FAMILY"]` | gnu, clang, generic | generic |
| `BUILD_SHARED` | true, false | false |

Use the `describe` subcommand to see the full list of supported variables:

```sh
$ must describe helloworld  # list all variables supported by helloworld
```

### Install targets

Install targets use the rule
[`["CC","install-with-deps"]`](https://github.com/just-buildsystem/rules-cc#rule-cc-install-with-deps),
which is useful to create a file structure for installing multiple targets. It
will also include required transitive dependencies of each target. Which
dependencies are considered "required" depends on the target type: binaries need
shared libraries for execution, while static libraries need their public headers
and depending static libraries for compiling and linking.

Install targets provided by this project are:

- `APPS`: installing `helloworld` and its runtime libraries to `bin`/`lib`
- `LIBS`: installing `libgreet` and its public header to `lib`/`include`

For example, building `APPS` with `{"BUILD_SHARED":true}` will generate an installation file structure containing the `helloworld` binary and its depending library `libgreet.so`.

```sh
$ must build APPS -D'{"BUILD_SHARED":true}'
INFO: Found 6 repositories to set up
INFO: Requested target is [["@","example","","APPS"],{"BUILD_SHARED":true}]
INFO: Discovered 4 actions, 2 trees, 0 blobs
INFO: Processed 4 actions, 1 cache hits.
INFO: Artifacts built, logical paths are:
        bin/helloworld [37f70f81e13f623ccc2af048077f20977a0ff36c:16976:x]
        lib/libgreet.so [2cd949b583de6dbc971f26698b40f9a377ca5e02:17448:x]
```

## Debugging your code

Mustbuild uses *staging*: the actual file structure used by compile actions may
be different from your project's file structure (see `stage` in
[`libs/greet/TARGETS`](./libs/greet/TARGETS)). It is up to the users to define
their desired staging. Targets without any `stage` are considered to be located
at the *stage root*.

For debugging, specifying the *stage roots* in a [`gdbinit` file](./etc/gdbinit)
might be useful. It helps mapping the debug information to your project's file
structure.

```sh
$ must install APPS -D'{"DEBUG":true}' -o .
$ gdb -x etc/gdbinit ./bin/helloworld
```
