require 'csv'


class CSVDiff

    # Defines functionality for exporting a Diff report in TEXT format. This is
    # a CSV format where only fields with differences have values.
    module Text

        private

        # Generare a diff report in TEXT format.
        def text_output(output)
            path = "#{File.dirname(output)}/#{File.basename(output, File.extname(output))}.csv"
            CSV.open(path, 'w') do |csv|
                @diffs.each do |file_diff|
                    text_diff(csv, file_diff) if file_diff.diffs.size > 0
                end
            end
            path
        end


        def text_diff(csv, file_diff)
            out_fields = output_fields(file_diff)
            csv << out_fields.map{ |fld| fld.is_a?(Symbol) ? titleize(fld) : fld }
            file_diff.diffs.each do |key, diff|
                row = out_fields.map do |field|
                    d = diff[field]
                    d = d.last if d.is_a?(Array)
                    if d.nil? && file_diff.options[:include_matched]
                        d = file_diff.right[key] && file_diff.right[key][field]
                    end
                    d
                end
                csv << row
            end
        end

    end

end
