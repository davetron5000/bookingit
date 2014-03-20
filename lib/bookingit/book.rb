module Bookingit
  class Book
    def initialize(config,cache)
      @config = config
      @cache = cache
    end

    def render_html!
      output_dir = 'book'
      mkdir output_dir unless Dir.exists?(output_dir)

      rendering_config = @config.rendering_config
      rendering_config[:cache] = File.expand_path('cache') if @cache
      renderer = Bookingit::Renderer.new(@config.rendering_config)
      redcarpet = Redcarpet::Markdown.new(renderer, no_intra_emphasis: true,
                                          tables: true,
                                          fenced_code_blocks: true,
                                          autolink: true,
                                          strikethrough: true,
                                          superscript: true)

      @config.rendering_config[:stylesheets].each do |stylesheet|
        cp stylesheet, output_dir
      end
      File.open(File.join(output_dir,'index.html'),'w') do |index|
        index.puts renderer.header_text
        index.puts "<ol>"
        %w(front_matter main_matter back_matter).each do |matter|
          index.puts "<li>#{matter}<ol>"
          @config.send(matter).chapters.each_with_index do |chapter,i|
            contents = if chapter.path.nil?
                         chapter.sections.map(&:path).map { |path|
                           File.read(path)
                         }.join("\n")
                       else
                         File.read(chapter.path)
                       end

            output_file = "#{matter}_#{i+1}.html"
            File.open(File.join(output_dir,output_file),'w') do |file|
              file.puts redcarpet.render(contents)
            end
            title = (Array(renderer.headers[1]) +
                     Array(renderer.headers[2]) +
                     Array(renderer.headers[3]) +
                     Array(renderer.headers[4]) +
                     Array(renderer.headers[5]) +
                     Array(renderer.headers[6])).first
            index.puts "<li><a href='#{output_file}'>#{title}</a></li>"
          end
          index.puts "</ol></li>"
        end
        index.puts "</ol>"
        index.puts renderer.doc_footer
      end
    end
  end
end
