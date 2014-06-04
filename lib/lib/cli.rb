require 'arg-parser'
require 'color-console'
require 'csv-diff-report'


class CSVDiffReport

    class CLI

        include ArgParser::DSL

        ArgParser::OnParseHandlers[:parse_fields] = lambda{ |val, arg, hsh|
            val.split(',').map{ |fld| fld =~ /^\d+$/ ? fld.to_i : fld }
        }

        title 'CSV-Diff'

        purpose <<-EOT
            Generate a diff report between two files using the CSV-Diff algorithm.
        EOT

        positional_arg :from, 'The file to use as the left or from file in the diff'
        positional_arg :to, 'The file to use as the right or to file in the diff'

        keyword_arg :parent_fields, 'The parent field name(s) or index(es)',
            usage_break: 'Source Options',
            on_parse: :parse_fields
        keyword_arg :child_fields, 'The child field name(s) or index(es)',
            on_parse: :parse_fields
        keyword_arg :key_fields, 'The key field name(s) or index(es)',
            on_parse: :parse_fields

        keyword_arg :format, 'The format in which to produce the diff report',
            default: 'HTML', validation: /^(html|xls(x)?)$/i, usage_break: 'Output Options'
        keyword_arg :output, 'The path to save the diff report to. If not specified, ' +
            'the diff report will be placed in the same directory as the from file'


        def run
            if arguments = parse_arguments
                options = {
                    parent_fields: arguments.parent_fields,
                    child_fields: arguments.child_fields,
                    key_fields: arguments.key_fields
                }
                from = open_source(arguments.from, options)
                to = open_source(arguments.to, options)
                output = arguments.output ||
                    "#{File.dirname(arguments.from)}/Diff_#{
                       File.basename(arguments.from, File.extname(arguments.from))
                     }_to_#{File.basename(arguments.to, File.extname(arguments.to))}"

                rep = CSVDiffReport.new
                rep.diff(from, to)

                arguments.format.upcase == 'HTML' ?
                    rep.output_html(output) :
                    rep.output_xlsx(output)
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
            end
        end


        def open_source(src, options)
            if File.exists?(src)
                Console.write "Opening '#{src}'..."
                from = CSVDiff::CSVSource.new(src, options)
                Console.puts "  #{from.lines.size} lines read", :white
                from.warnings.each{ |warn| Console.puts warn, :yellow }
                from
            #elsif Dir.exist?(arguments.from)
            else
                Console.puts "File '#{src}' could not be found", :red
                exit 1
            end
        end

    end

end


if __FILE__ == $0
    CSVDiffReport::CLI.new.run
end
