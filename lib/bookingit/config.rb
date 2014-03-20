require 'fileutils'
require 'json'

module Bookingit
  class Config
    include FileUtils

    attr_reader :front_matter,
                :main_matter,
                :back_matter,
                :rendering_config,
                :cache

    def initialize(config_json,root_dir)
      config_hash = JSON.parse(config_json)

      @front_matter     = Matter.new(config_hash['front_matter'],root_dir)
      @main_matter      = Matter.new(config_hash['main_matter'],root_dir)
      @back_matter      = Matter.new(config_hash['back_matter'],root_dir)
      @rendering_config = create_rendering_config(config_hash['rendering'])
      @cache            = false
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
          File.join(root_dir,chapter_filename)
        }
      end
    end
  end
end
