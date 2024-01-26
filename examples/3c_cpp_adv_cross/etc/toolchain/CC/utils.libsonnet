// User-defined utility functions
{
  // Helper function for key lookup from map
  get(key, map_var, default):: lookup(key, var(map_var, map()), default),

  // Helper function for computing cross prefix: '<arch>-<os>-<suffix>'
  // Example:
  //   x86 + linux -> 'i686-linux-gnu'
  //   arm + linux -> 'arm-linux-gnueabi'
  cross_prefix(arch_var, os_var, defaults)::
    let(
      [  // set defaults for ARCH and OS
        set('ARCH', var(arch_var, default=defaults.arch)),
        set('OS', var(os_var, default=defaults.os)),
      ],
      join(  // join cross prefix
        [  // <arch>
          case(var('ARCH'),
               { x86: 'i686', x86_64: 'x86_64', arm: 'arm', arm64: 'aarch64' },
               default=fail('unsupported architecture')),
          // <os>
          var('OS'),
          // <suffix>
          select(eq(var('ARCH'), 'arm'), 'gnueabi', 'gnu'),
        ],
        sep='-'
      )
    ),
}
