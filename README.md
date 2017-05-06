# fspath (Path)
[![Build Status](https://travis-ci.org/elidoran/node-fspath.svg?branch=master)](https://travis-ci.org/elidoran/node-fspath)
[![Dependency Status](https://gemnasium.com/elidoran/node-fspath.png)](https://gemnasium.com/elidoran/node-fspath)
[![npm version](https://badge.fury.io/js/fspath.svg)](http://badge.fury.io/js/fspath)
[![Coverage Status](https://coveralls.io/repos/github/elidoran/node-fspath/badge.svg?branch=master)](https://coveralls.io/github/elidoran/node-fspath?branch=master)

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

Note: Although this document is incomplete the library is fully functional and there are many tests.


## Install

```sh
npm install fspath --save
```


## Examples

```javascript
// get the builder
var buildPath = require('fspath')

// create a path to the current working directory
var dir = buildPath()

// create a path to specified relative path
dir = buildPath('some/app')

// create a new path at parent path
var parentDir = dir.parent()
// OR: parentDir = dir.to('..')

// create a path beneath this one.
// could be a file or a directory
var child = dir.to('child')

// create a path relative to it
var sibling = child.to('../sibling')

var result = dir.list()
// result.paths is an array with all the paths.
// OR:
dir.list(function(error, result) {
  var paths = result.paths
  // do something...
})

// a new path we know is a file
var file = dir.to('some-file.txt')

// write to it
file.write('some data')

// or append to it
file.append('\nmore data')

// OR:
file.write('some data', function (error) {
  if (error) {
    // do something when error exists
  }
})

content = file.read()
// content = 'some data\nmore data'

// create two paths
var source = dir.to('a-source-file.txt')
var target = dir.to('a-target-file.txt')

// pipe the first into the second.
// this requires `source` to be a real file,
// and requires `target` *not* be a directory.
source.pipe(target)
// the above calls reader() on source,
// and writer() on target, then pipes them.

// or, provide an options object.
// it accepts options for both reader/writer,
// and for adding events to both streams.
source.pipe(target, {
  reader: { /* options to give source.reader() */ },
  writer: { /* options to give to target.writer() */ },
  events: {
    reader: {
      // events to add to reader
      error: function(error) { }
    },
    writer: {
      // events to add to writer
      error: function(error) { }
    }
  }
})

// for example, listen for the writer's finish event:
source.pipe(target, {
  events: {
    writer: {
      finish: function() {
        // do something when target's writer stream is finished
      }
    }
  }
})
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


### stats([callback])

```javascript
// sync (no callback) call returns the stats object provided by node's fs module
stats = path.stats()

// async call provides the stats or an error object
path.stats(function(error, stats) {
  // ...
})
```

### isReal([callback])

```javascript
// sync (no callback) call returns true if the file/directory exists
isReal = path.isReal()

// async call provides true/false or an error object
path.isReal(function(error, isReal) {
  // ...
})
```

### isFile([callback])

```javascript
// sync (no callback) call returns true if it exists and is a file
isFile = path.isFile()

// async call provides true/false or an error object
path.isFile(function(error, isFile) {
  // ...
})
```

### isDir([callback])

```javascript
// sync (no callback) call returns true if it exists and is a directory
isDir = path.isDir()

// async call provides true/false or an error object
path.isDir(function(error, isDir) {
  // ...
})
```

### isCanonical([callback])

```javascript
// sync (no callback) call returns true if the path is normalized.
var isCanonical = path.isCanonical()

// async call provides true/false or an error object
path.isCanonical(function(error, isCanonical) {
  // ...
})
```

### modified([callback])
### created([callback])
### accessed([callback])

### basename()
### filename()
### extname()  or  extension()
### dirname()

### startsWith(string|fspath)
### endsWith(string|fspath)
### equals(string|regex|fspath)

### normalize()
### relativeTo(string)
### resolve(string[, string]*)
### subpath(start, end)
### part(index)

### reset()
### refresh()

### parent()
### up(count)
### to(path)

### list(options|done)
### files(options|done)
### dirs(options|done)

### reader(options|done)
### read(options|done)
### writer(options|done)
### write(data, options|done)
### append(data, options|done)
### pipe(stream, options)


### [MIT License](LICENSE)
