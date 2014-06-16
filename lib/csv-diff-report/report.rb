require 'csv-diff-report/excel'
require 'csv-diff-report/html'


class CSVDiff

    # Defines a class for generating diff reports using CSVDiff.
    #
    # A diff report may contain multiple file diffs, and can be output as either an
    # XLSX spreadsheet document, or an HTML file.
    class Report

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
                raise ArgumentError, "Only CSVDiff objects can be added to a CSVDiff::Report"
            end
        end


        # Add a diff to the diff report.
        #
        # @param options [Hash] Options to be passed to the diff process.
        def diff(left, right, options = {})
            @left = Pathname.new(left)
            @right = Pathname.new(right)
            if @left.file? && @right.file?
                Console.puts "Performing file diff:"
                Console.puts "  From File:    #{@left}"
                Console.puts "  To File:      #{@right}"
                opt_file = load_opt_file(@left.dirname)
                diff_file(@left.to_s, @right.to_s, options, opt_file)
            elsif @left.directory? && @right.directory?
                Console.puts "Performing directory diff:"
                Console.puts "  From directory:  #{@left}"
                Console.puts "  To directory:    #{@right}"
                opt_file = load_opt_file(@left)
                if fts = options[:file_types]
                    file_types = find_matching_file_types(fts, opt_file)
                    file_types.each do |file_type|
                        hsh = opt_file[:file_types][file_type]
                        ft_opts = options.merge(hsh)
                        diff_dir(@left, @right, ft_opts, opt_file)
                    end
                else
                    diff_dir(@left, @right, options, opt_file)
                end
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


        # Loads an options file from +dir+
        def load_opt_file(dir)
            opt_path = Pathname(dir + '.csvdiff')
            opt_path = Pathname('.csvdiff') unless opt_path.exist?
            if opt_path.exist?
                Console.puts "Loading options from .csvdiff at '#{dir}'"
                opt_file = YAML.load(IO.read(opt_path))
                symbolize_keys(opt_file)
            end
        end


        # Convert keys in hashes to lower-case symbols for consistency
        def symbolize_keys(hsh)
            Hash[hsh.map{ |k, v| [k.to_s.downcase.intern, v.is_a?(Hash) ?
                symbolize_keys(v) : v] }]
        end


        # Locates the file types in +opt_file+ that match the +file_types+ list of
        # file type names or patterns
        def find_matching_file_types(file_types, opt_file)
            known_fts = opt_file[:file_types].keys
            matched_fts = []
            file_types.each do |ft|
                re = Regexp.new(ft.gsub('.', '\.').gsub('?', '.').gsub('*', '.*'), true)
                matches = known_fts.select{ |file_type| file_type.to_s =~ re }
                if matches.size > 0
                    matched_fts.concat(matches)
                else
                    Console.puts "No file type matching '#{ft}' defined in .csvdiff", :yellow
                    Console.puts "Known file types are: #{opt_file[:file_types].keys.join(', ')}", :yellow
                end
            end
            matched_fts.uniq
        end


        # Diff files that exist in both +left+ and +right+ directories.
        def diff_dir(left, right, options, opt_file)
            pattern = Pathname(options[:pattern] || '*')
            exclude = options[:exclude]

            Console.puts "  Include Pattern: #{pattern}"
            Console.puts "  Exclude Pattern: #{exclude}" if exclude


            left_files = Dir[left + pattern].sort
            excludes = exclude ? Dir[left + exclude] : []
            (left_files - excludes).each_with_index do |file, i|
                right_file = right + File.basename(file)
                if right_file.file?
                    diff_file(file, right_file.to_s, options, opt_file)
                else
                    Console.puts "Skipping file '#{File.basename(file)}', as there is " +
                        "no corresponding TO file", :yellow
                end
            end
        end


        # Diff two files, and add the results to the diff report.
        #
        # @param left [String] The path to the left file
        # @param right [String] The path to the right file
        # @param options [Hash] The options to be passed to CSVDiff.
        def diff_file(left, right, options, opt_file)
            settings = find_file_type_settings(left, opt_file)
            return if settings[:ignore]
            options = settings.merge(options)
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
                        when 'Warning' then :yellow
                        end
                Console.write "#{v} #{k}s", color
            end
            Console.puts
            self << diff
        end


        # Locates any file type settings for +left+ in the +opt_file+ hash.
        def find_file_type_settings(left, opt_file)
            left = Pathname(left.gsub('\\', '/'))
            settings = opt_file && opt_file[:defaults] || {}
            opt_file && opt_file[:file_types] && opt_file[:file_types].each do |file_type, hsh|
                unless hsh[:pattern]
                    Console.puts "Invalid setting for file_type #{file_type} in .csvdiff; " +
                        "missing a 'pattern' key to use to match files", :yellow
                    hsh[:pattern] = '-'
                end
                next if hsh[:pattern] == '-'
                unless hsh[:matched_files]
                    hsh[:matched_files] = Dir[(left.dirname + hsh[:pattern]).to_s]
                    hsh[:matched_files] -= Dir[(left.dirname + hsh[:exclude]).to_s] if hsh[:exclude]
                end
                if hsh[:matched_files].include?(left.to_s)
                    settings.merge!(hsh)
                    [:pattern, :exclude, :matched_files].each{ |k| settings.delete(k) }
                    break
                end
            end
            settings
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

end
