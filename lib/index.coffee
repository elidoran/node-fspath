fs       = require 'fs'
corepath = require 'path'

isFile = (path) -> path.isFile()
isDir  = (path) -> path.isDir()

class Path

  constructor: (path) ->

    @_the = {}

    if path?

      if 'string' is typeof path
        @path = path
        @parts = path.split corepath.sep # split into array

      else if Array.isArray path
        @path = path.join corepath.sep
        @parts = path.slice() # copy array

      else
        throw new Error 'Path requires either string or array as `path` to constructor'

    else
      @path = '.'
      @parts = [ '.' ]

    @isAbsolute = corepath.isAbsolute @path
    @isRelative = not @isAbsolute


  reset: ->
    @_the = {}
    @_stats = null


  stats: (done) ->

    if done?

      fs.stat @path, (error, stats) =>
        @_stats = stats
        # get rid of error if it's a 'path doesnt exist' error
        if error?.code is 'ENOENT' then error = null
        done error, stats

    else
      try
        @_stats = null
        @_stats = fs.statSync @path
      catch error
        # errno is 34 in node 0.10.*
        # errno is -2 in node 0.12.* and 4.* ... so, use 'code'
        ### istanbul ignore else ###
        if error.code is 'ENOENT' then return
        else throw error


  refresh: (done) ->
    @reset()
    @stats done


  toString: -> @path


  _fromStats: (done, getter) ->

    if done? then @stats (error, stats) ->

      ### istanbul ignore if ###
      if error?
        if error.code is 'ENOENT' then done null, getter stats
        else done error

      else
        done null, getter stats

    else getter @stats()

  isReal  : (done) -> @_fromStats done, (stats) -> stats?
  isFile  : (done) -> @_fromStats done, (stats) -> stats?.isFile() ? false
  isDir   : (done) -> @_fromStats done, (stats) -> stats?.isDirectory() ? false
  modified: (done) -> @_fromStats done, (stats) -> stats?.mtime
  created : (done) -> @_fromStats done, (stats) -> stats?.ctime
  accessed: (done) -> @_fromStats done, (stats) -> stats?.atime

  isCanonical: -> @_the.canonical ? (@_the.canonical = not ('.' in @parts or '..' in @parts))
  basename: -> @_the.basename  ? (@_the.basename  = corepath.basename @path)
  filename: -> @_the.filename  ? (@_the.filename  = corepath.basename @basename(), @extname())
  extname : -> @_the.extension ? (@_the.extension = corepath.extname @basename())
  dirname : -> @_the.dirname   ? (@_the.dirname   = corepath.basename corepath.dirname @path)

  parent: -> @_the.parent ? (@_the.parent = @to '..')


  up: (count = 1) ->
    count = Math.max 1, Math.min 20, count
    add = '..'
    add += corepath.sep + '..' for i in [1...count]
    @to add


  startsWith: (arg) ->

    path =
      if typeof arg is 'string' then arg
      else if typeof arg?.path is 'string' then arg.path

    path? and path.length <= @path.length and
      path.length > 0 and path is @path[...path.length]


  endsWith: (arg) ->

    path =
      if typeof arg is 'string' then arg
      else if typeof arg?.path is 'string' then arg.path

    path? and path.length <= @path.length and
      path.length > 0 and path is @path[-path.length...]


  equals: (value) -> # value: string, regex, Path

    if value?

      if 'string' is typeof value then @path is value

      # instanceof RegExp, check for `test` function instead
      else if 'function' is typeof value.test then value.test @path

      # instanceof Path, check for `path` string property instead
      else if 'string' is typeof value.path then @path is value.path

      # could return false, but, I think you meant to provide the right
      # type and something went wrong, so, let's return an error.
      else error: 'equals() requires: string, regex, or Path'

    else false


  _createStream: (options, creator) ->

    if options?.done?
      path = @path
      done = options.done
      process.nextTick ->
        try
          done null, creator path, options
        catch error
          ### istanbul ignore next ###
          done error

    else creator @path, options


  reader: (arg) ->

    options = if typeof arg is 'function' then done:arg else arg

    unless @isFile()
      error = error: 'reader() requires file'
      if options?.done? then return options.done error
      else return error

    @_createStream options, (path, options) ->
      # passing `null` for options errors in node 0.12 and 4+.
      # so, we'll ensure it's an object
      fs.createReadStream path, options ? {}


  writer: (arg) ->

    options = if typeof arg is 'function' then done:arg else arg

    if @isDir()
      error = error: 'writer() requires non-directory'
      if options?.done? then return options.done error
      else return error

    @_createStream options, (path, options) ->
      fs.createWriteStream path, options


  read: (arg) ->

    options = if typeof arg is 'function' then done:arg else arg

    unless @isFile()
      error = error: 'read() requires file'
      if options?.done? then return options.done error
      else return error

    if options?.done? then fs.readFile @path, options, options.done
    else fs.readFileSync @path, options


  write: (data, arg) ->

    options = if typeof arg is 'function' then done:arg else arg

    if @isDir()
      error = error: 'write() requires non-directory'
      if options?.done? then return options.done error
      else return error

    if options?.done? then fs.writeFile @path, data, options, options.done
    else fs.writeFileSync @path, data, options


  append: (data, arg) ->

    options = if typeof arg is 'function' then done:arg else arg

    if @isDir()
      error = error: 'append() requires non-directory'
      if options?.done? then return options.done error
      else return error

    if options?.done? then fs.appendFile @path, data, options, options.done
    else fs.appendFileSync @path, data, options


  # stream: the stream to pipe the file's content to, or a path (call path.writer())
  # options: options for creating the reader and adding events to the reader
  # options.reader: the options to pass to reader()
  # options.writer: the options to pass to writer()
  # options.events: the event/listener pairs to register with the reader
  pipe: (pathOrStream, options) ->

    # get a reader for *this* path
    reader = @reader options?.reader

    if reader.error? then return reader

    if options?.events?.reader?
      reader.on event, listener for event, listener of options.events.reader

    # if target is a path then get a writer for it
    writer =
      if pathOrStream instanceof Path then pathOrStream.writer options?.writer
      else pathOrStream

    if writer.error? then return writer

    if options?.events?.writer?
      writer.on event, listener for event, listener of options.events.writer

    # finally pipe together and return result for chaining further
    return reader.pipe writer


  list: (arg) ->

    options = if typeof arg is 'function' then done:arg else arg

    unless @isDir()
      error = error: 'list() requires directory'
      if options?.done? then return options.done error
      else return error


    if options?.done?
      done = options.done
      path = this
      fs.readdir @path, (error, array) ->
        ### istanbul ignore if ###
        if error? then done error
        else done null, path._processList options, array

    else @_processList options, fs.readdirSync @path


  _processList: (options, array) ->

    acceptString = options?.acceptString
    acceptPath   = options?.acceptPath
    each         = options?.each

    # store all the accepted paths
    paths = []

    # count the rejected strings/paths
    rejectedStrings = rejectedPaths = 0

    # check array with filters, report each, count rejects
    for string in array

      # if there's no filter, or if the filter accepts
      if not acceptString? or acceptString string

        path = @to string

        # if there's no filter, or if the filter accepts
        if not acceptPath? or acceptPath path

          paths[paths.length] = path
          # call each if it exists
          each? {path}

        else rejectedPaths++

      else rejectedStrings++

    return paths:paths, rejected:{strings:rejectedStrings, paths:rejectedPaths}


  files: (arg) ->

    options = if typeof arg is 'function' then done:arg else arg

    if options?

      # clone their options
      options = Object.assign {}, options

      # wrap their filter so we can use `isFile` first
      if options.acceptPath?
        theirFilter = options.acceptPath
        options.acceptPath = (path) -> path.isFile() and theirFilter path

      # they aren't filtering, so, use ours directly
      else options.acceptPath = isFile

    # supply our files filter
    else options = acceptPath: isFile

    @list options


  dirs: (arg) ->

    options = if typeof arg is 'function' then done:arg else arg

    if options?

      # clone their options
      options = Object.assign {}, options

      # wrap their filter so we can use `isDir` first
      if options.acceptPath?
        theirFilter = options.acceptPath
        options.acceptPath = (path) -> path.isDir() and theirFilter path

      # they aren't filtering, so, use ours directly
      else options.acceptPath = isDir

    # supply our files filter
    else options = acceptPath: isDir

    @list options


  to: (path) ->

    if 'string' is typeof path
      newPath = corepath.join @path, path
      if newPath is @path then this else new Path newPath

    else if Array.isArray path then new Path @parts.concat path

    else error: 'to(path) requires either a string or array of strings'


  resolve: (path) ->
    path = corepath.resolve @path, path
    if path is @path then this else new Path path


  relativeTo: (path) ->
    path = corepath.relative @path, path
    if path.length < 1 then return this else new Path path


  normalize: () ->
    normalized = corepath.normalize @path
    if normalized is @path then this else new Path normalized


  subpath: (start, end) -> new Path (if @path is '/' then '' else @parts[start...end])


  part: (index) -> @parts[index]


# alias:
Path::extension = Path::extname


# Use these ways:
#  1a. {Path} = require 'fspath'
#  1b. Path = require('fspath').Path
#      path = new Path 'some/path'
#  2. buildPath = require 'fspath'
#     path      = buildPath 'some/path'
#  3. path = require('fspath') 'some/path'
module.exports = (path) -> new Path path
module.exports.Path = Path
