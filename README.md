# Mustbuild [![Bootstrap and Deploy](../../actions/workflows/deploy.yml/badge.svg)](../../releases)

Mustbuild is a friendly fork of
[Justbuild](https://github.com/just-buildsystem/justbuild). It is maintained as
a patch series. This fork introduces extensions that mainly focus on improving
usability while being fully compatible with existing Justbuild projects.

Some of those extensions are:

- [A new preprocessor](./doc/preprocessor.md) that supports [language extensions](./doc/must-lang.md)
- [Improved target descriptions](./doc/targets.md)
- [Interactive progress reporting](./doc/progress.md)
- [Non-verbose command line output](./doc/verbosity.md)
- [Single binary for all subcommands](./doc/single-binary.md)

## Example

In an empty directory, create a file named `TARGETS` with the following content:

```jsonnet
{
  // Target 'helloworld' based on built-in rule 'generic'
  helloworld: {
    type: 'generic',
    cmds: 'echo Hello World > out.txt',
    outs: 'out.txt',
  },
}
```

Build the `helloworld` target and print the output file `out.txt`:

```sh
$ must build helloworld -P out.txt
INFO: Requested target is [["@","","","helloworld"],{}]
INFO: Discovered 1 actions, 0 trees, 0 blobs
INFO: Processed 1 actions, 0 cache hits.
INFO: Artifacts built, logical paths are:
        out.txt [557db03de997c86a4a028e1ebd3a1ceb225be238:12:f]
Hello World
```

## Tutorial

The tutorial consists of a set of example projects with extensive descriptions.
It is recommended to look at these projects in order.

1. [Plain project](./examples/1_plain/README.md)
2. [Minimal C++ project](./examples/2_cpp_min/README.md)
3. [Advanced C++ project](./examples/3_cpp_adv/README.md)
    1. [Adding binary and shell tests](./examples/3a_cpp_adv_tests/README.md)
    2. [Importing external libraries](./examples/3b_cpp_adv_extern/README.md)
    3. [Using cross-compilation](./examples/3c_cpp_adv_cross/README.md)

## Installing

Obtain and install Mustbuild from the latest bundled
[releases](https://github.com/oreiche/mustbuild/releases) or build it from
source. For more details, please see the [build guide](./doc/building.md).
