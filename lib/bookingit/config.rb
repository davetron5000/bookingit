require 'fileutils'
require 'json'

module Bookingit
  class Config
    include FileUtils

    attr_reader :front_matter,
                :main_matter,
                :back_matter,
                :rendering_config,
                :cache,
                :options,
                :templates

    def initialize(config_json,root_dir)
      config_hash = JSON.parse(config_json)

      @front_matter     = Matter.new(config_hash.delete('front_matter'),root_dir)
      @main_matter      = Matter.new(config_hash.delete('main_matter'),root_dir)
      @back_matter      = Matter.new(config_hash.delete('back_matter'),root_dir)
      @templates        = config_hash.delete("templates") || {}
      @templates["index"] ||= "index.html"
      @rendering_config = create_rendering_config(config_hash.delete('rendering'))
      @cache            = false
      @options          = config_hash

      all_chapters = (@front_matter.chapters + @main_matter.chapters + @back_matter.chapters)
      all_chapters.each_with_index do |chapter,i|
        if all_chapters[i-1]
          all_chapters[i-1].next_chapter = chapter
          chapter.previous_chapter = all_chapters[i-1]
        end
        if all_chapters[i+1]
          all_chapters[i+1].previous_chapter = chapter
          chapter.next_chapter = all_chapters[i+1]
        end
      end
    end

    def cache=(cache)
      @cache = cache
    end

  private

    def create_rendering_config(raw_config)
      raw_config ||= {}
      rendering_config = {}
      rendering_config[:stylesheets] = Array(raw_config['stylesheets'])
      rendering_config[:basedir] = raw_config['git_repos_basedir']
      rendering_config[:languages] = Hash[(raw_config['languages'] || {}).map { |match,language|
        if match =~ /^\/(.+)\/$/
          [Regexp.new($1),language]
        else
          [match,language]
        end
      }]
      rendering_config[:theme] = raw_config['syntax_theme']

      rendering_config
    end

    class Matter
      attr_reader :chapters
      def initialize(chapter_filenames,root_dir)
        @chapters = Array(chapter_filenames).map { |chapter_filename|
          Chapter.new(markdown_path: File.join(root_dir,chapter_filename))
        }
      end
    end

    class Chapter
      attr_reader :markdown_path, :relative_url
      attr_accessor :title, :previous_chapter, :next_chapter

      def initialize(markdown_path: nil, relative_url: nil)
        @markdown_path = markdown_path
        @relative_url = relative_url || (File.basename(markdown_path, File.extname(markdown_path)) + ".html")
      end
    end
  end
end
