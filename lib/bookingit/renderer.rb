require 'redcarpet'
require 'cgi'
require 'fileutils'

module Bookingit
  class Renderer < Redcarpet::Render::HTML
    include FileUtils

    def initialize(config)
      super()
      options = config.rendering_config
      additional_languages = Hash[(options[:languages] || {}).map { |ext_or_regexp,language|
        if ext_or_regexp.kind_of? String
          [/#{ext_or_regexp}$/,language]
        else
          [ext_or_regexp,language]
        end
      }]
      @language_identifiers = EXTENSION_TO_LANGUAGE.merge(additional_languages)
      @basedir              = String(options[:basedir]).strip
      @basedir              = '.' if @basedir == ''
      @stylesheets          = Array(options[:stylesheets])
      @theme                = options[:theme] || "default"
      @cachedir             = options[:cache]
      @config               = config
      @images               = []
    end

    attr_accessor :headers, :stylesheets, :theme, :images

    def current_chapter=(chapter)
      @chapter = chapter
    end

    def header(text,header_level,anchor)
      @headers[header_level] ||= []
      @headers[header_level] << text
      "<h#{header_level+1}>#{text}</h#{header_level+1}>"
    end

    def image(link, title, alt_text)
      title = title.gsub(/'/,'"') if title
      @images << link
      "<img src='#{link}' alt='#{alt_text}' title='#{title}'>"
    end

    def doc_header
      @headers = {}
      Views::HeaderView.new(@stylesheets,@theme,@config).render
    end

    def doc_footer
      Views::FooterView.new(@chapter,@config).render
    end

    EXTENSION_TO_LANGUAGE = {
      /\.rb$/    => 'ruby',
      /\.html$/  => 'html',
      /\.scala$/ => 'scala',
      /Gemfile$/ => 'ruby',
    }

    def identify_language(path)
      @language_identifiers.select { |matcher,language|
        path =~ matcher
      }.values.first
    end


    def block_code(code, language)
      result = nil
      filename = nil
      chdir @basedir do
        code,language,filename = CodeBlockInterpreter.new(code)
        .when_file(                &cache(:read_file))
        .when_git_diff(            &cache(:read_git_diff))
        .when_shell_command_in_git(&cache(:run_shell_command_in_git))
        .when_file_in_git(         &cache(:read_file_in_git))
        .when_shell_command(       &cache(:run_shell_command))
        .otherwise {
          [code,language,nil]
        }.result
      end
      Views::CodeView.new(code,filename,language,@config).render.strip
    end

  private

    def cache(method_name)
      ->(*args) {
        if @cachedir && File.exist?(cached_filename(*args))
          puts "Pulling from cache..."
          lines = File.read(cached_filename(*args)).split(/\n/)
          language = lines.shift
          filename = lines.shift
          [lines.join("\n") + "\n",language,filename]
        else
          code,language,filename = method(method_name).(*args)
          if @cachedir
            FileUtils.mkdir_p(@cachedir) unless File.exist?(@cachedir)
            File.open(cached_filename(*args),'w') do |file|
              file.puts language
              file.puts filename
              file.puts code
            end
            puts "Cached output"
          end
          [code,language,filename]
        end
      }
    end

    def cached_filename(*args)
      args = args.map { |arg|
        case arg
        when ShellCommand
          [arg.command,arg.expected_exit_status].join("_")
        else
          arg
        end
      }
      File.join(@cachedir,args.join('__').gsub(/[#\/\!\s><]/,'_'))
    end

    def at_version_in_git(reference,&block)
      ShellCommand.new(command: "git checkout #{reference} 2>&1").run!
      block.call
      ShellCommand.new(command: "git checkout master 2>&1").run!
    end

    def capture_command_output(path,command,exit_type=:zero)
      shell_command = ShellCommand.new(command: command,path: path) do |exit_status|
        case exit_type
        when :zero
          exit_status == 0
        when :nonzero
          exit_status != 0
        else
          raise "unknown exit type #{exit_type}"
        end
      end
      shell_command.run!
      ["> #{command}\n#{shell_command.stdout}",'shell']
    end

    def read_file(path)
      filename = path
      [File.read(path),identify_language(path),filename]
    end

    def read_git_diff(path_in_repo,reference)
      puts "Calculating git diff #{reference}"
      filename = path_in_repo
      shell_command = ShellCommand.new(command: "git diff #{reference} #{path_in_repo}")
      shell_command.run!
      [ shell_command.stdout, 'diff', filename ]
    end

    def run_shell_command_in_git(reference,shell_command)
      code = nil
      at_version_in_git(reference) do
        shell_command.run!
        code = "> #{shell_command.command}\n#{shell_command.stdout}"
      end
      [code,'shell']
    end

    def read_file_in_git(path_in_repo,reference)
      puts "Getting file at #{reference}"
      code = nil
      filename = path_in_repo
      at_version_in_git(reference) do
        code = File.read(path_in_repo)
      end
      [code, identify_language(path_in_repo),filename]
    end

    def run_shell_command(shell_command)
      shell_command.run!
      ["> #{shell_command.command}\n#{shell_command.stdout}",'shell']
    end

    def css_class(language)
      if language.nil? || language.strip == ''
        ""
      else
        " class=\"language-#{language}\""
      end
    end

    def filename_footer(filename)
      if filename && filename.strip != ''
        %{<footer><h1>#{filename}</h1></footer>}
      else
        ''
      end
    end
  end
end
