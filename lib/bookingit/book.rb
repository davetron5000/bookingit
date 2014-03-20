require 'mustache'
require 'ostruct'

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
          title = Array(renderer.headers[1]).first
          toc[matter] << [output_file,title]
        end
      end
      toc
    end

    def structify
      -> (matter) {
        OpenStruct.new(href: matter[0], title: matter[1])
      }
    end

    def generate_toc(toc,renderer)
      view = IndexView.new(renderer.header_text,
                           renderer.doc_footer,
                           toc['front_matter'].map(&structify),
                           toc['main_matter'].map(&structify),
                           toc['back_matter'].map(&structify))
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

    class IndexView < Mustache
      self.template_path = File.expand_path(File.join(File.dirname(__FILE__),'..','..','templates'))
      self.template_name = 'index.html'

      attr_reader :header, :footer, :front_matter, :main_matter, :back_matter
      def initialize(header,footer,front_matter,main_matter,back_matter)
        @header = header
        @footer = footer
        @front_matter = front_matter
        @main_matter = main_matter
        @back_matter = back_matter
      end
    end
  end
end
