---
title: crs-toolchain
weight: 12
disableToc: false
chapter: false
---

> The crs-toolchain is the utility belt of CRS developers. It provides a single point of entry and a consistent interface for a range of different tools. Its core functionality (owed to the great [rassemble-go](https://github.com/itchyny/rassemble-go), which is itself based on the brain-melting [Regexp::Assemble](https://github.com/ronsavage/Regexp-Assemble) Perl module) is to assemble individual parts of a regular expression into a single expression (with some optimizations).

## Setup

### With Existing Go Environment

If you have a current Go environment, you can simply run

```bash
go install github.com/coreruleset/crs-toolchain@latest
```

Provided that you have the Go binaries on your, you can now run the toolchain from anywhere with

```bash
crs-toolchain
```

### With The Binary

Alternatively, you can download one of the pre-built binaries from Github. Navigate to `https://github.com/coreruleset/crs-toolchain/releases/latest` and download the package of your choice and the `crs-toolchain-checksums.txt` file. To verify the integrity of the binary / archive, navigate to the directory where you've stored the two files and verify that the checksum matches:

```bash
cd ~/Downloads
shasum -a 256 -c crs-toolchain-checksums.txt 2>&1 | grep OK
```

The output should look like the following (depnding on the binary / archive you downloaded):

```bash
crs-toolchain-1.0.0_amd64.deb: OK
```

### Test The Toolchain

You should now be able to use the crs-toolchain. Try to run the following in your shell:

```bash
printf "(?:homer)? simpson\n(?:lisa)? simpson" | crs-toolchain regex generate -
```

The output should be:

```bash
(?:homer|(?:lisa)?) simpson
```

## Adjusting the Logging Level

The level of logging can be adjusted with the `--log-level` option. Accepted values are  `trace`, `debug`, `info`, `warn`, `error`, `fatal`, `panic`, `disabled`, the default is `info`.

## The `regex` Command

The `regex` command provides sub-commands for everything surrounding regular expressions, especially the "assembly" of regular expressions from a specification of its components (see [Regular Expression Assembly]({{< ref "regex_assembly" >}}) for more details).

### Example Use

To generate a reduced expression from a list of expressions, simply pass the corresponding CRS rule ID to the script or pipe the contents to it:

```bash
crs-toolchain regex generate 942170
# or
cat util/regexp-assemble/data/942170.data | crs-toolchain regex generate -
```

It is also possible to compare generated expressions to the current expressions in the rule files, like so:

```bash
crs-toolchain regex compare 942170
```

Even better, rule files can be updated directly:

```bash
crs-toolchain regex update 942170
# or update all
crs-toolchain regex update --all
```

Read the built-in help text for the full documentation:

```bash
crs-toolchain --help
```

## The `util` Command

The `util` command includes sub-commands that are used from time to time and do not fit nicely into any of the other groups. Currently, the only sub-command is `renumber-tests`. `renumber-tests` is used to simplify maintenance of the regression tests. Since every test has a consecutive number within its file, adding or removing tests can disrupt numbering. `renumber-tests` will renumber all tests within each test file consecutively.

## The `completion` command

The `completion` command can be used to generate a shell script for shell completion. For example:

```bash
crs-toolchain completion zsh >  ~/.zsh.d/2/crs-toolchain.zsh
```

How completion is enabled and where completion scripts are sourced from depends on your environment. Please consult the documentation of your shell.
