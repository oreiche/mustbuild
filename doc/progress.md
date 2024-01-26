# Interactive progress reporting

The new interactive progress reporting gives better insights about which targets
are currently being built in parallel and how long those actions are running.

Furthermore, the inaccurate percentage reporting was dropped. The problem with
percentage reporting is that it neither reflects build times accurately (due to
long-running actions) nor is it guaranteed to ever reach 100% (which would
require two passes). Therefore, the impractical percentage was replaced by a
more favorable plain action counter.

```jsonc
$ must build must
INFO: Found 37 repositories to set up
INFO: Requested target is [["@","must","",""],{}]
INFO: Discovered 3182 actions, 502 trees, 22 blobs
#0: ["@","must","src/other_tools/git_operations","git_operations"]#0
#1: ["@","must","src/buildtool/main","build_utils"]#0
#2: ["@","must","src/buildtool/execution_api/remote","bazel_network"]#2
#3: ["@","must","src/buildtool/build_engine/analysed_target","target"]#0
#4: ["@","must","src/buildtool/serve_api/serve_service","target_service"]#0
#5: ["@","must","src/other_tools/root_maps","fpath_git_map"]#0
#6: ["@","must","src/other_tools/root_maps","content_git_map"]#0
#7: ["@","must","src/buildtool/execution_api/execution_service","capabilities_server"]#0
[2899/3182] 2880 cached, 8 processing.
```

You can always fallback to non-interactive progress by specifying `--plain-log`.
This option will also reduce the *progress interval* to 3000 milliseconds, which
might be desireable for environments that capture the progress (e.g., CI
pipelines). Users might also want to set a custom interval and a *progress
backoff factor* using the options `--prog-interval` and `--prog-backoff-factor`.
