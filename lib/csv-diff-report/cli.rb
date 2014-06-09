require 'arg-parser'
require 'csv-diff-report'


class CSVDiffReport

    class CLI

        include ArgParser::DSL

        # Define an on_parse handler for field names or indexes. Splits the
        # supplied argument value on commas, and converts numbers to Fixnums.
        ArgParser::OnParseHandlers[:parse_fields] = lambda{ |val, arg, hsh|
            val.split(',').map{ |fld| fld =~ /^\d+$/ ? fld.to_i : fld }
        }

        title 'CSV-Diff'

        purpose <<-EOT
            Generate a diff report between two files using the CSV-Diff algorithm.
        EOT

        positional_arg :from, 'The file or dir to use as the left or from source in the diff'
        positional_arg :to, 'The file or dir to use as the right or to source in the diff'

        keyword_arg :pattern, 'A file name pattern to use to filter matching files if a directory ' +
            'diff is being performed', default: '*', usage_break: 'Source Options'
        keyword_arg :exclude, 'A file name pattern of files to exclude from the diff if a directory ' +
            'diff is being performed'
        keyword_arg :field_names, 'A comma-separated list of field names for each ' +
            'field in the source files', on_parse: :split_to_array
        keyword_arg :parent_fields, 'The parent field name(s) or index(es)',
            on_parse: :parse_fields
        keyword_arg :child_fields, 'The child field name(s) or index(es)',
            on_parse: :parse_fields
        keyword_arg :key_fields, 'The key field name(s) or index(es)',
            on_parse: :parse_fields
        keyword_arg :encoding, 'The encoding to use when opening the CSV files'
        flag_arg :ignore_header, 'If true, the first line in each source file is ignored; ' +
            'requires the use of the --field-names option to name the fields'

        keyword_arg :ignore_fields, 'The names or indexes of any fields to be ignored during the diff',
            usage_break: 'Diff Options', on_parse: :parse_fields
        flag_arg :ignore_adds, "If true, items in TO that are not in FROM are ignored"
        flag_arg :ignore_deletes, "If true, items in FROM that are not in TO are ignored"
        flag_arg :ignore_updates, "If true, changes to non-key properties are ignored"
        flag_arg :ignore_moves, "If true, changes in an item's position are ignored"

        keyword_arg :format, 'The format in which to produce the diff report',
            default: 'HTML', validation: /^(html|xls(x)?)$/i, usage_break: 'Output Options'
        keyword_arg :output, 'The path to save the diff report to. If not specified, the diff ' +
            'report will be placed in the same directory as the FROM file, and will be named ' +
            'Diff_<FROM>_to_<TO>.<FORMAT>'


        # Parses command-line options, and then performs the diff.
        def run
            if arguments = parse_arguments
                begin
                    process(arguments)
                rescue RuntimeError => ex
                    Console.puts ex.message, :red
                    exit 1
                end
            else
                if show_help?
                    show_help(nil, Console.width).each do |line|
                        Console.puts line, :cyan
                    end
                else
                    show_usage(nil, Console.width).each do |line|
                        Console.puts line, :yellow
                    end
                end
                exit 2
            end
        end


        # Process a CSVDiffReport using +arguments+ to determine all options.
        def process(arguments)
            options = {
                pattern: arguments.pattern,
                exclude: arguments.exclude,
                field_names: arguments.field_names,
                parent_fields: arguments.parent_fields,
                child_fields: arguments.child_fields,
                key_fields: arguments.key_fields,
                encoding: arguments.encoding,
                ignore_header: arguments.ignore_header,
                ignore_fields: arguments.ignore_fields,
                ignore_adds: arguments.ignore_adds,
                ignore_deletes: arguments.ignore_deletes,
                ignore_updates: arguments.ignore_updates,
                ignore_moves: arguments.ignore_moves
            }
            rep = CSVDiffReport.new
            rep.diff(arguments.from, arguments.to, options)

            output_dir = FileTest.directory?(arguments.from) ?
                arguments.from : File.dirname(arguments.from)
            left_name = File.basename(arguments.from, File.extname(arguments.from))
            right_name = File.basename(arguments.to, File.extname(arguments.to))
            output = arguments.output ||
                "#{output_dir}/Diff_#{left_name}_to_#{right_name}.diff"
            rep.output(output, arguments.format)
        end

    end

end


if __FILE__ == $0
    CSVDiffReport::CLI.new.run
end
