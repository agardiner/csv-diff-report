
class CSVDiffReport

    # Defines functionality for exporting a Diff report in HTML format.
    module Html

        private

        # Generare a diff report in XLSX format.
        def html_output(output)
            content = []
            content << '<html>'
            content << '<head>'
            content << '<title>Diff Report</title>'
            content << '<meta http-equiv="Content-Type" content="text/html; charset=us-ascii">'
            content << html_styles
            content << '</head>'
            content << '<body>'

            html_summary(content)
            @diffs.each do |file_diff|
                html_diff(content, file_diff) if file_diff.diffs.size > 0
            end

            content << '</body>'
            content << '</html>'

            # Save workbook
            path = "#{File.dirname(output)}/#{File.basename(output, File.extname(output))}.html"
            File.open(path, 'w'){ |f| f.write(content.join("\n")) }
            path
        end


        # Returns the HTML head content, which contains the styles used for diffing.
        def html_styles
            head = <<-EOT
                <style>
                    @font-face {font-family: Calibri;}

                    h1 {font-family: Calibri; font-size: 16pt;}
                    h2 {font-family: Calibri; font-size: 14pt; margin: 1em 0em .2em;}
                    h3 {font-family: Calibri; font-size: 12pt; margin: 1em 0em .2em;}
                    body {font-family: Calibri; font-size: 11pt;}
                    p {margin: .2em 0em;}
                    table {font-family: Calibri; font-size: 10pt; line-height: 12pt; border-collapse: collapse;}
                    th {background-color: #00205B; color: white; font-size: 11pt; font-weight: bold; text-align: left;
                        border: 1px solid #DDDDFF; padding: 1px 5px;}
                    td {border: 1px solid #DDDDFF; padding: 1px 5px;}

                    .summary {font-size: 13pt;}
                    .add {background-color: white; color: #33A000;}
                    .delete {background-color: white; color: #FF0000; text-decoration: line-through;}
                    .update {background-color: white; color: #0000A0;}
                    .move {background-color: white; color: #0000A0;}
                    .bold {font-weight: bold;}
                    .center {text-align: center;}
                    .right {text-align: right;}
                    .separator {width: 200px; border-bottom: 1px gray solid;}
                </style>
            EOT
        end


        def html_summary(body)
            body << '<h2>Summary</h2>'
            body << '<table>'
            body << '<thead><tr>'
            body << '<th>File</th><th>Adds</th><th>Deletes</th><th>Updates</th><th>Moves</th>'
            body << '</tr></thead>'
            body << '<tbody>'
            @diffs.each do |file_diff|
                label = File.basename(file_diff.left.path)
                body << '<tr>'
                if file_diff.diffs.size > 0
                    body << "<td><a href='##{label}'>#{label}</a></td>"
                else
                    body << "<td>#{label}</td>"
                end
                body << "<td class='right'>#{file_diff.summary['Add']}</td>"
                body << "<td class='right'>#{file_diff.summary['Delete']}</td>"
                body << "<td class='right'>#{file_diff.summary['Update']}</td>"
                body << "<td class='right'>#{file_diff.summary['Move']}</td>"
                body << '</tr>'
            end
            body << '</tbody>'
            body << '</table>'
        end


        def html_diff(body, file_diff)
            label = File.basename(file_diff.left.path)
            body << "<h2 id=#{label}>#{label}</h2>"
            body << '<p>'
            count = 0
            if file_diff.summary['Add'] > 0
                body << "<span class='add'>#{file_diff.summary['Add']} Adds</span>"
                count += 1
            end
            if file_diff.summary['Delete'] > 0
                body << ', ' if count > 0
                body << "<span class='delete'>#{file_diff.summary['Delete']} Deletes</span>"
                count += 1
            end
            if file_diff.summary['Update'] > 0
                body << ', ' if count > 0
                body << "<span class='update'>#{file_diff.summary['Update']} Updates</span>"
                count += 1
            end
            if file_diff.summary['Move'] > 0
                body << ', ' if count > 0
                body << "<span class='move'>#{file_diff.summary['Move']} Moves</span>"
            end
            body << '</p>'

            all_fields = [:row, :action, :sibling_position] + file_diff.diff_fields
            body << '<table>'
            body << '<thead><tr>'
            all_fields.each do |fld|
                body << "<th>#{fld.to_s}</th>"
            end
            body << '</tr></thead>'
            body << '<tbody>'
            file_diff.diffs.sort_by{|k, v| v[:row] }.each do |key, diff|
                body << '<tr>'
                chg = diff[:action]
                all_fields.each_with_index do |field, i|
                    old = nil
                    style = case chg
                    when 'Add', 'Delete' then chg.downcase
                    end
                    d = diff[field]
                    if d.is_a?(Array)
                        old = d.first
                        new = d.last
                        if old.nil?
                            style = 'add'
                        else
                            style = chg.downcase
                        end
                    else
                        new = d
                        style = chg.downcase if i == 1
                    end
                    body << '<td>'
                    body << "<span class='delete'>#{old}</span>" if old
                    body << '<br>' if old && old.to_s.length > 10
                    body << "<span#{style ? " class='#{style}'" : ''}>#{new}</span>"
                    body << '</td>'
                end
                body << '</tr>'
            end
            body << '</tbody>'
            body << '</table>'
        end

    end

end
