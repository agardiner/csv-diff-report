GEMSPEC = Gem::Specification.new do |s|
    s.name = "csv-diff-report"
    s.version = "0.2"
    s.authors = ["Adam Gardiner"]
    s.date = "2014-08-11"
    s.summary = "CSV Diff Report is a library for generating diff reports using the CSV Diff gem"
    s.description = <<-EOQ
        This library generates diff reports of CSV files, using the diff capabilities
        of the CSV Diff gem.

        Unlike a standard diff that compares line by line, and is sensitive to the
        ordering of records, CSV Diff identifies common lines by key field(s), and
        then compares the contents of the fields in each line.

        CSV Diff Report takes the diff information calculated by CSV Diff, and uses it to produce
        Excel or HTML-based diff reports. It also provides a command-line tool for generating
        these diff reports from CSV files.
    EOQ
    s.email = "adam.b.gardiner@gmail.com"
    s.homepage = 'https://github.com/agardiner/csv-diff-report'
    s.require_paths = ['lib']
    s.files = ['README.md', 'LICENSE'] + Dir['lib/**/*.rb']

    s.add_runtime_dependency 'csv-diff', '>= 0.1'
    s.add_runtime_dependency 'arg-parser', '>= 0.1'
    s.add_runtime_dependency 'color-console', '>= 0.1'
    s.add_runtime_dependency 'axlsx', '~> 1.3'
    s.bindir = 'bin'
    s.executables << 'csvdiff'
end
