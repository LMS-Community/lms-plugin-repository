# lms-plugin-repository

The `lms-plugin-repository` repository hosts the plugin and extensions information file for the [Logitech Media Server](http://github.com/LMS-Community/slimserver) (aka. LMS).

A GitHub Actions file does collect the information from the various plugin authors' own repositories and merges them into one XML file. This XML file is to be used in LMS v7.9.4 and later.
The task is triggered automatically every few hours, or can be launched manually.
This allows maintainers to manage the central file without the need to clone this repository.

## `buildrepo.pl` - the worker script

`buildrepo.pl` is the work horse. It reads `include.json` and fetches all repository files found in there.
As the result of this action it saves an updated extensions.xml file.

## `include.json` - the repository of repositories

`include.json` contains a list URLs to plugin repositories to be included in the central `extensions.xml` file.
If a plugin author wants his plugins to be included in the default list of extensions in LMS, just add the URL to his repository XML file to this list and re-run the build script.
