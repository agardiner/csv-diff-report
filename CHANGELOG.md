# Change Log

## [0.4 - 2018-07-31]

### Fixed

  * Changed the --include-matched argument from a keyword argument to a flag
    argument.

### Added

  * If diff-lcs is available as a gem, then multi-line fields that have updates
    will show just the line(s) that have changed in the HTML diff, rather than
    showing the whole field old and new values.