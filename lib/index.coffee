fs       = require 'fs'
corepath = require 'path'

hasRoot = /// ^(
  \/           # *nix style root
  | [a-zA-Z]\: # windows drive spec
  | \\         # no drive spec, but, is absolute from current drive
) ///

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

    @isAbsolute = hasRoot.test @path
    @isRelative = not @isAbsolute

  reset: ->
    delete @_the
    delete @_stats
    @_the = {}

  stats: (done) ->
    if done?
      fs.stat @path, (error, stats) => @_stats = stats ; done error, stats
    else
      try
        delete @_stats
        @_stats = fs.statSync @path
      catch error
        # errno is 34 in node 0.10.*
        # errno is -2 in node 0.12.* and 4.* ... so, use 'code'
        if error.code is 'ENOENT' then return
        else throw error

  refresh: (done) ->
    @reset()
    @stats done

  toString: -> @path

  _fromStats: (done, getter) ->
    if done? then @stats (error, stats) ->
      if error?
        if error.errno is 34 then done undefined, getter()
        else done error
      else
        done undefined, getter stats

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
  extension: @extname

  parent: -> @_the.parent ? (@_the.parent = @to '..')

  up: (count = 1) ->
    count = Math.max 1, Math.min 20, count
    add = '..'
    add += corepath.sep + '..' for i in [1...count]
    @to add

  startsWith: (path) -> if path?.length then @path[...path.length] is path.toString() else false
  endsWith  : (path) -> if path?.length then @path[-path.length...] is path.toString() else false

  equals: (value) -> # value: string, regex, Path
    if value?
      if 'string' is typeof value then @path is value
      else if value instanceof RegExp then value.test @path
      else if value instanceof Path then  @path is value.path
      else throw new TypeError 'equals() requires either string, regex, or Path'
    else false

  _mustExist: (msg) ->
    unless @isReal() then throw new Error "path must exist #{msg}"

  _optionsAndDone: (options, done) ->
    if not done?
      if 'function' is typeof options
        done = options
        options = null
      else if options?
        if options.done?
          done = options.done
          delete options.done
    return options:options, done:done

  _createStream: (options, done, creator) ->
    {options, done} = @_optionsAndDone options, done
    if done?
      process.nextTick =>
        try
          done undefined, creator @path, options
        catch error
          done error
    else
      creator @path, options

  reader: (options, done) ->
    @_mustExist 'to read from it'
    @_createStream options, done, (path, options) ->
      fs.createReadStream path, options

  writer: (options, done) ->
    @_createStream options, done, (path, options) ->
      fs.createWriteStream path, options

  read: (options, done) ->
    @_mustExist 'to read from it'
    {options, done} = @_optionsAndDone options, done
    fn = if done? then fs.readFile else fs.readFileSync
    fn @path, options, done

  write: (data, options, done) ->
    {options, done} = @_optionsAndDone options, done
    fn = if done? then fs.writeFile else fs.writeFileSync
    fn @path, data, options, done

  append: (data, options, done) ->
    {options, done} = @_optionsAndDone options, done
    fn = if done? then fs.appendFile else fs.appendFileSync
    fn @path, data, options, done

  # stream: the stream to pipe the file's content to, or a path (call path.writer())
  # options: options for creating the reader and adding events to the reader
  # options.reader: the options to pass to reader()
  # options.writer: the options to pass to writer()
  # options.events: the event/listener pairs to register with the reader
  pipe: (pathOrStream, options) ->
    reader = @reader options?.reader
    reader.on event, listener for event,listener of options?.events?.reader
    pathOrStream = pathOrStream.writer options?.writer if pathOrStream instanceof Path
    pathOrStream.on event, listener for event,listener of options?.events?.writer
    return reader.pipe pathOrStream

  list: (options, done) ->
    @_mustExist 'to list directory'
    {options, done} = @_optionsAndDone options, done
    done ?= options?.all
    # TODO: allow a `returnType` option which has us store result in an object
    #       instead of an array?
    if done?
      fs.readdir @path, (error, array) =>
        if error? then return done error
        done? undefined, @_processList options, done, array
    else
      array = fs.readdirSync @path
      @_processList options, done, array

  _processList: (options, done, array) ->
    acceptString = options?.acceptString
    acceptPath   = options?.acceptPath
    each   = options?.each
    paths = []
    rejectedStrings = rejectedPaths = 0

    for string in array
      if not acceptString? or acceptString string
        path = @to string
        if not acceptPath? or acceptPath path
          paths.push path
          each? path:path
        else
          rejectedPaths++
      else
        rejectedStrings++

    return paths:paths, rejected:{strings:rejectedStrings, paths:rejectedPaths}

  files: (options, done) ->
    {options, done} = @_optionsAndDone options, done
    options ?= {}
    options.acceptPath ?= (path) -> path.isFile()
    @list options, done

  dirs: (options, done) ->
    {options, done} = @_optionsAndDone options, done
    options ?= {}
    options.acceptPath ?= (path) -> path.isDir()
    @list options, done

  # TODO: expect this path to be a file and reference file by name
  #file: (path) ->
  # read stats
  # ensure isFile() is true

  # TODO: expect this path to be a directory and reference directory by name
  #dir: (path) ->
  # read stats
  # ensure isDir() is true

  to: (path) ->
    unless path? then throw new Error 'must specify path to to()'
    if 'string' is typeof path
      newPath = corepath.join @path, path
      if newPath is @path then return this else return new Path newPath
    else if Array.isArray path
      new Path @parts.slice().concat path
    else throw new Error 'to(path) requires either a string or array of strings'

  resolve: (path) ->
    path = corepath.resolve @path, path
    if path is @path then this else new Path path

  relativeTo: (to) ->
    path = corepath.relative @path, to
    if path is @path then this else new Path path

  normalize: () ->
    normalized = corepath.normalize @path
    if normalized is @path then this else new Path normalized

  subpath: (start, end) -> new Path (if @path is '/' then '' else @parts[start...end])

  part: (index) -> @parts[index]

# Use these ways:
#  1a. {Path} = require 'fspath'
#  1b. Path = require('fspath').Path
#      path = new Path 'some/path'
#  2. buildPath = require 'fspath'
#     path      = buildPath 'some/path'
#  3. path = require('fspath') 'some/path'
module.exports = (path) -> new Path path
module.exports.Path = Path
