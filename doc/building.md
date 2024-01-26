# How to Build

Mustbuild is maintained as a patch series. To build Mustbuild, you first need to
generate the sources by applying the [patches](../patches) to the specific
[Justbuild commit](./justbuild.commit).

## 1. Generate sources

You can generate the sources by running the script `generate_sources.sh`:

```sh
$ ./generate_sources.sh ./srcs
Fetching Justbuild archive to ~/.distfiles
Unpacking sources to ./srcs
Patching sources
SUCCESS
$ cd srcs   # step into the source directory for building
```

Alternatively, you can also check out the specific [Justbuild
commit](../justbuild.commit) and apply the [patches](../patches) manually.

## 2. Building using `must` or `just-mr`

Once the sources have been successfully generated, you can build Mustbuild with
`must`:

```sh
$ must install must -o ${DESTDIR}
```

... or with `just-mr`:

```sh
$ just-mr install must -o ${DESTDIR}
```

### Build options

Build options are specified via JSON objects, encoded as string arguments:

```sh
$ must install must -D'{"DEBUG":true}' -o ${DESTDIR}
```

For the full list of variables supported for building Mustbuild, please see
[Justbuild's build
variables](https://github.com/just-buildsystem/justbuild/blob/master/INSTALL.md#building-just-for-other-architectures).

### The `ALL` target

To obtain a full installation with auxiliary tools, man pages, and bash
completion files, use the target `ALL`.

```sh
$ must install ALL -o ${DESTDIR}
```

> Note that `pandoc` needs to be installed. You can set its execution
> environment by specifying variable `PANDOC_ENV` as a JSON object, e.g.,
> `-D'{"PANDOC_ENV":{"HOME":"/home/user"}}'`.

## 3. Bootstrapping `must`

In case you have neither `must` nor `just-mr` available, you need to bootstrap
`must` first:

```sh
$ ./bin/bootstrap.py ${SRCDIR} ${BUILDDIR}
```

### Bootstrap options

[Build options](#build-options) to the bootstrap process can be provided by
specifying them as a serialized JSON object assigned to the environment variable
`JUST_BUILD_CONF`:

```sh
$ JUST_BUILD_CONF='{"DEBUG":true}' ./bin/bootstrap.py ${SRCDIR} ${BUILDDIR}
```

The final target that should be built by the bootstrap process can be specified
using the variable `BOOTSTRAP_TARGET`. This is particularly useful to directly
bootstrap the [`ALL` target](#the-all-target) described above:

```sh
$ BOOTSTRAP_TARGET=ALL ./bin/bootstrap.py ${SRCDIR} ${BUILDDIR}
```

Additional variables used to achieve *package builds* (linking against system
libraries) are `PACKAGE`, `LOCALBASE`, and `NON_LOCAL_DEPS`. For more
information on how to use these variables, see [Justbuild's bootstrapping
documentation](https://github.com/just-buildsystem/justbuild/blob/master/INSTALL.md#bootstrapping-just).
