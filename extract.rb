require 'pry'
VIEWS_PATH = '../tourizzzm/app/views'
ANCHOR = /= render(\(|\s)/

EXTENTIONS = ['.html.haml', '.html.erb', '.haml', '.erb']

@processed_items = []
@error_items = []

Dir.glob("#{VIEWS_PATH}/**/*.html.haml") do |filename|
  file = File.open(filename, 'r')
  curr_dir = File.dirname(filename)

  unless filename =~ /\/_\w*\.html\.haml/
    new_file_lines = []
    file.each_line do |line|
      if line =~ ANCHOR
        # get args
        render_args = line[(line.index(ANCHOR) + 8).. -1]

        # cleanup them
        render_args = render_args.gsub(/^\(/, '').gsub(/\)$/, '')

        # partial
        partial = render_args.split(',')[0].gsub("'", '').gsub('"', '').gsub('partial: ', '').gsub(':partial => ', '').strip.gsub(/\A\//, '')

        split_partial = partial.split('/')
        partial_path = split_partial.push("_#{split_partial.pop}").join('/')

        partial_path = if partial_path.start_with?('_')
                         [curr_dir, partial_path].join('/')
                       else
                         [VIEWS_PATH, partial_path].join('/')
                       end


        partial_exact_path = EXTENTIONS.find do |extention|
          File.exists?("#{partial_path}#{extention}")
        end

        unless partial_exact_path
          @error_items << [filename, partial_path]
          next
        end

        # args
        args = render_args.split(',')[1]

        unless args.nil?
          args = args.strip

          if args =~ /\A(:locals =>|locals:)/
            args = args.gsub(/\A(:locals =>|locals:)/, '').strip.gsub(/\A{(\s)/, '').gsub(/(\s)}\z/, '')
          end

          args.split(',').each do |arg|
            # puts arg.split(' ').first
            puts arg
          end
        end
      else
        new_file_lines << line
      end
    end
    # puts new_file_lines.join("\n")
  end
end
