# fspath (Path)
[![Build Status](https://travis-ci.org/elidoran/node-fspath.svg?branch=master)](https://travis-ci.org/elidoran/node-fspath)
[![Dependency Status](https://gemnasium.com/elidoran/node-fspath.png)](https://gemnasium.com/elidoran/node-fspath)
[![npm version](https://badge.fury.io/js/fspath.svg)](http://badge.fury.io/js/fspath)


Immutable Path object replaces using strings for paths. It provides some functionality from both `path` and `fs` core modules.

Path avoids doing any internal work, except storing the string and its parts split by the path separator, until a function is called requesting the information.

Some of the helpful capabilities:

1. all the `path` module's functions
2. `isAbsolute` and `isRelative`
3. fs.stats related information
4. fs.{write|append|read}File[Sync]
5. create read/write streams
6. piping between paths
7. listing directory contents
8. path startsWith, endsWith, equals
9. subpath
10. and much more

Many of Path's functions will operate asynchronously when a callback is provided; otherwise they operate synchronously.

<table of contents, like cosmos-browserify>

Note: Although this document is incomplete the library is fully functional and there are many tests.

## Install

```sh
npm install paths --save
```

## Examples

```coffeescript
# get the class
buildPath = require 'fspath'

dir = buildPath()          # creates a path to the current working directory

dir = buildPath 'some/app' # creates a path to specified relative path

parentDir = dir.parent()
# OR: parentDir = dir.to '..'

childDir = path.to 'child'

siblingDir = childDir.to '../sibling'

{paths} = dir.list()
# OR: dir.list (error, result) -> paths = result.paths

file = dir.to 'some-file.txt'
file.write 'some data'
file.append '\nmore data'
# OR:
#  file.write 'some data', (error) ->
#    if error? then # do something when error exists
#    file.append '\nmore data', (error) -> # do something when error exists

content = file.read()
console.log content # 'some data\nmore data'

source = dir.to 'a-source-file.txt'
target = dir.to 'a-target-file.txt'
source.pipe target  # calls reader() on source and writer() on target and pipes them
# options object accepts options for both reader/writer and for adding events

# listen for the finish event:
source.pipe target, events:writer:finish: -> # do something when target's writer stream is finished
# or wrap that options object down onto separate lines if you like...
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
