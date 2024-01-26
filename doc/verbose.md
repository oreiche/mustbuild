# Reduced command line output

To reduce the amount of command line output, unnecessary prints have been
removed from the default log level.

```sh
$ must build helloworld
INFO: Found 10 repositories to set up
INFO: Requested target is [["@","example","","helloworld"],{}]
INFO: Discovered 4 actions, 2 trees, 0 blobs
INFO: Processed 4 actions, 0 cache hits.
INFO: Artifacts built, logical paths are:
        helloworld [c7034a4416cb34806e971bcc3d8c362f6bea5fda:18328:x]
```

Instead, all verbose non-debug output (including which action commands are run)
was moved to a new log level `LogLevel::Verbose`. This log level can be enabled
with `--log-limit 5`.

```sh
$ must --log-limit 5 build helloworld
INFO: Using setup root /home/user/src/mustbuild/examples/3_cpp_adv
INFO: Performing repositories setup
INFO: Found 6 repositories to set up
INFO: Setup finished, call ["must","build","-C","/home/user/.cache/just/protocol-dependent/generation-0/git-sha1/casf/57/209f50704f7fabf36c8584308708a577df052d","--log-limit","5","helloworld"]
INFO: Using workspace root /home/user/src/mustbuild/examples/3_cpp_adv
INFO: Requested target is [["@","example","","helloworld"],{}]
PERF: Export target ["@","example","","helloworld"] is not eligible for target caching
PERF: Export target ["@","example","","libgreet"] is not eligible for target caching
INFO: Analysed target [["@","example","","helloworld"],{}]
INFO: Export targets found: 0 cached, 0 uncached, 2 not eligible for caching
INFO: Discovered 4 actions, 2 trees, 0 blobs
INFO: Building [["@","example","","helloworld"],{}].
INFO(action:daf06cead3ff3f3ceadd7a21d2d97769497fef6b): 
    ["c++","-O2","-DNDEBUG","-std=c++14","-Wall","-Werror","-pedantic","-I","work","-isystem","include","-c","work/greet/greet.cpp","-o","work/greet/greet.o"]
INFO(action:ff0af5c04d2821ac761e4eaeb4f0d42e9234a79d): 
    ["c++","-O2","-DNDEBUG","-std=c++14","-Wall","-Werror","-pedantic","-I","work","-isystem","include","-c","work/helloworld.cpp","-o","work/helloworld.o"]
INFO(action:66c19448268b6a329799668a05b4ed06ec52d39f): 
    ["ar","cqs","greet/libgreet.a","greet/greet.o"]
INFO(action:1c0ab626cb6a1eeb45ac522f16f5bc480459b8d2): 
    ["c++","-Wl,-rpath,$ORIGIN","-Wl,-rpath,$ORIGIN/../lib","-o","helloworld","-O2","-DNDEBUG","-std=c++14","-Wall","-Werror","-pedantic","helloworld.o","greet/libgreet.a"]
INFO: Processed 4 actions, 4 cache hits.
INFO: Artifacts built, logical paths are:
        helloworld [6206cbbf664842570f9c503916569e548e8a6225:19088:x]
```