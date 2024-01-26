# Minimal C++ Project

This minimal example C++ project uses the [C/C++ rule
set](https://github.com/just-buildsystem/rules-cc) for building a simple
`helloworld` binary. Including a rule set requires the project to set up a
[*multi-repository configuration*](#multi-repository-configuration), because the
rule set is imported as an *external repository*.

Key takeaways from this example:

1. Rule sets are imported as a [separate repository](#multi-repository-configuration)
2. [Targets](#mustbuild-target-description) refer to other repositories via open names
3. Building is done [out-of-source](#building-and-running-helloworld)

## Repository structure

A minimal C/C++ project requires at least three files:

1. C/C++ source file
2. `TARGETS` file defining the Mustbuild targets
3. [multi-repository
configuration](#multi-repository-configuration) for importing the C/C++ rule set

```
  2_cpp_min/          # Workspace root
  |
  ├── helloworld.cpp  # Application source
  ├── TARGETS         # Mustbuild top-level targets
  └── repos.json      # Mustbuild multi-repository configuration
```

## Multi-repository configuration

The multi-repository configuration [`repos.json`](./repos.json) contains two
repositories:

1. `example`: the helloworld example project
2. `rules-cc`: the C/C++ rule set, fetched via Git from GitHub

```json
{
  "main": "example",
  "repositories": {
    "example": {
      "repository": {"type": "file", "path": "."},
      "bindings": {
        "rules": "rules-cc"
      }
    },
    "rules-cc": {
      "repository": {
        "type": "git",
        "branch": "master",
        "commit": "2ea50063460a3e11dfcbb71651540c0d61fddc1a",
        "repository": "https://github.com/just-buildsystem/rules-cc",
        "subdir": "rules"
      }
    }
  }
}
```

The repository `example` includes `rules-cc` via `bindings`, mapping it to the
generic open name `rules`.

    ┌─────────────────┐ rules    ┌─────────────────┐
    │     example     |<─────────┤    rules-cc     |
    └─────────────────┘          └─────────────────┘

Open names are a way to refer to other repositories without using their actual
names. In this case, targets from `example` can refer to `rules-cc` via the
generic name `rules`.

## Mustbuild target description

The actual targets are described in the [`TARGETS`](./TARGETS) file. It contains
a single target `helloworld`, implemented using the rule
[`["CC","binary"]`](https://github.com/just-buildsystem/rules-cc#rule-cc-binary)
from repository `rules` (which is the open name for repository `rules-cc`).

```jsonnet
{
  // Target "helloworld"
  helloworld: {
    // Use rule ["CC", "binary"] from binding "rules"
    type: ref_ext('rules', 'CC', 'binary'),
    // Binary name: "helloworld"
    name: 'helloworld',
    // Source files
    srcs: ['helloworld.cpp'],
  },
}
```

## Building and running helloworld

To build the project, run `must build`. By default, Must will build the
lexicographical first target in the top-level `TARGETS` file. In this case, the
`helloworld` target.

```sh
$ must build
INFO: Found 2 repositories to set up
INFO: Requested target is [["@","example","","helloworld"],{}]
INFO: Discovered 2 actions, 1 trees, 0 blobs
INFO: Processed 2 actions, 0 cache hits.
INFO: Artifacts built, logical paths are:
        helloworld [1673e4d63deb6580f81fb57d8a5276abe2ae8bd3:16384:x]
```

Building the target will not pollute the source directory. In order to obtain
the binary for execution, you first need to `install` it to the desired output
directory. Note that there is no rebuild happening as all actions are served
from cache.

```sh
$ must install -o .
INFO: Found 2 repositories to set up
INFO: Requested target is [["@","example","","helloworld"],{}]
INFO: Discovered 2 actions, 1 trees, 0 blobs
INFO: Processed 2 actions, 2 cache hits.
INFO: Artifacts built, logical paths are:
        ./helloworld [1673e4d63deb6580f81fb57d8a5276abe2ae8bd3:16384:x]
$ ./helloworld
Hello World!
```
