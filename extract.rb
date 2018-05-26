require 'pry'
VIEWS_PATH = '../tourizzzm/app/views'
ANCHOR = /= render(\(|\s)/

EXTENTIONS = ['.html.haml', '.html.erb', '.haml', '.erb']

@processed_items = []
@error_items = []

Dir.glob("#{VIEWS_PATH}/**/*.html.haml") do |filename|
  file = File.open(filename, 'r+')
  curr_dir = File.dirname(filename)

  unless filename =~ /\/_\w*\.html\.haml/
    new_file_lines = []
    file.each_line do |line|
      if line =~ ANCHOR
        replacement = []
        shift = line.index(ANCHOR)
        render_args_start_position = shift + 8
        # get shift
        # get args
        render_args = line[render_args_start_position .. -1]

        # convert to new hashes
        render_args.dup.scan(/(:(\w+)\s*=>)/) do |match|
          render_args.gsub!(match.first, "#{match.last}:")
        end


        # cleanup them
        render_args = render_args.gsub(/^\(/, '').gsub(/\)$/, '')

        # partial
        partial = render_args.split(',')[0].gsub("'", '').gsub('"', '').gsub('partial: ', '').strip.gsub(/\A\//, '')

        split_partial = partial.split('/')
        partial_path = split_partial.push("_#{split_partial.pop}").join('/')

        partial_path = if partial_path.start_with?('_')
                         [curr_dir, partial_path].join('/')
                       else
                         [VIEWS_PATH, partial_path].join('/')
                       end


        partial_ext = EXTENTIONS.find do |extention|
          File.exists?("#{partial_path}#{extention}")
        end

        if partial_ext.nil?
          @error_items << [filename, partial_path]
          next
        else
          partial_exact_path = "#{partial_path}#{partial_ext}"
        end

        # args
        args = render_args.split(',')[1]

        unless args.nil?
          new_file_lines << [' ' * shift, "- # UNPARTIAL - locals (begin)"].join

          original = args
          args = args.strip

          if args =~ /\A(locals:)/
            args = args.gsub(/\A(locals:)/, '').strip.gsub(/\A{(\s)/, '').gsub(/(\s)}\z/, '')
          end

          args.split(',').each do |arg|
            var = arg.split(' ').first
            new_file_lines << [' ' * shift, "- #{var.gsub(':', '')} =#{arg.gsub(var, '')}"].join
          end
          new_file_lines << [' ' * shift, "- # UNPARTIAL - locals (end)"].join
        end

        new_file_lines << [' ' * shift, "- # UNPARTIAL - partial exctract (start)"].join
        File.open(partial_exact_path).read.each_line do |line|
          new_file_lines << [' ' * shift, line].join
        end
        new_file_lines << [' ' * shift, "- # UNPARTIAL - partial exctract (end)"].join

      else
        new_file_lines << line
      end
    end
    file.write(new_file_lines.join("\n"))
  end
end
