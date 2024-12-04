---
title: Assembling Regular Expressions
weight: 15
disableToc: false
chapter: false
---

> The CRS team uses a custom specification format to specify how a regular expression is to be generated from its components. This format enables reuse across different files, explanation of choices and techniques with comments, and specialized processing.

## Specification Format

The files containing regular expression specifications (`.ra` suffix, under `regex-assembly`) contain one regular expression per line. These files are meant to be processed by the [crs-toolchain]({{% ref "crs_toolchain" %}}).

### Example

The following is an example of what an assembly file might contain:

```
##! This line is a comment and will be ignored. The next line is empty and will also be ignored.

##! The next line sets the *ignore case* flag on the resulting expression:
##!+ i

##! The next line is the prefix comment. The assembled expression will be prefixed with its contents:
##!^ \b

##! The next line is the suffix comment. The assembled expression will be suffixed with its contents:
##!$ \W*\(

##! The following two lines are regular expressions that will be assembled:
--a--
__b__

##! Another comment, followed by another regular expression:
^#!/bin/bash
```

This assembly file would produce the following assembled expression: `(?i)\b(?:--a--|__b__|^#!/bin/bash)[^0-9A-Z_a-z]*\(`

### Comments

Lines starting with `##!` are considered comments and will be skipped. Use comments to explain the purpose of a particular regular expression, its use cases, origin, shortcomings, etc. Having more information recorded about individual expressions will allow developers to better understand changes or change requirements, such as when reviewing pull requests.

### Empty Lines

Empty lines, i.e., lines containing only white space, will be skipped. Empty lines can be used to improve readability, especially when adding comments.

### Flag Marker

A line starting with `##!+` can be used to specify global flags for the regular expression engine. The flags from all lines starting with the flag marker will be combined. The resulting expression will be prefixed with the flags. For example, the two lines

```
##!+ i
a+b|c
```

will produce the regular expression `(?i)a+b|c`.

The following flags are currently supported:
- `i`: ignore case; matches will be case-insensitive
- `s`: make `.` match newline (`\n`); this set by ModSecurity anyway and is included here for backward compatibility

### Prefix Marker

A line starting with `##!^` can be used to pass a global prefix to the script. The resulting expression will be prefixed with the literal contents of the line. Multiple prefix lines will be concatenated in order. For example, the lines

```
##!^ \d*\(
##!^ simpson
marge|homer
```

will produce the regular expression `[0-9]*\(simpson(?:marge|homer)`.

The prefix marker exists for convenience and improved readability. The same can be achieved with the [assemble processor](#assemble-processor).

### Suffix Marker

A line starting with `##!$` can be used to pass a suffix to the script. The resulting expression will be suffixed with the literal contents of the line. Multiple suffix lines will be concatenated in order. For example, the lines

```
##!$ \d*\(
##!$ simpson
marge|homer
```

will produce the regular expression `(?:marge|homer)[0-9]*\(simpson`.

The suffix marker exists for convenience and improved readability. The same can be achieved with the [assemble processor](#assemble-processor).

### Processor Marker

A line starting with `##!>` is a processor directive. The processor marker can be used to preprocess a block of lines.

A line starting with `##!<` marks the end of the most recent processor block.

Processor markers have the following general format: `<marker> <processor name> [<processor arguments>]`. For example: `##!> cmdline unix`. The arguments depend on the processor and may be empty.

The following example is intentionanlly simple (and meaningless) to illustrates the use of the markers without adding additionally confusing pieces. Please refer to the following sections for more concrete and useful examples.

```python
##!> cmdline unix
  command1
  command2
  ##!> assemble
    nested1
    nested2
  ##!<
##!<
```

Processors are defined in the [crs-toolchain]({{% ref "crs_toolchain" %}}).

### Nesting

Processors may be nested. This enables complex scenarios, such as assembling a smaller expression to concatenate it with another line or block of lines. For example, the following will produce the regular expression `line1(?:ab|cd)`:

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

The command line evasion processor treats each line as a word (e.g., a shell command) that needs to be escaped.

Lines starting with a single quote `'` are treated as literals and will not be escaped.

The special token `@` will be replaced with an optional "word ending" regular expression. This can be used in the context of a shell to reduce the number of false positives for a word by requiring a subsequent token to be present. For example: `python@`.

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

The patterns that are used by the command line evasion processor are configurable. The default configuration for the CRS can be found in the `toolchain.yaml` in the `regex-assembly` directory of the [CRS project](https://github.com/coreruleset/coreruleset).

The following is an example of how the command line evasion processor can be used:

```python
##!> cmdline unix
  w@
  gcc~
  'python[23]
  aptitude@
  pacman@
##!<
```

## Assemble processor

Processor name: `assemble`

### Arguments

This processor does not accept any arguments.

### Output

Single line regular expression, where each line of the input is treated as an alternation of the regular expression. Input can also be stored or concatenated by using the two marker comments for input (`##!=<`) and output (`##!=>`).

### Description

Each line of the input is treated as an alternation of a regular expression, processed into a single line. The resulting regular expression is not optimized (in the strict sense) but is reduced (i.e., common elements may be put into character classes or groups). The ordering of alternations in the output can differ from the order in the file (ordering alternations by length is a simple performance optimization).

This processor can also store the output of a block delimited with the input marker `##!=<`, or produce the concatenation of blocks delimited with the output marker `##!=>`.

Lines within blocks delimited by input or output markers are treated as alternations, as usual. The input and output markers enable more complex scenarios, such as separating parts of the regular expression in the assembly file for improved readability. Rule 930100, for example, uses separate expressions for periods and slashes, since it's easier to reason about the differences when they are physically separated. The following example is based on rules from 930100:

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

The input marker `##!=<` takes an identifier as a parameter and associates the output of the preceding block with the identifier. No output is produced when using the input `##!=<` marker. To concatenate the output of a previously stored block, the appropriate identifier must be passed to the output marker `##!=>` as an argument. Stored blocks remain in storage until the end of the program and are available globally. Any input stored previously can be retrieved at any nesting level. Both of the following examples produce the output `ab`:

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
- Suffix replacements (optional): Any number of two-tuples, where the first entry is the suffix to match and the second entry is the replacement. To use, write `--` after the include file name. Tuples are space separated

### Output

The exact contents of the included file, including processor directives, with suffixes replaced where appropriate. The prefix and suffix markers are not allowed in included files.

### Description

The include processor reduces repetition across assembly files. Repeated blocks can be put into a file in the `include` directory and then be included with the `include` processor comment. Include files are normal assembly files, hence include files can also contain further include directives. The only restriction is that included files must not contain the prefix or suffix markers. This is a technical limitation in the [crs-toolchain]({{% ref "crs_toolchain" %}}).

The contents of an include file could, for example, be the alternation of accepted HTTP methods:

```python
POST
GET
HEAD
```

This could be included into an assembly file for a rule that adds an additional method:

```python
##!> include http-headers
OPTIONS
```

The resulting regular expression would be `(?:POS|GE)T|HEAD|OPTIONS`.

Additionally, definition directives of include files are available to the including file. This means that include files can be used as libraries of expressions. For example, an include file called `lib.ra` could contain the following definitions:

```python
##!> define quotes ['"`]
##!> define opt-lazy-wspace \s*?
```

These definitions could then be used in an including file as follows:

```python
##!> include lib

it{{quotes}}s{{opt-lazy-wspace}}possible
```  

Note that the include processor does not have a body, thus the end marker is optional.

Please see [Include-Except processor]({{% ref "regex_assembly#include-except-processor" %}}) for how suffix replacements work.

## Include-Except processor

Processor name: `include-except`

### Arguments

- Include file name (required): The name of the file to include, without suffix
- Exclude file names (required): One or more names of files to consult for exclusions, without suffix, space separated
- Suffix replacements (optional): Any number of two-tuples, where the first entry is the suffix to match and the second entry is the replacement. To use, end the list of exclude file names with `--`. Tuples are space separated

### Output

The contents of the included file as per the include processor, but with all matching lines from the exclude file removed. Suffixes will have been replaced as appropriate.

### Description

The include-except processor further improves reusability of include files by removing exact line matches found in any of the listed exclude files from the result. A use case for this scenario is remote command execution where it is desirable to have a single list of commands but where certain commands should be excluded from some rules to avoid false positives. Consider the following list of command words:

```python
cat
wget
who
zless
```

This list may be usable at paranoia level 2 or 3 but the words `cat` and `who` would produce too many false positives at paranoia level 1. To work around this issue, the following exclude file can be used:

```python
cat
who
```

The regular expression for a rule at paranoia level 1 would then be generated by the following:

```python
##!> include-except command-list pl1-exclude-list
```

The processor accepts more than one exclude file, each file name separated by a space.

Additionally, the processor can be instructed to replace suffixes of entries in the include file. The use case for this is primarily that we have word lists used together with the `cmdline` processor, where entries can be suffixed with `@` or `~`. The same lists can be used in other contexts but then the `cmdline` suffixes need to be replaced with a regular expression. The following is an example, where `@` will be replaced with `[\s<>]` and `~` with `[^\s]`:

```python
##!> include-except command-list pl1-exclude-list -- @ [\s<>] ~ [^\s]
```

`""` is the special literal used to represent the empty string in suffix replacements. In order to replace a suffix with the empty string one would write, for example:

```python
##!> include-except command-list pl1-exclude-list -- @ "" ~ ""
```

Suffix replacement is performed _after_ all exclusions have been removed, which means that entries in exclude files must target the _verbatim_ contents of the include file, i.e., `some entry@`, not `some entry[\s<>]`

Note that the include-exclude processor does not have a body, thus the end marker is optional.

## Development

We have a syntax highlight extension for Visual Studio Code that helps with writing assembly files. Instructions on how to install the extension can be found in the readme of the repository: https://github.com/coreruleset/regexp-assemble-syntax
