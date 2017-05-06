## 0.15.0 - Released 2017/05/06

1. drop node 0.10 and 0.12, add 6, 7
2. update travis config with explicit sudo false, cache modules, submit coverage
3. add lint via coffeelint
4. rewrite a lot of implementation handling callbacks differently and more
5. change tests for rewrite
6. add tests for coverage
7. add 2017 to license
8. accept multiple args to `resolve()`
9. add missing `keywords` to `package.json`
10. specify minimum node is 4
11. DRY npm scripts


## 0.14.0 - Released 2015/11/07

1. exported builder function instead of class (which matches README...)
2. removed unnecessary `done` param from constructor
3. change README to call builder function `buildPath`
4. added nave module and testing on node versions 0.12 and 4.2
5. updated travis ci to test those versions too

## 0.13.0 - Released 2015/09/24

1. counts rejected strings and paths
2. each passes `path:path` instead of `path` to maintain result object pattern
3. test error messages uses `path.path` to get the string directly

## 0.12.3 - Released 2015/09/22

1. fixed undefined path to be '.' instead of process.cwd() so it's relative
2. fixed path listing uses to() instead of creating a new path

## 0.12.2 - Released 2015/09/21

1. fixed tests to include the added CHANGES file

## 0.12.1 - Released 2015/09/21

1. fixed typo in README code examples
2. added CHANGES file

## 0.12.0 - Released 2015/09/21
