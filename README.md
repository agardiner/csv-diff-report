# CSV-Diff Report

CSV-Diff Report is a command-line tool for generating diff reports in Excel or
HTML format from CSV files. It uses the CSV-Diff gem to perform diffs, and adds
to that library the ability to generate formatted reports, and a command-line
tool `csvdiff` for running diffs between files or directories.


## CSV-Diff

Unlike a standard diff that compares line by line, and is sensitive to the
ordering of records, CSV-Diff identifies common lines by key field(s), and
then compares the contents of the fields in each line.

CSV-Diff is particularly well suited to data in parent-child format. Parent-
child data does not lend itself well to standard text diffs, as small changes
in the organisation of the tree at an upper level can lead to big movements
in the position of descendant records. By instead matching records by key,
CSV-Diff avoids this issue, while still being able to detect changes in
sibling order.


## Usage

CSV-Diff Report is supplied as a gem, and has dependencies on a few small libraries.
To install it, simply:
```
gem install csv-diff-report
```

To compare two CSV files where the field names are in the first row of the file,
and the first field contains the unique key for each record, simply use:
```
csvdiff <file1> <file2>
```

The `csvdiff` command-line tool provides many options to control behaviour of
the diff and reporting process. To see all available options, run:
```
csv-diff --help
```

This will display a help screen like the following:
```
CSV-Diff
========

Generate a diff report between two files using the CSV-Diff algorithm.


USAGE
-----
  ruby /usr/local/opt/ruby/bin/csvdiff FROM TO [OPTIONS]

  FROM    The file or dir to use as the left or from source in the diff
  TO      The file or dir to use as the right or to source in the diff


OPTIONS
-------

Source Options
  --pattern PATTERN                A file name pattern to use to filter matching files if a directory diff is
                                   being performed
                                   [Default: *]
  --field-names FIELD-NAMES        A comma-separated list of field names for each field in the source files
  --parent-fields PARENT-FIELDS    The parent field name(s) or index(es)
  --child-fields CHILD-FIELDS      The child field name(s) or index(es)
  --key-fields KEY-FIELDS          The key field name(s) or index(es)
  --encoding ENCODING              The encoding to use when opening the CSV files
  --ignore-header                  If true, the first line in each source file is ignored; requires the use of
                                   the --field-names option to name the fields

Diff Options
  --ignore-fields IGNORE-FIELDS    The names or indexes of any fields to be ignored during the diff
  --ignore-adds                    If true, items in TO that are not in FROM are ignored
  --ignore-deletes                 If true, items in FROM that are not in TO are ignored
  --ignore-updates                 If true, changes to non-key properties are ignored
  --ignore-moves                   If true, changes in an item's position are ignored

Output Options
  --format FORMAT                  The format in which to produce the diff report
                                   [Default: HTML]
  --output OUTPUT                  The path to save the diff report to. If not specified, the diff report will
                                   be placed in the same directory as the FROM file, and will be named
                                   Diff_<FROM>_to_<TO>.<FORMAT>

```


## .csvdiff Files

The csvdiff command-line tool supports both file and directory diffs. As
directories may contain files of different formats, .csvdiff files can be
used to match file names to file types, and specify the appropriate diff
settings for each file type.

A .csvdiff file can be placed in either the working directory from which the
csvdiff command is run, or the FROM directory. It consists of a YAML-formatted
file with the following top-level keys:

- defaults: Contains settings to be applied across all file types unless
  overridden for a specific file type.
- file_types: A hash whose keys are the file type labels used to describe
  files of that type, and whose values are the various diff settings to use
  for that file type.

### .csvdiff Settings

All settings that can be specified on the command-line can also be specified via
.csvdiff for each file type. In addition, several additional settings are
available via .csvdiff that are not available on the command-line. These
additional settings are as follows:

- pattern: Specifies the file name pattern that is used to match a file name to
  a file type. File types are checked in the order listed, so more general
  patterns must appear later in the .csvdiff file to avoid masking more specific
  patterns; e.g. a pattern of * will match every file, so it should appear as
  the pattern setting of the last entry in the file_types hash to ensure other
  more specific patterns get a chance to match a given file name first.
- exclude_pattern: Specifies an exclusion pattern for file names. Can be useful
  when a single pattern is correct for a file-type but for a class of exceptions.
- ignore: A boolean flag that can be used to ignore processing of matching files.
  Useful when a directory contains files that should not be diffed in addition to
  those that should.
- include: A Hash of field names or indexes to either a regular expression or a
  lambda expression which must be satisfied for records in the source to be diffed.
  Any records with values in the corresponding columns will not be included in the
  diff if the value in that column does not satisfy the regular expression or
  lambda.
- exclude: A Hash of field names or indexes to either a regular expression or a
  lambda expression which must *not* be satisfied for records in the source to be
  diffed. Any records with values in the corresponding columns will not be included
  in the diff if the value in that column satisfies the regular expression or
  lambda.


## Unique Row Identifiers

CSVDiff is preferable over a standard line-by-line diff when row order is
significantly impacted by small changes. The classic example is a parent-child
file generated by a hierarchy traversal. A simple change in position of a parent
member near the root of the hierarchy will have a large impact on the positions
of all descendant rows. Consider the following example:
```
Root
  |- A
  |  |- A1
  |  |- A2
  |
  |- B
     |- B1
     |- B2
```

A hierarchy traversal of this tree into a parent-child format would generate a CSV
as follows:
```
Root,A
A,A1
A,A2
Root,B
B,B1
B,B2
```

If the positions of A and B were swapped, a hierarchy traversal would now produce a CSV
as follows:
```
Root,B
B,B1
B,B2
Root,A
A,A1
A,A2
```

A simple diff using a diff utility would highlight this as 3 additions and 3 deletions.
CSVDiff, however, would classify this as 2 moves (a change in sibling position for A and B).

In order to do this, CSVDiff needs to know what field(s) confer uniqueness on each row.
In this example, we could use the child field alone (since each member name only appears
once); however, this would imply a flat structure, where all rows are children of a single
parent. This in turn would cause CSVDiff to classify the above change as a Move (i.e. a
change in order) of all 6 rows.

The more correct specification of this file is that column 0 contains a unique parent
identifier, and column 1 contains a unique child identifier. CSVDiff can then correctly
deduce that there is in fact only two changes in order - the swap in positions of A and
B below Root.

Note: If you aren't interested in changes in the order of siblings, then you could use
CSVDiff with a :key_field option of column 1, and specify the :ignore_moves option.


## Warnings

When processing and diffing files, CSVDiff may encounter problems with the data or
the specifications it has been given. It will continue even in the face of problems,
but will log details of the problems in a #warnings Array. The number of warnings
will also be included in the Hash returned by the #summary method.

Warnings may be raised for any of the following:
* Missing fields: If the right/to file contains fields that are not present in the
  left/from file, a warning is raised and the field is ignored for diff purposes.
* Duplicate keys: If two rows are found that have the same values for the key field(s),
  a warning is raised, and the duplicate values are ignored.


## Examples

The simplest use case is as shown above, where the data to be diffed is in CSV files
with the column names as the first record, and where the unique key is the first
column in the data. In this case, a diff can be created simply via:
```ruby
diff = CSVDiff.new(file1, file2)
```

### Specifynig Unique Row Identifiers

Often however, rows are not uniquely identifiable via the first column in the file.
In a parent-child hierarchy, for example, combinations of parent and child may be
necessary to uniquely identify a row. In these cases, it is necessary to indicate
which fields are used to uniquely identify common rows across the two files. This
can be done in several different ways.

1. Using the :key_fields option with field numbers (these are 0-based):

    ```ruby
    diff = CSVDiff.new(file1, file2, key_fields: [0, 1])
    ```

2. Using the :key_fields options with column names:

    ```ruby
    diff = CSVDiff.new(file1, file2, key_fields: ['Parent', 'Child'])
    ```

3. Using the :parent_fields and :child_fields with field numbers:

    ```ruby
    diff = CSVDiff.new(file1, file2, parent_field: 1, child_fields: [2, 3])
    ```

4. Using the :parent_fields and :child_fields with column names:

    ```ruby
    diff = CSVDiff.new(file1, file2, parent_field: 'Date', child_fields: ['HomeTeam', 'AwayTeam'])
    ```

### Using Non-CSV File Sources

Data from non-CSV sources can be diffed, as long as it can be supplied as an Array
of Arrays:
```ruby
DATA1 = [
    ['Parent', 'Child', 'Description'],
    ['A', 'A1', 'Account 1'],
    ['A', 'A2', 'Account 2']
]

DATA2 = [
    ['Parent', 'Child', 'Description'],
    ['A', 'A1', 'Account1'],
    ['A', 'A2', 'Account2']
]

diff = CSVDiff.new(DATA1, DATA2, key_fields: [1, 0])
```

### Specifying Column Names

If your data file does not include column headers, you can specify the names of
each column when creating the diff. The names supplied are the keys used in the
diff results:

```ruby
DATA1 = [
    ['A', 'A1', 'Account 1'],
    ['A', 'A2', 'Account 2']
]

DATA2 = [
    ['A', 'A1', 'Account1'],
    ['A', 'A2', 'Account2']
]

diff = CSVDiff.new(DATA1, DATA2, key_fields: [1, 0], field_names: ['Parent', 'Child', 'Description'])
```

If your data file does contain a header row, but you wish to use your own column
names, you can specify the :field_names option and the :ignore_header option to
ignore the first row.


### Ignoring Fields

If your data contains fields that you aren't interested in, these can be excluded
from the diff process using the :ignore_fields option:
```ruby
diff = CSVDiff.new(file1, file2, parent_field: 'Date', child_fields: ['HomeTeam', 'AwayTeam'],
                   ignore_fields: ['CreatedAt', 'UpdatedAt'])
```

### Filtering Rows

If you need to filter source data before running the diff process, you can use the :include
and :exclude options to do so. Both options take a Hash as their value; the hash should have
keys that are the field names or indexes (0-based) on which to filter, and whose values are
regular expressions or lambdas to be applied to values of the corresponding field. Rows will
only be diffed if they satisfy :include conditions, and do not satisfy :exclude conditions.
```ruby
# Generate a diff of Arsenal home games not refereed by Clattenburg
diff = CSVDiff.new(file1, file2, parent_field: 'Date', child_fields: ['HomeTeam', 'AwayTeam'],
                   include: {HomeTeam: 'Arsenal'}, exclude: {Referee: /Clattenburg/})

# Generate a diff of games played over the Xmas/New Year period
diff = CSVDiff.new(file1, file2, parent_field: 'Date', child_fields: ['HomeTeam', 'AwayTeam'],
                   include: {Date: lambda{ |d| holiday_period.include?(Date.strptime(d, '%y/%m/%d')) } })
```

### Ignoring Certain Changes

CSVDiff identifies Adds, Updates, Moves and Deletes; any of these changes can be selectively
ignored, e.g. if you are not interested in Deletes, you can pass the :ignore_deletes option:
```ruby
diff = CSVDiff.new(file1, file2, parent_field: 'Date', child_fields: ['HomeTeam', 'AwayTeam'],
                   ignore_fields: ['CreatedAt', 'UpdatedAt'],
                   ignore_deletes: true, ignore_moves: true)
```
