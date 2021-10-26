# Core Rule Set Documentation Repository

This repository contains the documentation for the OWASP ModSecurity Core Rule Set.

## Requirements

Just download latest version of [Hugo binary](https://gohugo.io/getting-started/installing/) for your OS (Windows, Linux, Mac) : it’s that simple. You will need the _extended_ version, so be sure you download that one.

## Cloning this repository

After getting hugo, just clone this repository to work locally. This was you can edit and verify quickly that everything is working properly before creating a new pull request.

To clone, use the recursive version so you will be getting also the theme to render the pages properly:

```bash
git clone --recursive git@github.com:coreruleset/documentation.git
```

## Editing locally

Now you have all in place to perform you local edition.

Everything is created using markdown, and you will normally use the `content` subdirectory to add your edits.

The theme has many shortcodes and others that you can use to simplify the edition. You can have more information about it on [Hugo Relearn theme](https://themes.gohugo.io/themes/hugo-theme-relearn/).

You should run hugo to serve the pages and while you edit and save changes will be refreshed!

Use:
```
hugo serve
```

Once you are happy with your changes, [send a new PR](https://github.com/coreruleset/documentation/pulls) with your changes.

After reviewed and merged, the documentation is built by GitHub Actions and published [here](https://coreruleset.github.io/documentation/).
