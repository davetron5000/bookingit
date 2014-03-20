module Bookingit
  class Book
    def initialize(config)
      @config = config
      @output_dir = 'book'
    end

    def render_html!
      mkdir @output_dir unless Dir.exists?(@output_dir)

      rendering_config = @config.rendering_config
      rendering_config[:cache] = File.expand_path('cache') if @config.cache
      renderer = Bookingit::Renderer.new(@config.rendering_config)

      copy_assets
      toc = generate_chapters(renderer)
      generate_toc(toc,renderer)
    end

    def generate_chapters(renderer)
      redcarpet = Redcarpet::Markdown.new(renderer, no_intra_emphasis: true,
                                          tables: true,
                                          fenced_code_blocks: true,
                                          autolink: true,
                                          strikethrough: true,
                                          superscript: true)

      toc = {}
      %w(front_matter main_matter back_matter).each do |matter|
        toc[matter] = []
        @config.send(matter).chapters.each_with_index do |chapter,i|
          contents = File.read(chapter)

          output_file = "#{matter}_#{i+1}.html"
          File.open(File.join(@output_dir,output_file),'w') do |file|
            file.puts redcarpet.render(contents)
          end
          title = (Array(renderer.headers[1]) +
                   Array(renderer.headers[2]) +
                   Array(renderer.headers[3]) +
                   Array(renderer.headers[4]) +
                   Array(renderer.headers[5]) +
                   Array(renderer.headers[6])).first
          toc[matter] << [output_file,title]
        end
      end
      toc
    end

    def generate_toc(toc,renderer)
      File.open(File.join(@output_dir,"index.html"),'w') do |index|
        index.puts renderer.header_text
        index.puts "<ol>"
        %w(front_matter main_matter back_matter).each do |matter|
          index.puts "<li>#{matter}<ol>"
          toc[matter].each do |(output_file,title)|
            index.puts "<li><a href='#{output_file}'>#{title}</a></li>"
          end
          index.puts "</ol></li>"
        end
        index.puts "</ol>"
        index.puts renderer.doc_footer
      end
    end

  private

    def copy_assets

      @config.rendering_config[:stylesheets].each do |stylesheet|
        cp stylesheet, @output_dir
      end
    end
  end
end
