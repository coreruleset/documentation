# CRS Documentation Repository

This repository contains the documentation for OWASP CRS. For the official website, see [https://coreruleset.org/](https://coreruleset.org/).

## For Readers

The generated documentation is automatically updated at https://coreruleset.org/docs/. If you just want to read the documentation, you can find it there.

## For Contributors

Welcome! This page will guide you through the process of contributing to the CRS documentation. Before you start, please read our [Contribution Guideline](content/development/contribution_guidelines.md).

### 1. Prerequisites

To contribute to the CRS documentation, The only thing you need is the latest [Hugo binary](https://gohugo.io/getting-started/installing/) for your OS (Windows, Linux, Mac) **(Important: You need Hugo _extended_ version >= 0.93.0.)**.

### 2. Building the Local Environment

Once you have Hugo, clone this repository to work locally. You can edit and verify quickly that everything is working properly before creating a new pull request.
To clone, use the *recursive* option to get the theme we use for the documentation to render the pages properly:

```bash
git clone --recursive git@github.com:coreruleset/documentation.git
```

Now you have all in place to perform your local edits. Everything is created using [Markdown](https://www.markdownguide.org/), and you will normally use the `content` subdirectory to add your edits. The theme has many shortcodes and others that you can use to simplify editing. You can get more information about it on [Hugo Relearn theme](https://themes.gohugo.io/themes/hugo-theme-relearn/).

Now, you can run `hugo` to serve the pages, and while you edit and save, your changes will be refreshed in the browser!

Use:
```bash
hugo serve
```

Then check your edits on http://localhost:1313/documentation/.

### 3. Creating a Pull Request

If you are a CRS developer, you can make a branch in the documentation repository. If you are an outside contributor, you can fork the [repository](https://github.com/coreruleset/documentation/) to your own GitHub account and create a branch in your fork. Once you are happy with your changes, [send a PR](https://github.com/coreruleset/documentation/pulls) with your changes. After review and merging, the documentation is built and published on [https://coreruleset.org/docs](https://coreruleset.org/docs/) after max. 5 minutes.
