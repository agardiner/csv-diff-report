require 'cgi'
begin
    require 'lcs-diff'
rescue LoadError
end


class CSVDiff

    # Defines functionality for exporting a Diff report in HTML format.
    module Html


        # Generare a diff report in HTML format.
        def html_output(output)
            content = []
            content << '<html>'
            content << '<head>'
            content << '<title>Diff Report</title>'
            content << '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'
            content << html_styles
            content << '</head>'
            content << '<body>'

            @lcs_available = !!defined?(Diff::LCS)

            html_summary(content)
            @diffs.each do |file_diff|
                html_diff(content, file_diff) if file_diff.diffs.size > 0
            end

            content << '</body>'
            content << '</html>'

            # Save page
            path = "#{File.dirname(output)}/#{File.basename(output, File.extname(output))}.html"
            File.open(path, 'w'){ |f| f.write(content.join("\n")) }
            path
        end


        # Returns the HTML head content, which contains the styles used for diffing.
        def html_styles
            style = <<-EOT
                <style>
                    @font-face {font-family: Calibri, Helvetica, sans-serif;}

                    h1 {font-family: Calibri, Helvetica, sans-serif; font-size: 16pt;}
                    h2 {font-family: Calibri, Helvetica, sans-serif; font-size: 14pt; margin: 1em 0em .2em;}
                    h3 {font-family: Calibri, Helvetica, sans-serif; font-size: 12pt; margin: 1em 0em .2em;}
                    body {font-family: Calibri, Helvetica, sans-serif; font-size: 11pt;}
                    p {margin: .2em 0em;}
                    code {font-size: 8pt; white-space: pre;}
                    table {font-family: Calibri, Helvetica, sans-serif; font-size: 10pt; line-height: 13pt; border-collapse: collapse;}
                    th {background-color: #00205B; color: white; font-size: 11pt; font-weight: bold; text-align: left;
                        border: 1px solid #DDDDFF; padding: 1px 5px;}
                    td {border: 1px solid #DDDDFF; padding: 1px 5px;}

                    .summary {font-size: 13pt;}
                    .add {background-color: white; color: #33A000;}
                    .delete {background-color: white; color: #FF0000; text-decoration: line-through;}
                    .update {background-color: white; color: #0000A0;}
                    .move {background-color: white; color: #0000A0;}
                    .matched {background-color: white; color: #A0A0A0;}
                    .bold {font-weight: bold;}
                    .center {text-align: center;}
                    .right {text-align: right;}
                    .separator {width: 200px; border-bottom: 1px gray solid;}
                </style>
            EOT
            style
        end


        def html_summary(body, item_lbl='Files')
            body << '<h2>Summary</h2>'

            body << "<p>Diff report generated at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}.</p>"

            body << '<h3>Source Locations</h3>'
            body << '<table>'
            body << '<tbody>'
            body << "<tr><th>From:</th><td>#{@left}</td></tr>"
            body << "<tr><th>To:</th><td>#{@right}</td></tr>"
            body << '</tbody>'
            body << '</table>'
            body << '<br>'
            body << "<h3>#{item_lbl}</h3>"
            body << '<table>'
            body << '<thead>'
            body << "<tr><th rowspan=2>File</th><th colspan=2 class='center'>Lines</th><th colspan=4 class='center'>Diffs</th></tr>"
            body << "<tr><th>From</th><th>To</th><th>Adds</th><th>Deletes</th><th>Updates</th><th>Moves</th></tr>"
            body << '</thead>'
            body << '<tbody>'
            @diffs.each do |file_diff|
                label = File.basename(file_diff.left.path? ? file_diff.left.path : file_diff.right.path)
                body << '<tr>'
                if file_diff.diffs.size > 0
                    body << "<td><a href='##{label}'>#{label}</a></td>"
                else
                    body << "<td>#{label}</td>"
                end
                body << "<td class='right'>#{file_diff.left.line_count}</td>"
                body << "<td class='right'>#{file_diff.right.line_count}</td>"
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
            label = File.basename(file_diff.left.path? ? file_diff.left.path : file_diff.right.path)
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

            out_fields = output_fields(file_diff)
            body << '<table>'
            body << '<thead><tr>'
            out_fields.each do |fld|
                body << "<th>#{fld.is_a?(Symbol) ? titleize(fld) : fld}</th>"
            end
            body << '</tr></thead>'
            body << '<tbody>'
            file_diff.diffs.sort_by{|k, v| v[:row] }.each do |key, diff|
                body << '<tr>'
                chg = diff[:action]
                out_fields.each_with_index do |field, i|
                    old, new = nil, nil
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
                    elsif d
                        new = d
                        style = chg.downcase if i == 1
                    elsif file_diff.options[:include_matched]
                        style = 'matched'
                        new = file_diff.right[key] && file_diff.right[key][field]
                    end
                    body << '<td>'
                    if style == 'update' && @lcs_available && old && new && (old.to_s.lines.count > 1 || new.to_s.lines.count > 1)
                        Diff::LCS.diff(old.to_s.lines, new.to_s.lines).each_with_index do |chg_set, j|
                            body << '<br>...<br>' unless j == 0
                            chg_set.each_with_index do |lcs_diff, l|
                                body << '<br>' unless l == 0
                                body << "#{lcs_diff.position + 1}&nbsp;&nbsp;<span class='#{
                                    lcs_diff.action == '+' ? 'add' : 'delete'}'><code>#{
                                    CGI.escapeHTML(lcs_diff.element.to_s.chomp)}</code></span>"
                            end
                        end
                    else
                        body << "<span class='delete'><code>#{CGI.escapeHTML(old.to_s)}</code></span>" if old
                        body << '<br>' if old && old.to_s.length > 10
                        body << "<span#{style ? " class='#{style}'" : ''}><code>#{CGI.escapeHTML(new.to_s)}</code></span>"
                    end
                    body << '</td>'
                end
                body << '</tr>'
            end
            body << '</tbody>'
            body << '</table>'
        end

    end

end
