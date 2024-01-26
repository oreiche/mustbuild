# Plain Project with Built-in Rules

This plain example project demonstrates how to use
[built-in rules](https://github.com/just-buildsystem/justbuild/blob/master/doc/concepts/built-in-rules.md) to define:

1. [Generic targets](#generic-targets)
2. [File-gen targets](#file-gen-targets)
3. [Install targets](#install-targets)

## Repository structure

A single top-level [`TARGETS`](./TARGETS) is sufficient to describe the build of
a project that only uses built-in rules.

## Generic targets

One of the simplest buildable target a user can define uses the [built-in rule
`generic`](https://github.com/just-buildsystem/justbuild/blob/master/doc/concepts/built-in-rules.md#generic).
With this rule, custom shell commands can be run to produce the specified
outputs.


### Simple Greeter

The `simple_greeter` computes the file `out.txt` from a static string using the
rule `generic`. It is defined in the file [TARGETS](./TARGETS).

```jsonnet
simple_greeter: {
  type: 'generic',
  cmds: ['printf "Hello World\n" > out.txt'],
  outs: ['out.txt'],
},
```

To build the output of this greeter, run:

```sh
$ must build simple_greeter
INFO: Requested target is [["@","","","simple_greeter"],{}]
INFO: Discovered 1 actions, 0 trees, 0 blobs
INFO: Processed 1 actions, 0 cache hits.
INFO: Artifacts built, logical paths are:
        out.txt [557db03de997c86a4a028e1ebd3a1ceb225be238:12:f]
```

By default, the subcommand `build` will *not* pollute the source directory and
*not* stage any
outputs to your local file system. Instead, you have to use the subcommand
`install` to stage the output to your local file system.

```sh
$ must install simple_greeter -o .
INFO: Requested target is [["@","","","simple_greeter"],{}]
INFO: Discovered 1 actions, 0 trees, 0 blobs
INFO: Processed 1 actions, 1 cache hits.
INFO: Artifacts can be found in:
        ./out.txt [557db03de997c86a4a028e1ebd3a1ceb225be238:12:f]
$ cat ./out.txt
Hello World
```

If you just want to see the generated output without installing it, you can also
use the `-P` option after the subcommand `build`.

```sh
$ must build simple_greeter -P out.txt
INFO: Requested target is [["@","","","simple_greeter"],{}]
INFO: Discovered 1 actions, 0 trees, 0 blobs
INFO: Processed 1 actions, 1 cache hits.
INFO: Artifacts built, logical paths are:
        out.txt [557db03de997c86a4a028e1ebd3a1ceb225be238:12:f]
Hello World
```

### File Greeter

The `file_greeter` reads the string that will be used for greeting from the
local file [name.txt](./name.txt). This time, two commands were used to compute
the output. For convenience, a *Jsonnet multi-line string* (operator `|||`) is
used in combination with the [function `lines()`](../../doc/must-lang.md#lines),
which converts multi-line strings to string lists.

```jsonnet
file_greeter: {
  type: 'generic',
  // Field 'cmds' expects list of strings, the commands.
  // -> Function 'lines()' generates list of strings from multi-line string.
  cmds: lines(|||
    printf "Hello " > out.txt
    cat name.txt >> out.txt
  |||),
  outs: ['out.txt'],
  deps: ['name.txt'],
},
```

To build this greeter and see its output, run:

```sh
$ must build file_greeter -P out.txt
INFO: Requested target is [["@","","","file_greeter"],{}]
INFO: Discovered 1 actions, 0 trees, 0 blobs
INFO: Processed 1 actions, 0 cache hits.
INFO: Artifacts built, logical paths are:
        out.txt [34c97eeca89eb286aed798efd885da6ea77e9a96:13:f]
Hello Galaxy
```

### Input Greeter

The `input_greeter` runs similar commands to the previous one. The major
difference is that the file `input.txt` is *not* a local file, but instead the
output of the depending target `input.txt`.

```jsonnet
input_greeter: {
  type: 'generic',
  cmds: lines(|||
    printf "Hello " > out.txt
    cat input.txt >> out.txt
  |||),
  outs: ['out.txt'],
  // Dependency 'input.txt' is a target (see below), not a file!
  deps: ['input.txt'],
},
```

> Note that instead of depending on another target, you can also explicitly
> depend on a local file `input.txt` (if it exists) by using the [explicit
> `file()` reference](../../doc/must-lang.md#file) (e.g., `file('input.txt')`).

To build this greeter and see its output, run:

```sh
$ must build input_greeter -P out.txt
INFO: Requested target is [["@","","","input_greeter"],{}]
INFO: Discovered 1 actions, 0 trees, 1 blobs
INFO: Processed 1 actions, 0 cache hits.
INFO: Artifacts built, logical paths are:
        out.txt [a17dcb5259599be90a546576d571d2afcb66e37b:15:f]
Hello Universe
```

## File-gen targets

File-gen targets use the [built-in
rule
`file_gen`](https://github.com/just-buildsystem/justbuild/blob/master/doc/concepts/built-in-rules.md#file_gen)
to generate files.

Lets have a look at the file-gen target `input.txt` defined in
[`TARGETS`](./TARGETS). It generates the file `input.txt` from the string
specified in `data`. The value
for `data` is read from the variable `INPUT_STRING`, which defaults to string
`"Universe\n"` if not set (see [expression
`var()`](../../doc/must-lang.md#var)).

```jsonnet
'input.txt': {
  type: 'file_gen',
  // We want to read variable 'INPUT_STRING'.
  arguments_config: ['INPUT_STRING'],
  name: 'input.txt',
  // Use content of variable 'INPUT_STRING' if set, or else use 'Universe\n'
  data: var('INPUT_STRING', default='Universe\n'),
},
```

Using the variable `INPUT_STRING`, a caller can specify a string to use for the
greeting on the command line via the `-D` option:

```sh
$ must build input_greeter -P out.txt -D'{"INPUT_STRING":"Mustbuild\n"}'
INFO: Requested target is [["@","","","input_greeter"],{"INPUT_STRING":"Mustbuild\n"}]
INFO: Discovered 1 actions, 0 trees, 1 blobs
INFO: Processed 1 actions, 0 cache hits.
INFO: Artifacts built, logical paths are:
        out.txt [b874bf2dd8d4c5bde51c7bda3b02a4a401458771:16:f]
Hello Mustbuild
```

> Alternatively, configuration variables can also be specified as a JSON file
> via the option `--config`.

## Install targets

Last, we would like to show the [built-in rule
`install`](https://github.com/just-buildsystem/justbuild/blob/master/doc/concepts/built-in-rules.md#install).
It allows the flexible restaging (renaming/restructuring) of artifacts.

For example, what if we want to install the outputs of all greeters at once? It
would lead to a conflict, as all of them produce an output file with the same
name `out.txt`. In such scenarios, the following `install` target can be used to
restage and combine the outputs of all greeters.

```jsonnet
ALL: {
  type: 'install',
  files: {
    'out/simple.txt': 'simple_greeter',
    'out/file.txt': 'file_greeter',
    'out/input.txt': 'input_greeter',
  },
},
```

To build this target and produce all outputs, run:

```sh
$ must build ALL
INFO: Requested target is [["@","","","ALL"],{}]
INFO: Discovered 3 actions, 0 trees, 1 blobs
INFO: Processed 3 actions, 3 cache hits.
INFO: Artifacts built, logical paths are:
        out/file.txt [34c97eeca89eb286aed798efd885da6ea77e9a96:13:f]
        out/input.txt [a17dcb5259599be90a546576d571d2afcb66e37b:15:f]
        out/simple.txt [557db03de997c86a4a028e1ebd3a1ceb225be238:12:f]
```
