module Bookingit
  class Book
    def initialize(config,output_dir='book')
      @config = config
      @output_dir = output_dir
    end

    def render_html!
      mkdir @output_dir unless Dir.exists?(@output_dir)

      rendering_config = @config.rendering_config
      rendering_config[:cache] = File.expand_path('cache') if @config.cache
      renderer = Bookingit::Renderer.new(@config)
      @redcarpet = Redcarpet::Markdown.new(renderer, no_intra_emphasis: true,
                                                                tables: true,
                                                    fenced_code_blocks: true,
                                                              autolink: true,
                                                         strikethrough: true,
                                                           superscript: true)

      toc = parse_chapters_to_get_headers(renderer)
      generate_chapters(renderer)
      generate_toc(toc,renderer.stylesheets,renderer.theme)
      copy_assets(renderer)
    end

  private

    def parse_chapters_to_get_headers(renderer)
      toc = {}
      each_chapter do |matter,contents,chapter|
        toc[matter] ||= []
        renderer.current_chapter = chapter
        @redcarpet.render(contents)
        chapter.title = Array(renderer.headers[1]).first
        toc[matter] << chapter
      end
    toc
    end

    def each_chapter(&block)
      %w(front_matter main_matter back_matter).each do |matter|
        @config.send(matter).chapters.each do |chapter|
          block.call(matter,File.read(chapter.markdown_path),chapter)
        end
      end
    end

    def generate_chapters(renderer)
      each_chapter do |_,contents,chapter|
        output_file = chapter.relative_url
        renderer.current_chapter = chapter
        File.open(File.join(@output_dir,output_file),'w') do |file|
          file.puts @redcarpet.render(contents)
        end
      end
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

    def copy_assets(renderer)
      @config.rendering_config[:stylesheets].each do |stylesheet|
        cp stylesheet, @output_dir
      end
      renderer.images.each do |image|
        if File.exists?(image)
          dest_dir = File.join(@output_dir,File.dirname(image))
          unless File.exists? dest_dir
            mkdir_p dest_dir
          end
          cp image,dest_dir
        else
          $stderr.puts "Missing image #{image}"
        end
      end
    end
  end
end
