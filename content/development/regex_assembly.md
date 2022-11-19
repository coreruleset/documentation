---
title: Regular Expression Assembly
weight: 15
disableToc: false
chapter: false
---

> The CRS team uses a custom specification format to specify how a regular expression is to be generated from its components. This format enables reuse across different files, explanation of choices and techniques with comments and specialized processing.

## Specification Format

The files containing regular expression specifications (`.data` suffix, under `data`) contain one regular expression per line. These files are meant to be processed by the [crs-toolchain]({{< ref "crs_toolchain" >}}).

### Example

The following is an example of what a data file might contain:

```
##! This line is a comment and will be ignored. The next line is empty and will also be ignored.

##! The next line sets the *ignore case* flag on the resulting expression:
##!+ i

##! The next line is the prefix comment. The assembled expression will be prefixed with its contents:
##!^ \b

##! The next line is the suffix comment. The assembled expression will be suffixed with its contents:
##!$ \W*(

##! The following two lines are regular expressions that will be assembled:
--a--
__b__

##! Another comment, followed by another regular expression:
^#!/bin/bash
```

This data file would produce the following assembled expression: `(?i)\b(?:^#!\/bin\/bash|--a--|__b__)\W*(`

### Comments

Lines starting with `##!` are considered comments and will be skipped. Use comments to explain the purpose of a particular regular expression, its use cases, origin, shortcomings, etc. Having more information recorded about individual expressions will allow developers to better understand changes or change requirements, such as when reviewing pull requests.

### Empty Lines

Empty lines, i.e., lines containing only white space, will be skipped. Empty lines can be used to improve readability, especially when adding comments.

### Flag Marker

A line starting with `##!+` can be used to pass global flags to the script. The last found flag comment line overwrites all previous flag comment lines. The resulting expression will be prefixed with the flags. For example, the two lines

```
##!+ i
a+b|c
```

will produce the regular expression `(?i)a+b|c`.

Only the ignore case flag `i` is currently supported.

### Prefix Marker

A line starting with `##!^` can be used to pass a global prefix to the script. The resulting expression will be prefixed with the literal contents of the line. Multiple prefix lines will be concatenated in order. For example, the lines

```
##!^ \W*\(
##!^ two
a+b|c
d
```

will produce the regular expression `\W*\(two(?:a+b|c|d)`.

The prefix marker exists for convenience and improved readability. The same can be achieved with the [assemble processor](#assemble-processor).

### Suffix Marker

A line starting with `##!$` can be used to pass a suffix to the script. The last found suffix comment line overwrites all previous suffix comment lines. The resulting expression will be suffixed with the literal contents of the line. For example, the two lines

```
##!$ \W*\(
##!$ two
a+b|c
d
```

will produce the regular expression `(?:a+b|c|d)\W*\(two`.

The suffix marker exists for convenience and improved readability. The same can be achieved with the [assemble processor](#assemble-processor).

### Processor Marker

A line starting with `##!>` is a processor directive. The processor marker can be used to preprocess a block of lines.

A line starting with `##!<` marks the end of the most recent processor.

Processor markers have the following general format: `<marker> <processor name>[<processor arguments>]`. For example: `##!> cmdline unix`. The arguments depend on the processor and may be empty.

Processors are defined in the [crs-toolchain]({{< ref "crs_toolchain" >}}).

### Nesting

processors may be nested. This enables complex scenarios, such as assembling a smaller expression to concatenate it with another line or block of lines. For example:

```python
##!> assemble
line1
##!=>
  ##!> assemble
ab
cd
  ##!<
##!<
```

There is no practical limit to the nesting depth.

Each processor block must be terminated with the end marker `##!<`, except for the outermost (default) block, where the end marker is optional.

## Command Line Evasion processor

Processor name: `cmdline`

### Arguments

`unix|windows` (required): The processor argument determines the escaping strategy used for the regular expression. Currently, the two supported strategies are Windows cmd (`windows`) and "unix like" terminal (`unix`).

### Output

One line per line of input, escaped for the specified environment.

### Description

The command line evasion processor processes the entire file. Each line is treated as a word (e.g. shell command) that needs to be escaped.

Lines starting with a single quote `'` are treated as literals and will not be escaped.

The special token `@` will be replaced with the expression `(?:\s|<|>).*` in `unix` mode and `(?:[\s,;]|\.|/|<|>).*` in `windows` mode. This can be used in the context of a shell to reduce the number of of false positives for a word by requiring a subsequent token to be present. For example: `diff@`.

`@` will match:
- `python<<<'print("hello")'`
- `python <<< 'print("hello")'`

`@` will _not_ match:
- `python3<<<'print("hello")'`
- `python3 <<< 'print("hello")'`

The special token `~` acts like `@` but does not allow any white space tokens to _immediately_ follow the preceding word. This is useful for adding common English words to word lists. For example, there are multiple executable names for "python", such as `python3` or `python3.8`. These could not be added with `python@`, as `python ` would be a valid match and create many false positives.

`~` will match:
- `python<<<'print("hello")'`
- `python3 <<< 'print("hello")'` 

`~` will _not_ match:
- `python <<< 'print("hello")'`

## Assemble processor

Processor name: `assemble`

### Arguments

This processor does not accept any arguments.

### Output

Single line regular expression, where each line of the input is treated as an alternation of the regular expression. Input can also be concatenated by using the two marker comments for input (`##!=<`) and output (`##!=>`).

### Description

Each line of the input is treated as an alternation of a regular expression, processed into a single line. The resulting regular expression is not optimized (in the strict sense) but is reduced (i.e., common elements may be put into character classes or groups). The ordering of alternations in the output can differ from the order in the file (ordering alternations by length is a simple performance optimization).

This processor can also produce the concatenation of blocks delimited with `##!=>`. It supports two special markers, one for output (`##!=>`) and one for input (`##!=<`).

Lines within blocks delimited by input or output markers are treated as alternations, as usual. The input and output markers enable more complex scenarios, such as separating parts of the regular expression in the data file for improved readability. Rule 930100, for example, uses separate expressions for periods and slashes, since it's easier to reason about the differences when they are physically separated. The following example is based on rules from 930100:

```python
##!> assemble
  ##! slash patterns
  \x5c
  ##! URI encoded
  %2f
  %5c
  ##!=>
  
  ##! dot patterns
  \.
  \.%00
  \.%01
##!<
```

The above would produce the following, concatenated regular expression:

```python
(?:\x5c|%(?:2f|5c))\.(?:%0[0-1])?
```

The input marker `##!=<` takes an identifier as a parameter and associates the associated block with the identifier. No output is produced when using the input `##!=<` marker. To concatenate the output of a previously stored block, the appropriate identifier must be passed to the output marker `##!=>` as an argument. Stored blocks remain in storage until the end of the program and are available globally. Any input stored previously can be retrieved at any nesting level. Both of the following examples produce the output `ab`:

```python
##!> assemble
  ab
  ##!=< myinput
  ##!> assemble
    ##!=> myinput
  ##!<
##!<
```

```python
##!> assemble
  ab
  ##!=< myinput
##!<
##!> assemble
  ##!=> myinput
##!<
```

Rule 930100 requires the following concatenation of rules: `<slash rules><dot rules><slash rules>`, where `slash rules` is concatenated twice. The following example produces this sequence by storing the expression for slashes with the identifier `slashes`, thus avoiding duplication:

```python
##!> assemble
  ##! slash patterns
  \x5c
  ##! URI encoded
  %2f
  %5c
  ##!=< slashes
  ##!=> slashes

  ##! dot patterns
  \.
  \.%00
  \.%01
  ##!=>
  ##!=> slashes
##!<
```

## Definition processor

Processor name: `define`

### Arguments

- Identifier (required): The name of the definition that will be processed by this processor
- Replacement (required): The string that replaces the definition identified by `identifier`

### Output

One line per line of input, with all definition strings replaced with the specified replacement.

### Description

The definition processor makes it easy to add recurring strings to expressions. This helps reduce maintenance when a definition needs to be updated. It also improves readability as definition strings provide readable and bounded information, where otherwise a regular expression must be read and boundaries must be identified.

The format of definition strings is as follows:

```
{{identifier}}
```

The definition string starts with two opening braces, is followed by an identifier, and ends with two closing braces. The identifier format must satisfy the following regular expression:

```python
[a-z-A-Z\d_-]+
```

An identifier must have at least one character and consist only of upper and lowercase letters a through z, digits 0 through 9, and underscore or dash.

The following example shows how to use the definition processor:

```python
##!> define slashes [/\x5c]
regex with {{slashes}}
```

This would result in the output `regex with [/\x5c]`.

## Include processor

Processor name: `include`

### Arguments

- Include file name (required): The name of the file to include, without suffix

### Output

The exact contents of the included file, including processor directives.

### Description

The include processor reduces repetition across data files. Repeated blocks can be put into a file in the `include` directory and then be included with the `include` processor comment. The contents of an include file could, for example, be the alternation of accepted HTTP headers:

```python
POST
GET
HEAD
```

This could be included into a data file for a rule that adds an additional method:

```python
##!> include http-headers
OPTIONS
```

The resulting regular expression would be `(?:POS|GE)T|HEAD|OPTIONS`.

Note that the include processor does not have a body, therefore the end marker is optional.
