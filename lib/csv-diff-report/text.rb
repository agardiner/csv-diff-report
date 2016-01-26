require 'csv'


class CSVDiff

    # Defines functionality for exporting a Diff report in TEXT format. This is
    # a CSV format where only fields with differences have values.
    module Text

        private

        # Generare a diff report in TEXT format.
        def text_output(output)
            path = "#{File.dirname(output)}/#{File.basename(output, File.extname(output))}.diff"
            CSV.open(path, 'w') do |csv|
                @diffs.each do |file_diff|
                    text_diff(csv, file_diff) if file_diff.diffs.size > 0
                end
            end
            path
        end


        def text_diff(csv, file_diff)
            count = 0

            all_fields = [:row, :action]
            all_fields << :sibling_position unless file_diff.options[:ignore_moves]
            all_fields.concat(file_diff.diff_fields)

            csv << all_fields.map{ |fld| fld.is_a?(Symbol) ? titleize(fld) : fld }
            file_diff.diffs.each do |key, diff|
                row = all_fields.map do |field|
                    d = diff[field]
                    d = d.last if d.is_a?(Array)
                    d
                end
                csv << row
            end
        end

    end

end
