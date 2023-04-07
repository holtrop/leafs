# LEAFS

LEAFS is an Easy Asset File System.

LEAFS consists of a redistributable command-line script which generates source
code that:

* contains the contents of a set of input file(s)
* provides an API to read these file contents

Currently LEAFS generates D source code.

# Installation

LEAFS does not require any installation.
It is a standalone script that can be copied into and versioned with the
project that uses it.
The only dependency LEAFS requires is a Ruby interpreter.

# Usage

    Usage: ./leafs [options] <paths>

    LEAFS is an Easy Asset File System

    Options:
      --version                 Show the version and exit
      --help, -h                Show the usage and exit
      --strip=<S>, -s <S>       Strip path prefix S from asset paths

    All <paths> specified will be recursively selected to add to the generated
    asset file system.

LEAFS provides a simple command-line interface.
It can integrate with any build system by adding a custom command to invoke
the leafs executable.

## Example

    ./leafs -o gen/leafs.d -s assets assets

This will generate a leafs.d source module containing the contents of every
file recursively found under the `assets` directory.
Since the `-s` option is given, the `assets/` prefix to each file path will be
stripped, so a `assets/shader.glsl` can be loaded via the path `shader.glsl`.

## API

LEAFS generates a D module containing a struct with a simple API.
An application can access file contents using the `get()` function.
For example:

```d
import leafs;

string shader_src = cast(string)Leafs.get("shader.glsl");
```
