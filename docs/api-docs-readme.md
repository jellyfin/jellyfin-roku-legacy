# Welcome

Use the `Modules` dropdown or the search feature to find files and functions to inspect

## Known Issues

- BrighterScript namespaces:
  - Duplicate function names will prevent the entire file from being parsed by JSDoc i.e. having `namespace.red.Delete()` and `namespace.blue.Delete()`
- When viewing source files:
  - The syntax highlighter doesn't support BrightScript and will treat all source files as JavaScript.
  - The page scrolls to the correct line number but it does not highlight the selected line.
