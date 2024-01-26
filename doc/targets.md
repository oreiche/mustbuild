# Improved target descriptions

Even with the [syntax improvements of the preprocessor](./preprocessor.md),
target descriptions are still a little rough. Mustbuild tries to address that
issue with several minor improvements.

## Support for single string and boolean fields

When writing `TARGETS` files, two types of fields are supported:

1. **target fields:** a list of target references (e.g., `ref(...)`)
2. **string/config fields:** a list of strings

String and config fields are sometimes used to specify only a *single string*
or a *single boolean* ([interpreting lists as
boolean](https://github.com/just-buildsystem/justbuild/blob/bda3dabe37fdde648f90ce5aa4b20d7336570cf0/doc/concepts/expressions.md#truth)).
In Mustbuild, the user is not required to provide string lists for string and
config fields anymore. Instead, the user can directly use:

- *single strings*
- *single booleans*

Using this extension, the following code is a valid target description:

```jsonnet
{
  libgreet: {
    type: ref_ext('rules', 'CC', 'library'),
    name: 'greet',  // single string (expands to singleton string list)
    shared: true,   // single boolean (expands to empty/non-empty string list)
    // ...
  },
}
```

## Reduced code duplication for `export` targets

[Export
targets](https://github.com/just-buildsystem/justbuild/blob/master/doc/concepts/built-in-rules.md#export)
should always document the `flexible_variables`, the set of variables forwarded
to all sub-targets, so that the user knows which variables are supported and
what their meaning is. In Mustbuild, documentation can now be provided part of
the same field, instead of duplicating the variable names in field `config_doc`:

```jsonnet
{
  libgreet: {
    type: 'export',
    // flexible_config can be a literal map containing documentation
    flexible_config: {
      'DEBUG': ['Build in debug mode'],
      'BUILD_SHARED': ['Build shared libraries'],
    },
    target: 'greet',
  },
}
```

Of course, the user is still free to use `flexible_config` and `config_doc`
separately.
