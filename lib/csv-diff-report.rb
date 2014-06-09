require 'csv-diff'
require 'color-console'
require 'pathname'
require 'csv-diff-report/excel'
require 'csv-diff-report/html'


# Defines a class for generating diff reports using CSVDiff.
#
# A diff report may contain multiple file diffs, and can be output as either an
# XLSX spreadsheet document, or an HTML file.
class CSVDiffReport

    include Excel
    include Html


    # Instantiate a new diff report object.
    def initialize
        @diffs = []
    end


    # Add a CSVDiff object to this report.
    def <<(diff)
        if diff.is_a?(CSVDiff)
            @diffs << diff
        else
            raise ArgumentError, "Only CSVDiff objects can be added to a CSVDiffReport"
        end
    end


    # Add a diff to the diff report.
    #
    # @param options [Hash] Options to be passed to the diff process.
    def diff(left, right, options = {})
        left = Pathname.new(left)
        right = Pathname.new(right)
        if left.file? && right.file?
            diff_files(left, right, options)
        elsif left.directory? && right.directory?
            diff_dir(left, right, options)
        else
            raise ArgumentError, "Left and right must both exist and be files or directories"
        end
    end


    # Saves a diff report to +path+ in +format+.
    #
    # @param path [String] The path to the output report.
    # @param format [Symbol] The output format for the report; one of :html or
    #   :xlsx.
    def output(path, format = :html)
        path = case format.to_s
        when /^html$/i
            html_output(path)
        when /^xls(x)?$/i
            xl_output(path)
        else
            raise ArgumentError, "Unrecognised output format: #{format}"
        end
        Console.puts "Diff report saved to '#{path}'"
    end


    private


    # Diff files that exist in both +left+ and +right+ directories.
    def diff_dir(left, right, options)
        pattern = Pathname(options[:pattern] || '*')
        exclude = options[:exclude]
        @left = left + pattern
        @right = right + pattern
        Console.puts "Performing directory diff:"
        Console.puts "  From directory:  #{left}"
        Console.puts "  To directory:    #{right}"
        Console.puts "  Include Pattern: #{pattern}"
        Console.puts "  Exclude Pattern: #{exclude}" if exclude
        begin
            left_files = Dir[left + pattern].sort
            excludes = exclude ? Dir[left + exclude] : []
            (left_files - excludes).each_with_index do |file, i|
                Console.show_progress 'Diffing...', i, left_files.size
                right_file = right + File.basename(file)
                if right_file.file?
                    diff_file(file, right_file.to_s, options)
                end
            end
        ensure
            Console.clear_progress
        end
    end


    # Diff two CSV files
    def diff_files(left, right, options)
        Console.puts "Performing file diff:"
        Console.puts "  From file:  #{left}"
        Console.puts "  To file:    #{right}"
        @left = left
        @right = right
        diff_file(from, to, options)
    end


    # Diff two files, and add the results to the diff report.
    #
    # @param left [String] The path to the left file
    # @param right [String] The path to the right file
    # @param options [Hash] The options to be passed to CSVDiff.
    def diff_file(left, right, options)
        from = open_source(left, :from, options)
        to = open_source(right, :to, options)
        diff = CSVDiff.new(left, right, options)
        diff.diff_warnings.each{ |warn| Console.puts warn, :yellow }
        Console.write "Found #{diff.diffs.size} differences"
        diff.summary.each_with_index.map do |pair, i|
            Console.write i == 0 ? ": " : ", "
            k, v = pair
            color = case k
                    when 'Add' then :light_green
                    when 'Delete' then :red
                    when 'Update' then :cyan
                    when 'Move' then :light_magenta
                    end
            Console.write "#{v} #{k}s", color
        end
        Console.puts
        self << diff
    end


    # Opens a source file.
    #
    # @param src [String] A path to the file to be opened.
    # @param options [Hash] An options hash to be passed to CSVSource.
    def open_source(src, left_right, options)
        Console.write "Opening #{left_right.to_s.upcase} file '#{File.basename(src)}'..."
        csv_src = CSVDiff::CSVSource.new(src.to_s, options)
        Console.puts "  #{csv_src.lines.size} lines read", :white
        csv_src.warnings.each{ |warn| Console.puts warn, :yellow }
        csv_src
    end

end
