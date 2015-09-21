# fspath (Path)
[![Build Status](https://travis-ci.org/elidoran/node-fspath.svg?branch=master)](https://travis-ci.org/elidoran/node-fspath)
[![Dependency Status](https://gemnasium.com/elidoran/node-fspath.png)](https://gemnasium.com/elidoran/node-fspath)
[![npm version](https://badge.fury.io/js/fspath.svg)](http://badge.fury.io/js/fspath)


Path object replaces using strings for paths. It provides some functionality from both `path` and `fs` core modules.

Although, using modules `fs` and `path` on strings gets the job done with focused modules, it can become tedious to manage the path strings manually, using the `path` module's *join* and *resolve*, and using `fs` to manage the streams.

This module combines those operations onto a single object: `Path`

<table of contents, like cosmos-browserify>

Note: Although this document is incomplete the library is fully functional and there are many tests.

## Install

```sh
npm install paths --save
```

## Usage: Basic

```coffeescript
# get the class
Path = require 'fspath'

dir = Path()          # creates a path to the current working directory

dir = Path 'some/app' # creates a path to specified relative path

parentDir = dir.parent()
# OR: parentDir = dir.to '..'

childDir = path.to 'child'

siblingDir = childDir.to '../sibling'

paths = dir.list()
# OR: dir.list (error, result) -> paths = result.paths


```

## Immutable Path

The Path object is immutable. Functions which require a different internal state return a *new* Path object.

This allows passing a Path object around without worrying some operation is changing it.

It also allows that object to be the focus of managing streams it creates to the file for only one file path.


## API

### Accessible Properties

1. `path` : the path as a string
2. `parts`: path string split on delim into an array of strings
3. `isRelative`: true when the path doesn't start with a slash
4. `isAbsolute`: true when the path starts with a slash

### Functions

#### stats([callback])

```coffeescript
# sync (no callback) call returns the stats object provided by node's fs module
stats = path.stats()

# async call provides the stats or an error object
path.stats (error, stats) -> console.log error?.message ? stats
```

#### isReal([callback])

```coffeescript
# sync (no callback) call returns true if the file/directory exists
isReal = path.isReal()

# async call provides true/false or an error object
path.isReal (error, isReal) -> console.log error?.message ? isReal
```

#### isFile([callback])

```coffeescript
# sync (no callback) call returns true if it exists and is a file
isFile = path.isFile()

# async call provides true/false or an error object
path.isFile (error, isFile) -> console.log error?.message ? isFile
```

#### isDir([callback])

```coffeescript
# sync (no callback) call returns true if it exists and is a directory
isDir = path.isDir()

# async call provides true/false or an error object
path.isDir (error, isDir) -> console.log error?.message ? isDir
```

#### isCanonical([callback])

```coffeescript
# sync (no callback) call returns true if the path is normalized.
isCanonical = path.isCanonical()

# async call provides true/false or an error object
path.isCanonical (error, isCanonical) -> console.log error?.message ? isCanonical
```

#### modified([callback])
#### created([callback])
#### accessed([callback])

#### basename()

Returns the last part of the path.

```coffeescript
# some/path  returns  path
# some/path/ returns  path
```


#### filename()
#### extname()  or  extension()
#### dirname()

#### startsWith(string)
#### endsWith(string)
#### equals(string|regex|Path)

#### normalize()
#### relativeTo(string)
#### resolve(string[, string]*)
#### subpath(start, end)
#### part(index)

#### reset()
#### refresh()

#### parent()
#### up(count)
#### to(path)

#### list(options, done)
#### files(options, done)
#### dirs(options, done)

#### reader(options, done)
#### read(options, done)
#### writer(options, done)
#### write(data, options, done)
#### append(data, options, done)
#### pipe(stream, options)


### MIT License
