
class CSVDiffReport

    # Defines functionality for exporting a Diff report to Excel in XLSX format
    # using the Axlsx library.
    module Excel

        private

        # Generare a diff report in XLSX format.
        def xl_output(output)
            require 'axlsx'

            # Create workbook
            xl = xl_new

            # Add a summary sheet and diff sheets for each diff
            xl_summary_sheet(xl)

            # Save workbook
            path = "#{File.dirname(output)}/#{File.basename(output, File.extname(output))}.xlsx"
            xl_save(xl, path)
        end


        # Create a new XL package object
        def xl_new
            @xl_styles = {}
            xl = Axlsx::Package.new
            xl.use_shared_strings = true
            xl.workbook.styles do |s|
                s.fonts[0].sz = 9
                @xl_styles['Title'] = s.add_style(:b => true)
                @xl_styles['Comma'] = s.add_style(:format_code => '#,##0')
                @xl_styles['Right'] = s.add_style(:alignment => {:horizontal => :right})
                @xl_styles['Add'] = s.add_style :fg_color => '00A000'
                @xl_styles['Update'] = s.add_style :fg_color => '0000A0', :bg_color => 'F0F0FF'
                @xl_styles['Move'] = s.add_style :fg_color => '4040FF'
                @xl_styles['Delete'] = s.add_style :fg_color => 'FF0000', :strike => true
            end
            xl
        end


        # Add summary sheet
        def xl_summary_sheet(xl)
            compare_from = @left
            compare_to = @right

            xl.workbook.add_worksheet(name: 'Summary') do |sheet|
                sheet.add_row do |row|
                    row.add_cell 'From:', :style => @xl_styles['Title']
                    row.add_cell compare_from
                end
                sheet.add_row do |row|
                    row.add_cell 'To:', :style => @xl_styles['Title']
                    row.add_cell compare_to
                end
                sheet.add_row
                sheet.add_row ['Sheet', 'Adds', 'Deletes', 'Updates', 'Moves'], :style => @xl_styles['Title']
                sheet.column_info.each do |ci|
                    ci.width = 10
                end
                sheet.column_info.first.width = 20

                @diffs.each do |file_diff|
                    sheet.add_row([File.basename(file_diff.left.path, File.extname(file_diff.left.path)),
                                   file_diff.summary['Add'], file_diff.summary['Delete'],
                                   file_diff.summary['Update'], file_diff.summary['Move']])
                    xl_diff_sheet(xl, file_diff) if file_diff.diffs.size > 0
                end
            end

        end


        # Add diff sheet
        def xl_diff_sheet(xl, file_diff)
            sheet_name = File.basename(file_diff.left.path, File.extname(file_diff.left.path))
            all_fields = [:row, :action, :sibling_position] + file_diff.diff_fields
            xl.workbook.add_worksheet(name: sheet_name) do |sheet|
                sheet.add_row(all_fields.map{ |f| f.to_s }, :style => @xl_styles['Title'])
                file_diff.diffs.sort_by{|k, v| v[:row] }.each do |key, diff|
                    sheet.add_row do |row|
                        chg = diff[:action]
                        all_fields.each_with_index do |field, i|
                            cell = nil
                            comment = nil
                            old = nil
                            style = case chg
                            when 'Add', 'Delete' then @xl_styles[chg]
                            else 0
                            end
                            d = diff[field]
                            if d.is_a?(Array)
                                old = d.first
                                new = d.last
                                if old.nil?
                                    style = @xl_styles['Add']
                                else
                                    style = @xl_styles[chg]
                                    comment = old
                                end
                            else
                                new = d
                                style = @xl_styles[chg] if i == 1
                            end
                            case new
                            when String
                                cell = row.add_cell(new.encode('utf-8'), :style => style) #, :type => :string)
                            #    cell = row.add_cell(new, :style => style)
                            else
                                cell = row.add_cell(new, :style => style)
                            end
                            sheet.add_comment(:ref => cell.r, :author => 'Current', :visible => false,
                                              :text => old.to_s.encode('utf-8')) if comment
                        end
                    end
                end
                sheet.column_info.each do |ci|
                    ci.width = 80 if ci.width > 80
                end
                xl_filter_and_freeze(sheet, 5)
            end
        end


        # Freeze the top row and +freeze_cols+ of +sheet+.
        def xl_filter_and_freeze(sheet, freeze_cols = 0)
            sheet.auto_filter = "A1:#{Axlsx::cell_r(sheet.rows.first.cells.size - 1, sheet.rows.size - 1)}"
            sheet.sheet_view do |sv|
                sv.pane do |p|
                    p.state = :frozen
                    p.x_split = freeze_cols
                    p.y_split = 1
                end
            end
        end


        # Save +xl+ package to +path+
        def xl_save(xl, path)
            begin
                xl.serialize(path)
                path
            rescue RuntimeError => ex
                Console.puts ex.message, :red
                raise "Unable to replace existing Excel file #{path} - is it already open in Excel?"
            end
        end

    end

end
