---
title: crs-toolchain
weight: 62
disableToc: false
chapter: false
aliases: ["../development/crs_toolchain"]
---

> The crs-toolchain is the CRS developer's utility belt — the Swiss army knife for CRS development. It provides a single point of entry and a consistent interface for a range of different tools. Its core functionality (owed to the great [rassemble-go](https://github.com/itchyny/rassemble-go), which is itself based on the brain-melting [Regexp::Assemble](https://github.com/ronsavage/Regexp-Assemble) Perl module) is to assemble individual parts of a regular expression into a single expression (with some optimizations).

The current stable release is **v2.7.0** (as of December 2025).

## Setup

### Method 1: Pre-built Binaries (Recommended)

The recommended way to get the tool is using one of the pre-built binaries from GitHub. Navigate to the [latest release](https://github.com/coreruleset/crs-toolchain/releases/latest) and download the package for your platform along with the `crs-toolchain-checksums.txt` file.

**Available formats:**
- Linux: `.deb`, `.rpm`, `.tar.gz`, and `.apk` packages
- macOS: `.tar.gz` archives for both Intel and Apple Silicon
- Windows: `.zip` and `.tar.gz` archives

To verify the integrity of the binary/archive, navigate to the directory where the two files are stored and verify that the checksum matches:

```bash
cd ~/Downloads
shasum -a 256 -c crs-toolchain-checksums.txt 2>&1 | grep OK
```

The output should look like the following (depending on the binary/archive downloaded):

```bash
crs-toolchain-2.7.0_amd64.deb: OK
```

### Method 2: Install with Go

{{% notice note %}}
This method requires Go 1.19 or higher installed on your system.
{{% /notice %}}

If a current Go environment is present, install the latest version directly:

```bash
go install github.com/coreruleset/crs-toolchain/v2@latest
```

Provided that the Go binaries are on the `PATH` (typically `~/go/bin`), the toolchain can now be run from anywhere:

```bash
crs-toolchain --version
```

### Method 3: Self-Update

Once you have crs-toolchain installed, you can update it to the latest version using the built-in self-update command:

```bash
crs-toolchain util self-update
```

This will automatically download and install the latest release for your platform.

## Verify Installation

After installation, verify that crs-toolchain is working correctly:

```bash
# Check version
crs-toolchain --version

# View available commands
crs-toolchain --help
```

### Test the Toolchain

Test the regex assembly functionality by running the following in a shell:

```bash
printf "(?:homer)? simpson\n(?:lisa)? simpson" | crs-toolchain regex generate -
```

The output should be:

```bash
(?:homer|(?:lisa)?) simpson
```

This demonstrates that the tool successfully assembled multiple regular expression alternatives into an optimized single expression.

## Configuration and Options

### Adjusting the Logging Level

The level of logging can be adjusted with the `--log-level` global flag. This affects the verbosity of output for all commands.

**Available levels** (from most to least verbose):
- `trace` - Most detailed, includes all internal operations
- `debug` - Detailed debugging information
- `info` - General informational messages (default)
- `warn` - Warning messages only
- `error` - Error messages only
- `fatal` - Fatal errors only
- `panic` - Panic-level errors only
- `disabled` - No logging output

**Usage:**

```bash
# Run with debug logging
crs-toolchain --log-level debug regex generate 942170

# Run with minimal output
crs-toolchain --log-level error regex update --all
```

### Global Flags

In addition to `--log-level`, the following global flags are available for all commands:

```bash
crs-toolchain --help              # Show help for all commands
crs-toolchain --version           # Show version information
crs-toolchain <command> --help    # Show help for a specific command
```

## Recent Releases and Improvements

### Version 2.7.0 (December 2024)
- Release automation improvements
- Bug fixes for semver parsing
- Enhanced meta character escaping
- Security dependency updates for crypto and compression libraries

### Version 2.6.0 (September 2024)
- Integrated wordnet database functionality for fp-finder utility
- Improved false positive detection capabilities
- Routine dependency maintenance

### Version 2.5.0 (August 2024)
- Command refactoring for better performance
- Enabled stdin support for fp-finder command
- GitHub Actions and Alpine Linux updates

### Version 2.4.0 (May 2024)
- **New feature:** `util fp-finder` command for detecting false positives
- Added PR templates
- Improved regex comparison functionality

### Version 2.3.x Series (January-April 2024)
- Enhanced format validation to fail on unnecessary uppercase character classes
- Fixed Unicode character hex representation issues
- Added warnings for uppercase in case-insensitive patterns
- Removed mage build tool dependency
- Restricted evasion modifiers usage

{{% notice tip %}}
To see the full release history and detailed changelogs, visit the [releases page](https://github.com/coreruleset/crs-toolchain/releases) on GitHub.
{{% /notice %}}

## Getting Help

### Built-in Documentation

Read the built-in help text for comprehensive documentation:

```bash
# General help
crs-toolchain --help

# Command-specific help
crs-toolchain regex --help
crs-toolchain regex generate --help
crs-toolchain util --help
```

### Online Resources

- **Official Documentation:** https://coreruleset.org/docs/development/crs_toolchain/
- **GitHub Repository:** https://github.com/coreruleset/crs-toolchain
- **Issue Tracker:** https://github.com/coreruleset/crs-toolchain/issues
- **Latest Releases:** https://github.com/coreruleset/crs-toolchain/releases

## The `regex` Command

The `regex` command provides sub-commands for everything surrounding regular expressions, especially the "assembly" of regular expressions from a specification of its components. This is the most commonly used feature of crs-toolchain for CRS development.

For detailed information on how regular expressions are assembled, see [Assembling Regular Expressions]({{% ref "6-3-assembling-regular-expressions.md" %}}).

### Available Sub-commands

#### `generate`

Generates an optimized regular expression from a list of expression components. This command reads from regex assembly (`.ra`) files and produces an assembled, optimized expression.

**Usage:**

```bash
# Generate from rule ID (reads from regex-assembly/<rule-id>.ra)
crs-toolchain regex generate 942170

# Generate from stdin
cat regex-assembly/942170.ra | crs-toolchain regex generate -

# Generate from a specific file
crs-toolchain regex generate --file path/to/942170.ra
```

**Example:**

```bash
# Input: regex-assembly/942170.ra might contain:
# select
# union
# where
# from

# Output: Optimized assembled regex
(?:from|select|union|where)
```

#### `compare`

Compares the generated expression against the current expression in the rule files. This is useful for verifying that changes to regex assembly files will produce the expected output.

**Usage:**

```bash
# Compare single rule
crs-toolchain regex compare 942170

# Compare all rules
crs-toolchain regex compare --all
```

The output will show:
- Whether the expressions match
- Differences between current and generated expressions
- Any formatting or optimization changes

#### `update`

Updates rule files directly with newly generated expressions. This command modifies the actual CRS rule configuration files.

{{% notice warning %}}
This command modifies files in place. Make sure you have committed your changes or have a backup before running update commands.
{{% /notice %}}

**Usage:**

```bash
# Update single rule
crs-toolchain regex update 942170

# Update all rules with .ra files
crs-toolchain regex update --all

# Dry-run to see what would be updated (without making changes)
crs-toolchain regex update --all --dry-run
```

#### `format`

Checks and formats regex assembly (`.ra`) files according to CRS standards. This ensures consistent formatting across all regex assembly files.

**Usage:**

```bash
# Check formatting for all .ra files
crs-toolchain regex format --all

# Format a specific rule
crs-toolchain regex format 942170

# Check only (report violations without fixing)
crs-toolchain regex format --all --check
```

**Format checks include:**
- Proper line endings
- Consistent indentation
- Avoiding unnecessary uppercase character classes (added in v2.3.3)
- Warning about uppercase in case-insensitive patterns (added in v2.2.0)

### Common Workflow

A typical workflow when modifying regular expressions:

```bash
# 1. Edit the .ra file
vim regex-assembly/942170.ra

# 2. Check formatting
crs-toolchain regex format 942170

# 3. Generate and compare to see the result
crs-toolchain regex compare 942170

# 4. If satisfied, update the rule file
crs-toolchain regex update 942170

# 5. Test the changes
# (run your tests here)
```

## The `util` Command

The `util` command includes sub-commands that are used from time to time and do not fit nicely into any of the other groups. Available sub-commands:

### `renumber-tests`

Used to simplify maintenance of the regression tests. Since every test has a consecutive number within its file, adding or removing tests can disrupt numbering. This command will renumber all tests within each test file consecutively.

**Usage:**

```bash
crs-toolchain util renumber-tests
```

### `fp-finder`

The false positive finder utility helps identify potential false positives in CRS rules. This command analyzes test data and can process input from stdin or files to detect patterns that might trigger false positives.

**Added in:** v2.4.0 (with wordnet database integration in v2.6.0)

**Usage:**

```bash
# Run fp-finder with stdin input
echo "test data" | crs-toolchain util fp-finder -

# Run fp-finder with file input
crs-toolchain util fp-finder <test-file>
```

This tool is particularly useful for:
- Identifying problematic patterns before deployment
- Testing rule changes against known good traffic
- Validating that rule modifications don't introduce new false positives

### `self-update`

Updates the crs-toolchain to the latest available version. This command automatically downloads and installs the newest release for your platform.

**Usage:**

```bash
crs-toolchain util self-update
```

The command will:
1. Check for the latest release on GitHub
2. Download the appropriate binary for your platform
3. Replace the current installation with the new version
4. Verify the update was successful

## The `chore` Command

The `chore` command provides maintenance utilities primarily used by CRS maintainers and release managers.

### `release`

Manages the release process for crs-toolchain, including version tagging and release artifact generation.

**Usage:**

```bash
crs-toolchain chore release
```

### `update-copyright`

Updates copyright year information across the project files.

**Usage:**

```bash
crs-toolchain chore update-copyright
```

## The `completion` Command

The `completion` command generates shell completion scripts to enable tab completion for crs-toolchain commands in your shell.

### Supported Shells

- Bash
- Zsh
- Fish
- PowerShell

### Installation Examples

**For Zsh (with Oh My Zsh):**

```bash
mkdir -p ~/.oh-my-zsh/completions
crs-toolchain completion zsh > ~/.oh-my-zsh/completions/_crs-toolchain
```

**For Bash:**

```bash
crs-toolchain completion bash > /etc/bash_completion.d/crs-toolchain
```

**For Fish:**

```bash
crs-toolchain completion fish > ~/.config/fish/completions/crs-toolchain.fish
```

**For PowerShell:**

```powershell
crs-toolchain completion powershell | Out-String | Invoke-Expression
```

{{% notice tip %}}
After installing shell completion, you may need to restart your shell or source your shell configuration file for the changes to take effect.
{{% /notice %}}

How completion is enabled and where completion scripts are sourced from depends on your shell and environment. Please consult the documentation of the shell you're using for specific details.
