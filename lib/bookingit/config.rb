require 'fileutils'
require 'json'

module Bookingit
  class Config
    include FileUtils

    attr_reader :front_matter,
                :main_matter,
                :back_matter

    def initialize(config_json,root_dir)
      config_hash = JSON.parse(config_json)

      @front_matter = Matter.new(config_hash['front_matter'],root_dir)
      @main_matter  = Matter.new(config_hash['main_matter'],root_dir)
      @back_matter  = Matter.new(config_hash['back_matter'],root_dir)
    end

    class Matter
      attr_reader :chapters
      def initialize(chapters_config,root_dir)
        @chapters = Array(chapters_config).map { |chapter_config|
          Chapter.new(chapter_config,root_dir)
        }
      end
    end

    class Chapter
      attr_reader :sections
      attr_reader :path

      def initialize(chapter_config,root_dir)
        files = Array(chapter_config).flatten(1).map { |file|
          Dir[File.join(root_dir,file)]
        }.flatten
        if files.size == 1
          @sections = []
          @path = files[0]
        else
          @sections = files.map { |file|
            Section.new(file)
          }
        end
      end
    end

    class Section
      attr_reader :path
      def initialize(path)
        @path = path
      end
    end
  end

end
