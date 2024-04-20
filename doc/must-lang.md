# Mustbuild Language Extensions

The language extensions use the [Mustbuild preprocessor](./preprocessor.md)
to generate JSON code that serves as a intermediate representation. This
intermediate representation is used by the Mustbuild backend and is also
identical to the [Justbuild expression
language](https://github.com/just-buildsystem/justbuild/blob/master/doc/concepts/expressions.md).

There are two important particularities inherited from Justbuild:

1. Literal maps `{}` are considered to be Justbuild expressions and
   therefore are not supported (unless explicitly stated otherwise). To
   create a map, please see the [`map()`](#map) utility function.
2. Every expression can be interpreted as a boolean for conditions. In that
   case, they are considered to be `true` if they do *not* evaluate to
   `null`, `false`, `0`, `''`, `[]`, or `{}`.

## Expressions

Every Mustbuild expression is implemented as a disjoint mapping to one or
more corresponding Justbuild expressions.

---

### `var`

Access value of variable.

`var`(`name`: *str*, `default`: *expr*) -> *expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `name`    | Name of the variable to read | None |
| `default` | (optional) Expression to use if variable is not set | `null` |

Example:
```jsonnet
// evaluates to value of variable 'a' or null if not set
var('a')
// evaluates to "foo" if variable 'a' is not set
var('a', default='foo')
```

---

### `let`

Sequentially set variables for use in specified expression.

`let`(`bindings`: *list[pair]*, `body`: *expr*) -> *expr*

Each *pair* is of the form [`var`: *str-expr*, `val`: *expr*].

| Argument | Description | Default value |
|-|:-|:-:|
| `bindings` | List of var-val pairs overlaying the environment | None |
| `body`     | Expression to evaluate in overlayed environment | None |

Example:
```jsonnet
// evaluates to "foobar"
let([ set('a', 'foo'),
      set('b', 'bar')
    ],
    join([var('a'), var('b')]))
```

> See also [`set()`](#set) and [`join()`](#join).

---

### `select`

Select expression depending on condition.

`select`(`cond`: *expr*, `pass`: *expr*, `fail`: *expr*) -> *expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `cond` | Expression for condition | None |
| `pass` | Expression to evaluate if `cond` succeeds | None |
| `fail` | (optional) Expression to evaluate if `cond` fails | `[]` |

Example:
```jsonnet
// evaluates to "pass" or "fail" (depending on variable 'a')
select(var('a'), 'pass', 'fail')
// evaluates to []
select(false, 'pass')
```

---

### `cond`

Sequentially evaluate conditions and select expression of the first
successful condition.

`cond`(`cond`: *list[pair]*, `default`: *expr*) -> *expr*

Each *pair* is of the form [`cond`: *expr*, `value`: *expr*], with
`cond` being interpreted as a boolean.

| Argument | Description | Default value |
|-|:-|:-:|
| `cond`    | List of cond-value pairs | None |
| `default` | (optional) Expression to evaluate if no condition succeeds | `[]` |

Example:
```jsonnet
// evaluates to "pass" (value of first successful condition)
cond([ [null, 'fail'],
       [true, 'pass'],
       [var('a'), 'unknown'],
     ],
     default='fallback')
```

---

### `case`

Select expression from cases.

`case`(`expr`: *expr*, `case`: *map | list[pair]*, `default`: *expr*) -> *expr*

If cases are specified as a literal map, only string cases can be matched.
If cases are specified as list of pairs, arbitrary expressions can be
matched as cases sequentially. Each *pair* is of the form [`comp`: *expr*,
`value`: *expr*].

| Argument | Description | Default value |
|-|:-|:-:|
| `expr`    | Expression to evaluate for comparison | None |
| `case`    | Map for string comparison or pairs for arbitrary comparison | None |
| `default` | (optional) Expression to evaluate if no comparision succeeds | `[]` |

Example:
```jsonnet
// evaluates to "pass" or "fail" (depending on variable 'a')
case(select(var('a'), 'yes', 'no'),
     { yes: 'pass',
       no: 'fail',
       maybe: 'unknown',
     },
     default='fallback')
// evaluates to "pass" or "fail" (depending on variable 'a')
case(select(var('a'), true, null),
     [ [true, 'pass'],
       [null, 'fail'],
       ['maybe', 'unknown'],
     ],
     default='fallback')
```

---

### `and`

Logical AND.

`and`(`conds`: *list-expr*) -> *bool-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `conds` | List of expressions or expression evaluating to list | None |

> Note that literal lists are subject to short-circuit evaluation.

Example:
```jsonnet
// evaluates to true or false (depending on varable 'a')
and([true, var('a')])
```

---

### `or`

Logical OR.

`or`(`conds`: *list-expr*) -> *bool-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `conds` | List of expressions or expression evaluating to list | None |

> Note that literal lists are subject to short-circuit evaluation.

Example:
```jsonnet
// evaluates to true or false (depending on varable 'a')
or([false, var('a')])
```

---

### `foreach`

Evaluate expression for each element in list.

`foreach`(`var`: *str*, `range`: *list-expr*, `body`: *expr*) -> *list-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `var`   | Literal string used as iteration variable name | None |
| `range` | Expression evaluating to list | None |
| `body`  | Expression to evaluate in each iteration | None |

Example:
```jsonnet
// evaluates to ["food","foot"]
foreach('x', ['d', 't'], join(['foo', var('x')]))
```

> See also [`join()`](#join).

---

### `foreach_map`

Evaluate expression for each field in map.

`foreach_map`(`var`: *str*, `var_val`: *str*, `range`: *map-expr*, `body`: *expr*) -> *list-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `var`     | Literal string used as iteration variable name for keys | None |
| `var_val` | Literal string used as iteration variable name for values | None |
| `range`   | Expression evaluating to map | None |
| `body`    | Expression to evaluate in each iteration | None |

Example:
```jsonnet
// evaluates to ["a:x","b:y"]
foreach_map('k', 'v', map({'a':'x','b':'y'})],
            join([var('k'), ':', var('v')]))
```

> See also [`map()`](#map) and [`join()`](#join).

---

### `foldl`

Sequentially evaluate expression for each element in list. The result of
each evaluation is assigned to an accumulation variable.

`foldl`(`var`: *str*, `var_acc`: *str*, `range`: *list-expr*, `start`: *expr*, `body`: *expr*) -> *expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `var`     | Literal string used as iteration variable name | None |
| `var_acc` | Literal string used as accumulation variable name | None |
| `range`   | Expression evaluating to list | None |
| `start`   | Expression to evaluate the accumulation start value | None |
| `body`    | Expression to evaluate the next accumulation value | None |

Example:
```jsonnet
// evaluates to "foobarbaz"
foldl('x', 'acc', ['bar', 'baz'],
      start='foo',
      body=join([var('acc'), var('x')]))
```

> See also [`join()`](#join).

---

### `nub_right`

Remove duplicates from list and retain only the right-most one.

`nub_right`(`list`: *list-expr*) -> *list-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `list` | List-expression to remove left-most duplicates from | None |

Example:
```jsonnet
// evaluates to ["foo","baz","bar"]
nub_right(['foo', 'bar', 'baz', 'bar', 'bar'])
```

---

### `basename`

Get basename from string.

`basename`(`path`: *str-expr*) -> *str-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `path` | String-expression to extract file name from | None |

Example:
```jsonnet
// evaluates to "bar.baz"
basename('foo/bar.baz')
```

---

### `keys`

Get keys from map as list.

`keys`(`map`: *map-expr*) -> *list-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `map` | Map-expression to read keys from | None |

Example:
```jsonnet
// evaluates to ["a","b"]
keys(map({a:'x',b:'y'}))
```

> See also [`map()`](#map).

---

### `values`

Get values from map as list.

`values`(`map`: *map-expr*) -> *list-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `map` | Map-expression to read values from | None |

Example:
```jsonnet
// evaluates to ["x","y"]
keys(map({a:'x',b:'y'}))
```

> See also [`map()`](#map).

---

### `range`

Generate range from length as number or string. String must be the decimal
representation of an integer.

`range`(`num`: *number | str-expr*) -> *list-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `num` | Number or string-expression to generate the range list from | None |

Example:
```jsonnet
// evaluates to ["0","1","2"]
range(3.0)
// evaluates to ["0","1","2"]
range("3")
```

---

### `map_env`

Generate map from variables.

`map_env`(`vars`: *list[str]*) -> *map-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `vars` | List of environment variable names to create a map from | None |

Example:
```jsonnet
// evaluates to {"a":"x","b":"y"}
let([ set('a', 'x'),
      set('b', 'y')
    ],
    map_env(['a', 'b']))
```

> See also [`let()`](#let).

---

### `map_enum`

Generate map with values from list. All keys are the decimal representation
of the position in the list, padded with leading zeros to length 10.

`map_enum`(`list`: *list-expr*) -> *map-expr*

| Argument | Description | Default value |
|-|:-|
| `list` | List-expression to generate the map from | None |

Example:
```jsonnet
// evaluates to {"0000000000":"a","0000000001":"b"}
map_enum(['a', 'b'])
```

---

### `map_set`

Generate map with keys from list. All values are set to `true`.

`map_set`(`keys`: *list-expr*) -> *map-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `keys` | List-expression with key names to generate the map from | None |

Example:
```jsonnet
// evaluates to {"a":true,"b":true}
map_set(['a', 'b'])
```

---

### `reverse`

Reverse list.

`reverse`(`list`: *list-expr*) -> *list-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `list` | List-expression to reverse | None |

Example:
```jsonnet
// evaluates to ["c","b","a"]
reverse(['a', 'b', 'c'])
```

---

### `flatten`

Concatenate lists.

`flatten`(`lists`: *list-expr*) -> *list-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `lists` | List-expression containing the lists to concatenate | None |

Example:
```jsonnet
// evaluates to ["a","b","c","d"]
flatten([ ['a', 'b'], ['c', 'd'] ])
```

---

### `map_union`

Combine maps with the union of their fields.

`map_union`(`maps`: *list-expr*, `disjoint`: *bool*) -> *list-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `lists`    | List-expression containing the maps to unify | None |
| `disjoint` | (optional) Bool indicating that maps should be disjoint | `false` |

Example:
```jsonnet
// evaluates to {"a":"x","b":"y"}
map_union([ map({a:'x'}), map({b:'y'} ])
// evaluation fails
map_union([ map({a:'x'}), map({a:'y'} ], disjoint=true)
```

> See also [`map()`](#map).

---

### `sum`

Compute sum from list of numbers.

`sum`(`nums`: *list-expr*) -> *num-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `nums` | List-expression containing numbers | None |

> Note that sum of the empty list is the neutral element `0`.

Example:
```jsonnet
// evaluates to 0
sum([])
// evaluates to 6
sum([4, 2])
```

---

### `prod`

Compute product from list of numbers.

`prod`(`nums`: *list-expr*) -> *num-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `nums` | List-expression containing numbers | None |

> Note that product of the empty list is the neutral element `1`.

Example:
```jsonnet
// evaluates to 1
prod([])
// evaluates to 8
prod([4, 2])
```

---

### `join_cmd`

Join strings with shell quoting (POSIX shell can decode original list).

`join_cmd`(`args`: *list-expr*) -> *str-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `args` | List-expression containing the command arguments to join | None |

Example:
```jsonnet
// evaluates to "'echo' 'foo' ''\''bar'\'' baz'"
join_cmd(['echo' 'foo', "'bar' baz"])
```

---

### `json_encode`

Serialize JSON to string.

`json_encode`(`data`: *expr*) -> *str-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `data` | Expression containing the command arguments to join | None |

Example:
```jsonnet
// evaluates to "[\"foo\",\"bar\"]"
json_encode(['foo','bar'])
```

---

### `change_ending`

Change extension of a filename component.

`change_ending`(`path`: *str-expr*, `ending`: *str-expr*) -> *str-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `path`   | String-expression of which to change the ending | None |
| `ending` | String-expression specifying the new ending | None |

Example:
```jsonnet
// evaluates to "src/main.o"
change_ending('src/main.c', '.o')
```

---

### `join`

Join strings with optional separator.

`join`(`strings`: *list-expr*, `sep`: *str-expr*) -> *str-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `strings` | List-expression containing strings to concatenate | None |
| `sep`     | (optional) String-expression used as concatenation separator | `''` |

Example:
```jsonnet
// evaluates to "foo,bar"
join(['foo', 'bar'], ',')
```

---

### `escape_chars`

Escape charaters from string.

`escape_chars`(`string`: *str-expr*, `chars`: *list-expr*, `escape`: *str-expr*) -> *str-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `string` | String-expression specifying the input string | None |
| `chars`  | List-expression specifying the characters to escape | None |
| `escape` | (optional) String-expression specifying the escape character | None |

Example:
```jsonnet
// evaluates to ",foo,bar"
escape_chars('foobar', ['f', 'b'], ',')
```

---

### `to_subdir`

Interpret keys of map as paths and change their prefix.

`to_subdir`(`map`: *map-expr*, `subdir`: *str-expr*, `flat`: *expr*, `msg`: *expr*) -> *map-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `map`    | Map-expression containin the keys to modify | None |
| `subdir` | String-expression specifying the path prefixed to keys | None |
| `flat`   | (optional) Expression boolean foring replacement keys' dirname | `false` |
| `msg`    | (optional) Expression stringified as error message on conflict | `null` |

Example:
```jsonnet
// evaluates to {"sub/a/b":"xy"}
to_subdir(map({'a/b':'xy'}), 'sub')
// evaluates to {"sub/b":"xy"}
to_subdir(map({'a/b':'xy'}), 'sub', flat=true, msg='conflict error')
```

> See also [`map()`](#map).

---

### `eq`

Compare expressions for equality.

`eq`(`lhs`: *expr*, `rhs`: *expr*) -> *bool-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `lhs` | Left-hand side expression of comparison | None |
| `rhs` | Right-hand side expression of comparison | None |

Example:
```jsonnet
// evaluates to true if variable 'a' is not set
eq(var('a'), null)
```

---

### `empty_map`

Generates an empty map. See also [`map()`](#map).

`empty_map`() -> *map-expr*

Example:
```jsonnet
// evaluates to {}
empty_map()
```

---

### `singleton_map`

Generates a map from key and value. See also [`map()`](#map).

`singleton_map`(`key`: *str-expr*, `value`: *expr*) -> *map-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `key`   | String-expression used as key to create map from | None |
| `value` | String-expression used as value to create map from | None |

Example:
```jsonnet
// evaluates to {"foo":"bar"}
singleton_map('foo', 'bar')
```

---

### `lookup`

Lookup value of key in map.

`lookup`(`key`: *str-expr*, `map`: *map-expr*, `default`: *expr*) -> *expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `key`     | String-expression used as key for lookup | None |
| `map`     | Map-expression to lookup the value from at key | None |
| `default` | (optional) Expression returned if key is not found | `null` |

Example:
```jsonnet
// evaluates to "x"
lookup('a', map({a:'x', b:'y'}))
// evaluates to "z"
lookup('c', map({a:'x', b:'y'}), default='z')
```

> See also [`map()`](#map).

---

### `at`

Access value at index in list.

`at`(`index`: *num-expr | str-expr*, `list`: *list-expr*, `default`: *expr*) -> *expr*

String indices will be interpreted as integers and numbers will be rounded
to the nearest integer. Negative indicies count from the end of the list.

| Argument | Description | Default value |
|-|:-|:-:|
| `index`   | Number or string-expression used as list index | None |
| `list`    | List-expression to access the value from at index | None |
| `default` | (optional) Expression returned if index is out of bounds | `null` |

Example:
```jsonnet
// evaluates to "x"
at('0', ['x', 'y'])
// evaluates to "y"
at(-1, ['x', 'y'])
// evaluates to "z"
at(2, ['x', 'y'], default='z')
```

---

### `fail`

Trigger evaluation failure with error message.

`fail`(`msg`: *expr*) -> *expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `msg` | Expression stringified as error message | None |

Example:
```jsonnet
// evaluation fails with specified 'error message'
fail('error message')
```

---

### `context`

Provide error message in case the evaluation of any sub-expression fails.

`context`(`msg`: *expr*, `expr`: *expr*) -> *expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `msg`  | Expression stringified as error message | None |
| `expr` | Expression to evaluate in context | None |

Example:
```jsonnet
// evaluation fails with specified 'error message'
context('error message', fail('force failure'))
```

---

### `assert_non_empty`

Trigger evaluation failure if expression evaluates to empty string, map, or
list.

`assert_non_empty`(`msg`: *expr*, `arg`: *expr*) -> *expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `msg` | Expression stringified as error message | None |
| `arg` | Expression that should evaluate to non-empty string, map, or list | None |

Example:
```jsonnet
// evaluation fails with specified 'error message'
assert_non_empty('error message', '')
```

## Utility functions

Additional functions that make the developer's life easier but do not have a
direct counter-part in the Justbuild expression language.

---

### `not`

Negate boolean expression.

`not`(`cond`: *expr*) -> *bool-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `cond` | Expression to negate its boolean value | None |

Example:
```jsonnet
// evaluates to true
not(null)
```

---

### `neq`

Negated [`eq()`](#eq) expression.

`neq`(`lhs`: *expr*, `rhs`: *expr*) -> *bool-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `lhs` | Left-hand side expression of comparison | None |
| `rhs` | Right-hand side expression of comparison | None |

Example:
```jsonnet
// evaluates to true if variable 'a' is set
neq(var('a'), null)
```

---

### `nand`

Negated [`and()`](#and) expression.

`nand`(`conds`: *list[expr] | expr*) -> *bool-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `conds` | List of expressions or expression evaluating to list | None |

Example:
```jsonnet
// evaluates to true if variable 'a' is not set
nand([true, var('a')])
```

---

### `nor`

Negated [`or()`](#or) expression.

`nor`(`conds`: *list[expr] | expr*) -> *bool-expr*

| Argument | Description | Default value |
|-|:-|:-:|
| `conds` | List of expressions or expression evaluating to list | None |

Example:
```jsonnet
// evaluates to true if variable 'a' is not set
nor([false, var('a')])
```

---

### `lines`

Generates a list of strings from newline-separated lines in string literal.
Note that the last trailing newline will be removed before list generation.

`lines`(`data`: *str*) -> *list[str]*

| Argument | Description | Default value |
|-|:-|:-:|
| `data` | String literal that may contain newlines | None |

Example:
```jsonnet
// expands to ["foo"]
lines('foo')
// expands to ["foo","bar"]
lines('foo\\nbar')
// expands to ["foo","  bar"]
lines(|||
  foo
    bar
|||)
```

---

### `map`

Generate map from literal map or list of key value pairs.

`map`(`data`: *list[pair] | map*, `disjoint`: *bool*) -> *map-expr*

Generates a map-expression from list from key-value pairs or literal map.
Each *pair* is of the form [`key`: *str-expr*, `value`: *expr*] with the
first element being a string-expression.

| Argument | Description | Default value |
|-|:-|:-:|
| `data`     | (optional) List of pairs or literal map to create map-expression | `{}` |
| `disjoint` | (optional) Bool indicating that data should be disjoint | `false` |

Example:
```jsonnet
// evaluates to {}
map()
// evaluates to {"a":"x","b":"y"}
map({a:'x',b:'y'})
// evaluates to {"a":"x","b":"y"}
map([ ['a','x'], ['b','y'] ])
```

## Aliases

Alias functions for providing a meaningful name to special syntactical
constructs.

---

### `file`

Alias for explicitly referencing a source-file target.

`file`(`path`: *str*) -> *target-ref*

Expands to `["FILE", null, path]`.

---

### `link`

Alias for explicitly referencing a symlink target.

`link`(`path`: *str*) -> *target-ref*

Expands to `["SYMLINK", null, path]`.

---

### `tree`

Alias for explicitly referencing a tree target.

`tree`(`path`: *str*) -> *target-ref*

Expands to `["TREE", null, path]`.

---

### `glob`

Alias for referencing a collection of source files.

`glob`(`pattern`: *str*) -> *target-ref*

Expands to `["GLOB", null, pattern]`.

---

### `ref`

Alias for referencing a generic entity (target, rule, expression) in the
local repository.

`ref`(`module`: *str*, `target`: *str*) -> *ref*

Expands to `[module, target]`.

---

### `ref_rel`

Alias for referencing a generic enity (target, rule, expression) relative to
the current module in the local repository.

`ref_rel`(`submodule`: *str*, `target`: *str*) -> *ref*

Expands to `["./", submodule, target]`.

---

### `ref_ext`

Alias for referencing a target from an external repository.

`ref_ext`(`repo`: *str*, `module`: *str*, `target`: *str*) -> *ref*

Expands to `[repo, module, target]`.

---

### `set`

Alias for creating a var-val pair.

`set`(`var`: *string-expr*, `val`: *expr*) -> *pair*

Pairs are of the form [`var`: *str-expr*, `val`: *expr*].

## User-defined variables and functions

All functions are available in the global namespace. To avoid conflicts with
existing (and possible upcoming) built-in functions, all user-defined
variables and functions should be prefixed with `_`:

```jsonnet
local _foo = 'variable foo';
local _bar(s) = 'function _bar called with s=' + s;

{
  output: [_foo, _bar('hello world')]
}
```

