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
        @config.send(matter).chapters.each_with_index do |chapter,i|
          contents = File.read(chapter)

          output_file = "#{matter}_#{i+1}.html"
          File.open(File.join(@output_dir,output_file),'w') do |file|
            file.puts redcarpet.render(contents)
          end
          title = Array(renderer.headers[1]).first
          toc[matter] << OpenStruct.new(href: output_file, title: title)
        end
      end
      toc
    end

    def generate_toc(toc,stylesheets,theme)
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

  private

    def copy_assets
      @config.rendering_config[:stylesheets].each do |stylesheet|
        cp stylesheet, @output_dir
      end
    end
  end
end
