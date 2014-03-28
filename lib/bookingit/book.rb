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
      generate_toc(toc,renderer.stylesheets,renderer.theme)
    end

  private

    def generate_chapters(renderer)
      redcarpet = Redcarpet::Markdown.new(renderer, 
                                 no_intra_emphasis: true,
                                            tables: true,
                                fenced_code_blocks: true,
                                          autolink: true,
                                     strikethrough: true,
                                       superscript: true)

      toc = {}
      %w(front_matter main_matter back_matter).each do |matter|
        toc[matter] = []
        @config.send(matter).chapters.each do |chapter|
          contents = File.read(chapter.markdown_path)

          output_file = chapter.relative_url
          renderer.current_chapter = chapter
          File.open(File.join(@output_dir,output_file),'w') do |file|
            file.puts redcarpet.render(contents)
          end
          chapter.title = Array(renderer.headers[1]).first
          toc[matter] << chapter
        end
      end
      toc
    end

    def generate_toc(toc,stylesheets,theme)
      if @config.templates["index"] =~ /^\//
        Views::IndexView.template_path = File.dirname(@config.templates["index"])
        Views::IndexView.template_name = File.basename(@config.templates["index"])
      else
        Views::IndexView.template_name = @config.templates["index"]
      end
      view = Views::IndexView.new(stylesheets,
                                  theme,
                                  toc['front_matter'],
                                  toc['main_matter'],
                                  toc['back_matter'],
                                  @config)
      File.open(File.join(@output_dir,'index.html'),'w') do |index|
        index.puts view.render
      end
    end

    def copy_assets
      @config.rendering_config[:stylesheets].each do |stylesheet|
        cp stylesheet, @output_dir
      end
    end
  end
end
