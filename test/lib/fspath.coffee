fs       = require 'fs'
assert   = require 'assert'
corepath = require 'path'
strung   = require 'strung'
slash    = corepath.sep
Path     = require '../../lib'

# lean path ops:
#  1. avoid as much work as possible
#  2. don't do anything in constructor we don't have to
#  3. change all props to functions which figure things out. cache results
#  4. have refresh() update cached values, all from stats, right?

describe 'test Path', ->

  tests =
    relative:
      path : 'some' + slash + 'test' + slash + 'string'
      parts: ['some', 'test', 'string']
    absolute:
      path : slash + 'some' + slash + 'test' + slash + 'string'
      parts: ['', 'some', 'test', 'string']

  pathArray = [
    undefined
    null
    ''
    '.'
    '..'
    'path'
    './path'
    '../path'
    'path/more'
    'path/more/more'
    'path/more/'
    'path/more/more/'
    './path/more'
    './path/more/more'
    './path/more/'
    './path/more/more/'
    '../path/more'
    '../path/more/more'
    '../path/more/'
    '../path/more/more/'
    '/'
    '/path'
    '/path/more'
    '/path/more/'
    '/./path'
    '/./path/'
  ]

  rootFiles = [
    '.gitignore', '.npmignore', '.travis.yml', 'LICENSE', 'README.md', 'package.json'
  ]
  rootDirs = [ '.git', 'lib', 'test', 'node_modules' ]
  rootPaths = [].concat(rootDirs).concat(rootFiles)


  # path.path
  describe 'constructor', ->

    ctorTest = (pathType, valueType) ->
      describe 'from ' + pathType + ' ' + valueType, ->
        it 'should have matching path/parts', ->
          test = tests[pathType]
          path = new Path test[valueType]
          assert.equal path.path, test.path
          assert.deepEqual path.parts,test.parts

    ctorTest 'relative', 'path'
    ctorTest 'relative', 'parts'
    ctorTest 'absolute', 'path'
    ctorTest 'absolute', 'parts'

  # path.startsWith
  describe 'startsWith', ->
    path = new Path tests.relative.path
    it 'with undefined should return false',     -> assert.equal path.startsWith(undefined), false
    it 'with null should return false',          -> assert.equal path.startsWith(null), false
    it 'with empty string should return false',  -> assert.equal path.startsWith(''), false
    it 'with wrong string should return false',  -> assert.equal path.startsWith('some/wrong/path'), false
    it 'with correct string should return true', -> assert.equal path.startsWith(tests.relative.path), true

  # path.endsWith
  describe 'endsWith', ->
    path = new Path tests.relative.path
    it 'with undefined should return false',     -> assert.equal path.endsWith(undefined), false
    it 'with null should return false',          -> assert.equal path.endsWith(null), false
    it 'with empty string should return false',  -> assert.equal path.endsWith(''), false
    it 'with wrong string should return false',  -> assert.equal path.endsWith('some/wrong/path'), false
    it 'with correct string should return true', -> assert.equal path.endsWith(tests.relative.path), true


  # path.equals(Path|string)
  describe 'equals', ->
    path1 = new Path tests.relative.path
    path2 = new Path tests.relative.path
    path3 = new Path tests.absolute.path
    it 'with undefined should return false',     -> assert.equal path1.equals(undefined), false
    it 'with null should return false',          -> assert.equal path1.equals(null), false
    it 'with empty string should return false',  -> assert.equal path1.equals(''), false
    it 'with wrong string should return false',  -> assert.equal path1.equals('some/wrong/path'), false
    it 'with correct string should return true', -> assert.equal path1.equals(tests.relative.path), true
    it 'with wrong regex should return false',   -> assert.equal path1.equals(/some wrong regex/), false
    it 'with correct regex should return true',  -> assert.equal path1.equals(/some\/test\/string/), true
    it 'with matching Path should return true',  -> assert.equal path1.equals(path2), true
    it 'with different Path should return false',-> assert.equal path1.equals(path3), false


  # path.isReal
  describe 'isReal', ->
    for string,result of {
      '.':true
      './':true
      './lib':true
      './lib/index.coffee':true
      '../node-fspath':true
      '../node-fspath/package.json':true
      './fake':false
      './fake.file':false
    }
      do (string,result) ->
        it 'with [' + string + '] should return [' + result + ']', (done) ->
          path = new Path string
          assert.equal path.isReal(), result
          path.isReal (error, isReal) ->
            if error? and result isnt false then return done error
            assert.strictEqual isReal, result
            done()

  # path.isFile
  describe 'isFile', ->
    for string,result of {
      '.':false
      './':false
      './lib':false
      './lib/index.coffee':true
      '../node-fspath':false
      '../node-fspath/package.json':true
      './fake':false
      './fake.file':false
    }
      do (string,result) ->
        it 'with [' + string + '] should return [' + result + ']', (done) ->
          path = new Path string
          assert.equal path.isFile(), result
          path.isFile (error, isFile) ->
            if error? and result isnt false then return done error
            assert.strictEqual isFile, result
            done()


  # path.isDir
  describe 'isDir', ->
    for string,result of {
      '.':true
      './':true
      './lib':true
      './lib/index.coffee':false
      '../node-fspath':true
      '../node-fspath/package.json':false
      './fake':false
      './fake.file':false
    }
      do (string,result) ->
        it 'with [' + string + '] should return [' + result + ']', (done) ->
          path = new Path string
          assert.equal path.isDir(), result
          path.isDir (error, isDir) ->
            if error? and result isnt false then return done error
            assert.strictEqual isDir, result
            done()


  # path.isRelative
  describe 'isRelative', ->
    for path,result of {
      '':true
      '.':true
      '..':true
      'path':true
      './path':true
      '../path':true
      'path/more':true
      'path/more/more':true
      'path/more/':true
      'path/more/more/':true
      './path/more':true
      './path/more/more':true
      './path/more/':true
      './path/more/more/':true
      '../path/more':true
      '../path/more/more':true
      '../path/more/':true
      '../path/more/more/':true
      '/':false
      '/path':false
      '/path/more':false
      '/path/more/':false
      '/./path':false
      '/./path/':false
      '\\':false
      'C:':false
      'C:\\':false
      'C:\\some\\path':false
    }
      do (path,result) ->
        it 'with |' + path + '| should return |' + result + '|', ->
          assert.equal new Path(path).isRelative, result

  # path.isAbsolute
  describe 'isAbsolute', ->
    for path,result of {
      '':false
      '.':false
      '..':false
      'path':false
      './path':false
      '../path':false
      'path/more':false
      'path/more/more':false
      'path/more/':false
      'path/more/more/':false
      './path/more':false
      './path/more/more':false
      './path/more/':false
      './path/more/more/':false
      '../path/more':false
      '../path/more/more':false
      '../path/more/':false
      '../path/more/more/':false
      '/':true
      '/path':true
      '/path/more':true
      '/path/more/':true
      '/./path':true
      '/./path/':true
      '\\':true
      'C:':true
      'C:\\':true
      'C:\\some\\path':true
    }
      do (path,result) ->
        it 'with [' + path + '] should return [' + result + ']', ->
          assert.equal new Path(path).isAbsolute, result

  # path.isCanonical
  describe 'isCanonical', ->
    for path,result of {
      '':true
      '.':false
      '..':false
      'path':true
      './path':false
      '../path':false
      'path/more':true
      'path/more/more':true
      'path/more/':true
      'path/more/more/':true
      './path/more':false
      './path/more/more':false
      './path/more/':false
      './path/more/more/':false
      '../path/more':false
      '../path/more/more':false
      '../path/more/':false
      '../path/more/more/':false
      '/':true
      '/path':true
      '/path/more':true
      '/path/more/':true
      '/./path':false
      '/./path/':false
    }
      do (path,result) ->
        it 'with [' + path + '] should return [' + result + ']', ->
          assert.equal new Path(path).isCanonical(), result

  # path.normalize
  describe 'normalize', ->
    for path in pathArray
      do (path) ->
        it 'with ' + path, ->
          expected = if path? then corepath.normalize path else corepath.normalize process.cwd()
          assert.equal new Path(path).normalize().path, expected


  # path.resolve
  describe 'resolve', ->
    for path1,path2 of {
      '':'one/two'
      '.':'one/two'
      '..':'one/two'
      'path':'one/two'
      './path':'one/two'
      '../path':'one/two'
      'path/more':'one/two'
      'path/more/more':'one/two'
      'path/more/':'one/two'
      'path/more/more/':'one/two'
      './path/more':'one/two'
      './path/more/more':'one/two'
      './path/more/':'one/two'
      './path/more/more/':'one/two'
      '../path/more':'one/two'
      '../path/more/more':'one/two'
      '../path/more/':'one/two'
      '../path/more/more/':'one/two'
      '/':'one/two'
      '/path':'one/two'
      '/path/more':'one/two'
      '/path/more/':'one/two'
      '/./path':'one/two'
      '/./path/':'one/two'
      '':'/one/two'
      '.':'/one/two'
      '..':'/one/two'
      'path':'/one/two'
      './path':'/one/two'
      '../path':'/one/two'
      'path/more':'/one/two'
      'path/more/more':'/one/two'
      'path/more/':'/one/two'
      'path/more/more/':'/one/two'
      './path/more':'/one/two'
      './path/more/more':'/one/two'
      './path/more/':'/one/two'
      './path/more/more/':'/one/two'
      '../path/more':'/one/two'
      '../path/more/more':'/one/two'
      '../path/more/':'/one/two'
      '../path/more/more/':'/one/two'
      '/':'/one/two'
      '/path':'/one/two'
      '/path/more':'/one/two'
      '/path/more/':'/one/two'
      '/./path':'/one/two'
      '/./path/':'/one/two'
    }
      do (path1,path2) ->
        it 'with ' + path1 + ' should return ' + path2, ->
          assert.equal new Path(path1).resolve(path2).path, corepath.resolve path1, path2


  # path.relativeTo
  describe 'relativeTo', ->
    for path1,path2 of {
      '':'one/two'
      '.':'one/two'
      '..':'one/two'
      'path':'one/two'
      './path':'one/two'
      '../path':'one/two'
      'path/more':'one/two'
      'path/more/more':'one/two'
      'path/more/':'one/two'
      'path/more/more/':'one/two'
      './path/more':'one/two'
      './path/more/more':'one/two'
      './path/more/':'one/two'
      './path/more/more/':'one/two'
      '../path/more':'one/two'
      '../path/more/more':'one/two'
      '../path/more/':'one/two'
      '../path/more/more/':'one/two'
      '/':'one/two'
      '/path':'one/two'
      '/path/more':'one/two'
      '/path/more/':'one/two'
      '/./path':'one/two'
      '/./path/':'one/two'
      '':'/one/two'
      '.':'/one/two'
      '..':'/one/two'
      'path':'/one/two'
      './path':'/one/two'
      '../path':'/one/two'
      'path/more':'/one/two'
      'path/more/more':'/one/two'
      'path/more/':'/one/two'
      'path/more/more/':'/one/two'
      './path/more':'/one/two'
      './path/more/more':'/one/two'
      './path/more/':'/one/two'
      './path/more/more/':'/one/two'
      '../path/more':'/one/two'
      '../path/more/more':'/one/two'
      '../path/more/':'/one/two'
      '../path/more/more/':'/one/two'
      '/':'/one/two'
      '/path':'/one/two'
      '/path/more':'/one/two'
      '/path/more/':'/one/two'
      '/./path':'/one/two'
      '/./path/':'/one/two'
    }
      do (path1,path2) ->
        it 'with ' + path1 + ' and ' + path2, ->
          assert.equal new Path(path1).relativeTo(path2).path, corepath.relative path1, path2


  # path.parent
  describe 'parent', ->
    for path,result of [
      ''
      '.'
      '..'
      'path'
      'path/'
      './path'
      '../path'
      'path/more'
      'path/more/'
      'path/some/more'
      'path/some/more/'
      './path/more'
      './path/more/'
      './path/some/more'
      './path/some/more/'
      '../path/more'
      '../path/more/'
      '../path/some/more'
      '../path/some/more/'
      '/'
      '/path'
      '/path/more'
      '/path/more/'
      '/./path'
      '/./path/'
    ]
      do (path,result) ->
        it 'with [' + path + '] should match corepath.join(path, ..)', ->
          expected = corepath.join path, '..'
          assert.equal new Path(path).parent().path, expected
          # test a second time because value is cached
          assert.equal new Path(path).parent().path, expected, 'cached value should be the same'


  # path.filename
  describe 'filename', ->
    for path in pathArray
      do (path) ->
        it 'with [' + path + '] should match corepath.filename', ->
          expected =
            if path? then corepath.basename(path, corepath.extname path)
            else corepath.basename process.cwd()
          assert.equal new Path(path).filename(), expected
          # test a second time because value is cached
          assert.equal new Path(path).filename(), expected, 'cached value should be the same'


  # path.basename # accept an extension to exclude?
  describe 'basename', ->
    for path in pathArray
      do (path) ->
        it 'with [' + path + '] should match corepath.basename', ->
          expected =
            if path? then corepath.basename path
            else corepath.basename process.cwd()
          assert.equal new Path(path).basename(), expected
          # test a second time because value is cached
          assert.equal new Path(path).basename(), expected, 'cached value should be the same'

  # path.extname # -> alias of path.ext ?
  describe 'extname', ->
    for path in pathArray
      do (path) ->
        it 'with [' + path + '] should match corepath.extname', ->
          expected =
            if path? then corepath.extname path
            else corepath.extname process.cwd()
          assert.equal new Path(path).extname(), expected
          # test a second time because value is cached
          assert.equal new Path(path).extname(), expected, 'cached value should be the same'

  # path.dirname # -> alias of parent ?
  describe 'dirname', ->
    for path in pathArray
      do (path) ->
        it 'with [' + path + '] should match corepath.dirname', ->
          expected = corepath.basename corepath.dirname if path? then path else process.cwd()
          actual = new Path(path).dirname()
          assert.equal actual, expected
          # test a second time because value is cached
          assert.equal actual, expected, 'cached value should be the same'

  # path.up(#)
  describe 'up', ->
    for path,count of {
      '':1
      '.':1
      '..':1
      'path':1
      './path':1
      '../path':1
      'path/more':1
      'path/some/more':1
      'path/more/':1
      'path/some/more/':1
      './path/more':1
      './path/more/more':1
      './path/more/':1
      './path/more/more/':1
      '../path/more':1
      '../path/more/more':1
      '../path/more/':1
      '../path/more/more/':1
      '/':1
      '/path':1
      '/path/more':1
      '/path/more/':1
      '/./path':1
      '/./path/':1

      '':2
      '.':2
      '..':2
      'path':2
      './path':2
      '../path':2
      'path/more':2
      'path/more/':2
      'path/some/more':2
      'path/some/more/':2
      './path/more':2
      './path/more/':2
      './path/some/more':2
      './path/some/more/':2
      '../path/more':2
      '../path/more/':2
      '../path/some/more':2
      '../path/some/more/':2
      '/':2
      '/path':2
      '/path/more':2
      '/path/more/':2
      '/./path':2
      '/./path/':2
    }
      do (path,count) ->
        it '(' + count + ') with [' + path + "] should match corepath.join with \'..\'^#{count} ", ->
          joins = []
          joins.push '..' for i in [0...count]
          expected = corepath.join path, joins...
          assert.equal new Path(path).up(count).path, expected

  # path.to
  describe 'to', ->
    for path,to of {
      '':'../'
      '.':'../'
      '..':'../..'
      'path':''
      './path':''
      '../path':'../'
      'path/more':'path'
      'path/some/more':'path/some'
      'path/more/':'path'
      'path/some/more/':'path/some'
      './path/more':'./path'
      './path/more/more':'./path/more'
      './path/more/':'./path'
      './path/more/more/':'./path/more'
      '../path/more':'../path'
      '../path/more/more':'../path/more'
      '../path/more/':'../path'
      '../path/more/more/':'../path/more'
      '/':''
      '/path':'/'
      '/path/more':'/path'
      '/path/more/':'/path'
      '/./path':'/'
      '/./path/':'/'
    }
      do (path,to) ->
        it 'with [' + path + '] to ' + to, ->
          assert.equal new Path(path).to(to), corepath.join path, to

  # path.subpath
  describe 'subpath', ->
    for path,test of {
      '':{start:0,end:1,result:''}
      '.':{start:0,end:1,result:''}
      '..':{start:0,end:1,result:'..'}
      'path':{start:0,end:1,result:'path'}
      './path':{start:0,end:1,result:'.'}
      '../path':{start:0,end:1,result:'..'}
      'path/more':{start:0,end:1,result:'path'}
      'path/some/more':{start:0,end:1,result:'path'}
      'path/more/':{start:0,end:1,result:'path'}
      'path/some/more/':{start:0,end:1,result:'path'}
      './path/more':{start:0,end:1,result:'.'}
      './path/more/more':{start:0,end:1,result:'.'}
      './path/more/':{start:0,end:1,result:'.'}
      './path/more/more/':{start:0,end:1,result:'.'}
      '../path/more':{start:0,end:1,result:'..'}
      '../path/more/more':{start:0,end:1,result:'..'}
      '../path/more/':{start:0,end:1,result:'..'}
      '../path/more/more/':{start:0,end:1,result:'..'}
      '/':{start:0,end:1,result:''}
      '/path':{start:0,end:1,result:'/'}
      '/path/more':{start:0,end:1,result:'/'}
      '/path/more/':{start:0,end:1,result:'/'}
      '/./path':{start:0,end:1,result:'/'}
      '/./path/':{start:0,end:1,result:'/'}

      '':{start:1,end:1,result:''}
      '.':{start:1,end:1,result:''}
      '..':{start:1,end:1,result:''}
      'path':{start:1,end:1,result:''}
      './path':{start:1,end:1,result:''}
      '../path':{start:1,end:1,result:''}
      'path/more':{start:1,end:1,result:''}
      'path/more/':{start:1,end:1,result:''}
      'path/some/more':{start:1,end:1,result:''}
      'path/some/more/':{start:1,end:1,result:''}
      './path/more':{start:1,end:1,result:''}
      './path/more/':{start:1,end:1,result:''}
      './path/some/more':{start:1,end:1,result:''}
      './path/some/more/':{start:1,end:1,result:''}
      '../path/more':{start:1,end:1,result:''}
      '../path/more/':{start:1,end:1,result:''}
      '../path/some/more':{start:1,end:1,result:''}
      '../path/some/more/':{start:1,end:1,result:''}
      '/':{start:1,end:1,result:''}
      '/path':{start:1,end:1,result:''}
      '/path/more':{start:1,end:1,result:''}
      '/path/more/':{start:1,end:1,result:''}
      '/./path':{start:1,end:1,result:''}
      '/./path/':{start:1,end:1,result:''}

      '':{start:1,end:2,result:''}
      '.':{start:1,end:2,result:''}
      '..':{start:1,end:2,result:''}
      'path':{start:1,end:2,result:''}
      './path':{start:1,end:2,result:'path'}
      '../path':{start:1,end:2,result:'path'}
      'path/more':{start:1,end:2,result:'more'}
      'path/more/':{start:1,end:2,result:'more/'}
      'path/some/more':{start:1,end:2,result:'some'}
      'path/some/more/':{start:1,end:2,result:'some'}
      './path/more':{start:1,end:2,result:'path'}
      './path/more/':{start:1,end:2,result:'path'}
      './path/some/more':{start:1,end:2,result:'path'}
      './path/some/more/':{start:1,end:2,result:'path'}
      '../path/more':{start:1,end:2,result:'path'}
      '../path/more/':{start:1,end:2,result:'path'}
      '../path/some/more':{start:1,end:2,result:'path'}
      '../path/some/more/':{start:1,end:2,result:'path'}
      '/':{start:1,end:2,result:''}
      '/path':{start:1,end:2,result:'path'}
      '/path/more':{start:1,end:2,result:'path'}
      '/path/more/':{start:1,end:2,result:'path'}
      '/./path':{start:1,end:2,result:'.'}
      '/./path/':{start:1,end:2,result:'.'}

      '':{start:1,end:3,result:''}
      '.':{start:1,end:3,result:''}
      '..':{start:1,end:3,result:''}
      'path':{start:1,end:3,result:''}
      './path':{start:1,end:3,result:'path'}
      '../path':{start:1,end:3,result:'path'}
      'path/more':{start:1,end:3,result:'more'}
      'path/more/':{start:1,end:3,result:'more/'}
      'path/some/more':{start:1,end:3,result:'some/more'}
      'path/some/more/':{start:1,end:3,result:'some/more'}
      './path/more':{start:1,end:3,result:'path/more'}
      './path/more/':{start:1,end:3,result:'path/more'}
      './path/some/more':{start:1,end:3,result:'path/some'}
      './path/some/more/':{start:1,end:3,result:'path/some'}
      '../path/more':{start:1,end:3,result:'path/more'}
      '../path/more/':{start:1,end:3,result:'path/more'}
      '../path/some/more':{start:1,end:3,result:'path/some'}
      '../path/some/more/':{start:1,end:3,result:'path/some'}
      '/':{start:1,end:3,result:''}
      '/path':{start:1,end:3,result:'path'}
      '/path/more':{start:1,end:3,result:'path/more'}
      '/path/more/':{start:1,end:3,result:'path/more'}
      '/./path':{start:1,end:3,result:'./path'}
      '/./path/':{start:1,end:3,result:'./path'}
    }
      do (path,test) ->
        it "with '#{path}'[#{test.start}, #{test.end}]", ->
          assert.equal new Path(path).subpath(test.start, test.end).path, test.result


  # path.part(#)
  describe 'part', ->
    for path,test of {
      '':{index:0,result:''}
      '.':{index:0,result:'.'}
      '..':{index:0,result:'..'}
      'path':{index:0,result:'path'}
      './path':{index:0,result:'.'}
      '../path':{index:0,result:'..'}
      'path/more':{index:0,result:'path'}
      'path/some/more':{index:0,result:'path'}
      'path/more/':{index:0,result:'path'}
      'path/some/more/':{index:0,result:'path'}
      './path/more':{index:0,result:'.'}
      './path/more/more':{index:0,result:'.'}
      './path/more/':{index:0,result:'.'}
      './path/more/more/':{index:0,result:'.'}
      '../path/more':{index:0,result:'..'}
      '../path/more/more':{index:0,result:'..'}
      '../path/more/':{index:0,result:'..'}
      '../path/more/more/':{index:0,result:'..'}
      '/':{index:0,result:''}
      '/path':{index:0,result:''}
      '/path/more':{index:0,result:''}
      '/path/more/':{index:0,result:''}
      '/./path':{index:0,result:''}
      '/./path/':{index:0,result:''}

      '':{index:1,result:undefined}
      '.':{index:1,result:undefined}
      '..':{index:1,result:undefined}
      'path':{index:1,result:undefined}
      './path':{index:1,result:'path'}
      '../path':{index:1,result:'path'}
      'path/more':{index:1,result:'more'}
      'path/some/more':{index:1,result:'some'}
      'path/more/':{index:1,result:'more'}
      'path/some/more/':{index:1,result:'some'}
      './path/more':{index:1,result:'path'}
      './path/some/more':{index:1,result:'path'}
      './path/more/':{index:1,result:'path'}
      './path/some/more/':{index:1,result:'path'}
      '../path/more':{index:1,result:'path'}
      '../path/some/more':{index:1,result:'path'}
      '../path/more/':{index:1,result:'path'}
      '../path/some/more/':{index:1,result:'path'}
      '/':{index:1,result:undefined}
      '/path':{index:1,result:'path'}
      '/path/more':{index:1,result:'path'}
      '/path/more/':{index:1,result:'path'}
      '/./path':{index:1,result:'.'}
      '/./path/':{index:1,result:'.'}

      '':{index:2,result:undefined}
      '.':{index:2,result:undefined}
      '..':{index:2,result:undefined}
      'path':{index:2,result:undefined}
      './path':{index:2,result:undefined}
      '../path':{index:2,result:undefined}
      'path/more':{index:2,result:undefined}
      'path/some/more':{index:2,result:'more'}
      'path/more/':{index:2,result:''}
      'path/some/more/':{index:2,result:'more'}
      './path/more':{index:2,result:'more'}
      './path/some/more':{index:2,result:'some'}
      './path/more/':{index:2,result:'more'}
      './path/some/more/':{index:2,result:'some'}
      '../path/more':{index:2,result:'more'}
      '../path/some/more':{index:2,result:'some'}
      '../path/more/':{index:2,result:'more'}
      '../path/some/more/':{index:2,result:'some'}
      '/':{index:2,result:undefined}
      '/path':{index:2,result:undefined}
      '/path/more':{index:2,result:'more'}
      '/path/more/':{index:2,result:'more'}
      '/./path':{index:2,result:'path'}
      '/./path/':{index:2,result:'path'}
    }
      do (path,test) ->
        it 'with [' + path + '] part #' + test.index, ->
          assert.equal new Path(path).part(test.index), test.result


  # path.reader
  describe 'async reader', -> it 'should read file \'file.txt\'', (done) ->
    target = strung()
    target.on 'error', done
    target.on 'finish', ->
      assert.equal target.string, 'file.txt\nsome test file\n'
      done()
    path = new Path 'test/helpers/file.txt'
    path.reader (error, reader) ->
      if error? then return done error
      reader.pipe target

  describe 'sync reader', -> it 'should read file \'file.txt\'', (done) ->
    target = strung()
    target.on 'error', done
    target.on 'finish', ->
      assert.equal target.string, 'file.txt\nsome test file\n'
      done()
    path = new Path 'test/helpers/file.txt'
    reader = path.reader()
    assert reader, 'should return a reader synchronously'
    reader.pipe target


  # path.writer
  describe 'sync writer', -> it 'should write file \'path.writer/.txt\'', (done) ->
    testFile = 'test/helpers/path.writer.txt'
    pretext = 'this line was output by writer.write\n'
    testContent = 'output by path.write test'
    source = strung testContent
    path = new Path testFile
    writer = path.writer()
    writer.on 'error', done
    writer.on 'finish', ->
      # test content of file... delete file
      fs.readFile testFile, 'utf8', (error, text) ->
        if error? then return done error
        fs.unlink testFile, (error) ->
          if error? then return done error
          assert.equal pretext+testContent, text
          done()
    writer.write pretext, 'utf8'
    source.pipe writer


  # path.read
  describe 'sync read', -> it 'should read file \'file.txt\'', ->
    path = new Path 'test/helpers/file.txt'
    text = path.read()
    assert.equal text, 'file.txt\nsome test file\n'

  describe 'async read', -> it 'should read file \'file.txt\'', (done) ->
    path = new Path 'test/helpers/file.txt'
    path.read {}, (error, text) ->
      if error? then return done error
      assert.equal text, 'file.txt\nsome test file\n'
      done()


  # path.write
  describe 'sync write', -> it 'should write file \'path.sync.write.txt\'', ->
    testFile = 'test/output/path.sync.write.txt'
    testContent = 'output by path.write test'
    path = new Path testFile
    path.write testContent
    text = fs.readFileSync testFile, encoding:'utf8'
    fs.unlinkSync testFile
    assert.equal text, testContent

  describe 'async write', -> it 'should write file \'path.async.write.txt\'', (done) ->
    testFile = 'test/output/path.async.write.txt'
    testContent = 'output by path.write test'
    path = new Path testFile
    path.write testContent, {}, (error) ->
      if error? then return done error
      fs.readFile testFile, encoding:'utf8', (error, text) ->
        if error? then return done error
        fs.unlink testFile, (error) ->
          if error? then return done error
          assert.equal text, testContent
          done()


  # path.append
  describe 'sync append', -> it 'should append file \'sync.append.txt\'', ->
    testFile = 'test/output/sync.append.txt'
    testContent = 'output by path.append test'
    testPreexisting = 'sync append\n'
    testResult  = testPreexisting + testContent
    path = new Path testFile
    path.append testContent
    text = fs.readFileSync testFile, encoding:'utf8'
    fs.writeFileSync testFile, testPreexisting, encoding:'utf8'
    assert.equal text, testResult

  describe 'async append', -> it 'should append file \'async.append.txt\'', (done) ->
    testFile = 'test/output/async.append.txt'
    testContent = 'output by path.append test'
    testPreexisting = 'async append\n'
    testResult  = testPreexisting + testContent
    path = new Path testFile
    path.append testContent, {}, (error) ->
      if error? then return done error
      fs.readFile testFile, encoding:'utf8', (error, text) ->
        if error? then return done error
        fs.writeFile testFile, testPreexisting, encoding:'utf8', (error) ->
          if error? then return done error
          assert.equal text, testResult
          done()


  # path.pipe
  describe '.pipe()', -> it 'should send file contents to stream', (done) ->
    target = strung()
    target.on 'error', done
    target.on 'finish', ->
      assert.equal target.string, 'file.txt\nsome test file\n'
      done()
    path = new Path 'test/helpers/file.txt'
    path.pipe target


  # path.list: async/sync => options:accept/each/all/done
  describe 'list', ->

    describe 'async', ->

      describe 'with only done callback', ->

        it 'should list all the project root paths', (done) ->
          path = new Path
          path.list (error, result) ->
            if error? then return done error
            for path in result.paths
              assert (path.path in rootPaths), 'results shouldnt have |' + path + '|'
            done()

      describe 'with only `done` option', ->

        it 'should list all the project root paths', (done) ->
          path = new Path
          path.list done:(error, result) ->
            if error? then return done error
            for path in result.paths
              assert (path.path in rootPaths), 'results shouldnt have |' + path + '|'
            done()

      describe 'with only `all` option', ->

        it 'should list all the project root paths', (done) ->
          path = new Path
          path.list all:(error, result) ->
            if error? then return done error
            for path in result.paths
              assert (path.path in rootPaths), 'results shouldnt have |' + path + '|'
            done()

      describe 'with `each` and `done` option', ->

        it 'should list all the project root paths', (done) ->
          path = new Path
          path.list
            each:(path) ->
              assert (path.path in rootPaths), 'each shouldnt receive : |' + path + '|'
            done: (error, result) ->
              if error? then return done error
              for path in result.paths
                assert (path.path in rootPaths), 'results shouldnt have |' + path + '|'
              done()


      describe 'with `accept` and `done` option', ->

        it 'should list all the project root paths', (done) ->
          path = new Path
          path.list
            acceptString: -> true
            done:(error, result) ->
              if error? then return done error
              for path in result.paths
                assert (path.path in rootPaths), 'results shouldnt have |' + path + '|'
              done()

      describe 'with `accept` \'lib\' and `done` option', ->

        it 'should list all the project root paths', (done) ->
          path = new Path
          path.list
            acceptString: (path) -> path is 'lib'
            done:(error, result) ->
              if error? then return done error
              assert.equal result?.paths?.length, 1,
                'result should only contain \'lib\' path'
              assert.equal result?.paths[0], 'lib'
              done()

    describe 'sync', ->

      describe 'with no options', ->

        it 'should list all the project root paths', ->
          path = new Path
          result = path.list()
          for path in result.paths
            assert (path.path in rootPaths), 'results shouldnt have |' + path + '|'

      describe 'with only `accept` option', ->

        it 'accept true should list all root paths', ->
          path = new Path
          result = path.list accept:-> true
          for path in result.paths
            assert (path.path in rootPaths), 'results shouldnt have |' + path + '|'

        it 'accept \'lib\' should only list lib', ->
          path = new Path
          result = path.list acceptString:(path) -> 'lib' is path
          assert.equal result?.paths?.length, 1, 'result should only contain \'lib\' path'
          assert.equal result?.paths[0], 'lib'

      describe 'with only `each` option', ->

        it 'should list all the project root paths', ->
          each = {}
          path = new Path
          result = path.list each:(path) -> each[path.path] = true
          for path in result.paths
            assert (path.path in rootPaths), 'results shouldnt have |' + path + '|'
          for path in rootPaths
            assert each[path]?, 'each should have received path: |' + path + '|'


  # path.files
  describe 'async files', ->
    it 'should list all files in project root', (done) ->
      path = new Path
      path.files (error, result) ->
        if error? then return done error
        for path in result.paths
          assert (path.path in rootFiles), 'results shouldnt have |' + path + '|'
        done()

  describe 'sync files', ->
    it 'should list all files in project root', ->
      path = new Path
      result = path.files()
      for path in result.paths
        assert (path.path in rootFiles), 'results shouldnt have |' + path + '|'


  # path.dirs
  describe 'async dirs', ->
    it 'should list all dirs in project root', (done) ->
      path = new Path
      path.dirs (error, result) ->
        if error? then return done error
        for path in result.paths
          assert (path.path in rootDirs), 'results shouldnt have |' + path + '|'
        done()

  describe 'sync dirs', ->
    it 'should list all dirs in project root', ->
      path = new Path
      result = path.dirs()
      for path in result.paths
        assert (path.path in rootDirs), 'results shouldnt have |' + path + '|'

  # path.reset
  describe 'reset', ->
    it 'should delete the cache and stored stats', ->
      path = new Path
      testObject = {}
      path._stats = testObject
      path._the   = testObject
      path.reset()
      assert.notStrictEqual path._stats, testObject
      assert.notStrictEqual path._the, testObject

  # path.refresh
  describe 'async refresh', ->
    it 'should replace stats with new object', (done) ->
      path = new Path
      testObject = {}
      path._stats = testObject
      path.refresh (error, stats) ->
        if error? then return done error
        assert.notStrictEqual path._stats, testObject, 'stats should have been replaced'
        done()

  describe 'sync refresh', ->
    it 'should replace stats with new object', ->
      path = new Path
      testObject = {}
      path._stats = testObject
      path.refresh()
      assert.notEqual path._stats, testObject, 'stats should have been replaced'
