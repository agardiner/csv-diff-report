
class CSVDiffReport

    # Defines functionality for exporting a Diff report in HTML format.
    module Html

        private

        # Generare a diff report in XLSX format.
        def html_output(output)
            # Save workbook
            path = "#{File.dirname(output)}/#{File.basename(output, File.extname(output))}.html"
        end

    end

end
