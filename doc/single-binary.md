# Single binary `must`

Mustbuild provides a single binary for all subcommands:

```sh
$ must --help
must, a generic multi-repository build tool.
Usage: must [OPTIONS] SUBCOMMAND

Subcommands:
  version         Print version information in JSON format of this tool.
  setup           Setup and generate configuration for the build tool
  setup-env       Setup without workspace root for the main repository.
  fetch           Fetch and store distribution files.
  update          Advance Git commit IDs and print updated must configuration.
  analyse         Analyse specified targets.
  build           Build specified targets.
  describe        Describe the rule generating a target.
  gc              Trigger garbage collection of local cache.
  install         Build and stage specified targets.
  install-cas     Fetch and stage artifact from CAS.
  preprocess      Preprocess Jsonnet file.
  rebuild         Rebuild and compare artifacts to cached build.
  traverse        Build and stage artifacts from graph file.
```

## Full flexibility for advanced users

Whenever `build` or `install` subcommands are run, the following process will
be initiated behind the scenes:

         repos.json
    (multi-repo config)                    ─┐
             │                              │
             │  ┌───────────┐ fetch         │
             ├─>│   fetch   │ distfiles     │
             │  └─────┬─────┘               │
             │        │                     │
             │        │                     ├─ frontend
             │        ▼                     │
             │  ┌───────────┐ import        │
             └─>│   setup   │ to CAS        │
                └─────┬─────┘               │
                      │                     │
                      │                    ─┘
                      │ (backend config)
                      │                    ─┐
                      ▼                     │
                ┌───────────┐ analyse       │
                │  analyse  │ TARGETS       │
                └─────┬─────┘               │
                      │                     │
                      │ (action graph)      ├─ backend
                      ▼                     │
                ┌───────────┐ run           │
                │ traverse  │ ACTIONS       │
                └─────┬─────┘               │
                      │ install             │
                      │                    ─┘
                      ▼
               built artifacts

Advanced users might have good reasons to run these steps separately. Although,
the frontend and backend are now provided as a single binary, these steps can
still be run individually.

### Fetch

The subcommand `fetch` reads the provided `repos.json` and ensures that all
distfiles required to build targets from `<repo>` are downloaded and made
locally available (by default in `~/.distfiles`).

```sh
$ must fetch <repo>
INFO: Found XX archives to fetch
INFO: Fetch completed
```

### Setup

Running `setup` will lookup distfiles (runs `fetch` for missing ones), unpacks
them, adds their content to the local CAS, and generate the Mustbuild backend
configuration (see `man must-backend-config`).

```sh
$ must setup <repo> | xargs cat > backend_config.json
INFO: Found XX repositories to set up
INFO: Setup completed
```

### Analyse

Using the backend config, we can `analyse` the target graph and generate the
resulting action graph for the requested `<target>`. Furthermore, the
serialization of the artifacts produced by the requested target are also dumped.
The format of the action graph file and the artifact serialization are
documented in the man page (see `man must-graph-file`).

```sh
$ must analyse <target> -C backend_config.json \
    --dump-graph graph.json \
    --dump-artifacts-to-build artifacts.json
INFO: Requested target is [["@","<repo>","","<target>"],{}]
INFO: Discovered X actions, Y trees, Z blobs
INFO: Dumping action graph to file graph.json.
```

The result of the analysis are the these two files:

- graph.json: the action graph, serialized to JSON
- artifacts.json: description of target's output artifacts in the action graph

### Traverse

Finally, with the action graph file and the serialization of the requested
artifacts (there are no targets anymore at this point), we can now `traverse`
the graph and run every action to build and retrieve the final outputs.
Note that this step is internally used by `build` and `install`, and therefore
also supports all build-related options (e.g., number of jobs, remote execution
address and properties, etc.).

```sh
$ must traverse -C backend_config.json \
  --graph-file graph.json \
  --artifacts "$(cat artifacts.json)" \
  -o .
INFO: Artifacts can be found in:
        ...
```



