require 'redcarpet'
require 'cgi'
require 'fileutils'

module Bookingit
  class Renderer < Redcarpet::Render::HTML
    include FileUtils

    # options:: control aspects of rendering
    #           languages:: a Hash of string extensions or regexps to languages.  This allows adding
    #                       new language detection not present by default
    def initialize(options={})
      super()
      additional_languages = Hash[(options[:languages] || {}).map { |ext_or_regexp,language|
        if ext_or_regexp.kind_of? String
          [/#{ext_or_regexp}$/,language]
        else
          [ext_or_regexp,language]
        end
      }]
      @language_identifiers = EXTENSION_TO_LANGUAGE.merge(additional_languages)
    end

    attr_accessor :headers
    def header(text,header_level,anchor)
      @headers[header_level] ||= []
      @headers[header_level] << text
      "<h#{header_level}>#{text}</h#{header_level}>"
    end

    def doc_header
      @headers = {}
      ""
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

    class Code
      def initialize(code)
        @code = code.strip
        @ran = false
      end

      def when_file(&block)
        if @code =~ /^\s*file:\/\/(.*)$/
          @ran = true
          path = $1
          block.call(path)
        end
        self
      end

      def when_git_diff(&block)
      end

      def when_shell_command_in_git(&block)
      end

      def when_git_reference(&block)
        if @code =~ /^\s*git:\/\/(.*)$/
          path = $1
          if path =~ /(^.*).git\/(.*)#([^#]+)$/
            repo_path = $1
            path_in_repo = $2
            path_in_repo = '.' if String(path_in_repo).strip == ''
            reference = $3
            block.call(repo_path,path_in_repo,reference)
          else
            raise "You must provide a SHA1 or tagname: #{path}"
          end
        end
        self
      end

      def when_file_in_git(&block)
        when_git_reference do |repo_path,path_in_repo,reference|
          if reference !~ /^(.+)\.\.(.+)$/ && reference !~ /^(.+)\!(.+)$/
            @ran = true
            chdir repo_path do
              block.call(path_in_repo,reference)
            end
          end
        end
        self
      end

      def when_git_diff(&block)
        when_git_reference do |repo_path,path_in_repo,reference|
          if reference =~ /^(.+)\.\.(.+)$/
            @ran = true
            chdir repo_path do
              block.call(path_in_repo,reference)
            end
          end
        end
        self
      end

      def when_shell_command_in_git(&block)
        when_git_reference do |repo_path,path_in_repo,reference|
          if reference =~ /^(.+)\!(.+)$/
            reference = $1
            command   = $2
            @ran = true
            chdir repo_path do
              block.call(path_in_repo,reference,command)
            end
          end
        end
      end

      def when_shell_command(&block)
        if @code.strip =~ /^\s*sh:\/\/(.+)#([^#]+)$/
          @ran = true
          path = $1
          command = $2
          block.call(path,command)
        end
      end

      def otherwise(&block)
        block.call unless @ran
      end
    end

    def block_code(code, language)
      Code.new(code).when_file { |path|

        code = File.read(path)
        language = identify_language(path)

      }.when_git_diff { |path_in_repo,reference|

        code = `git diff #{reference} #{path_in_repo}`
        language = 'diff'

      }.when_shell_command_in_git { |path_in_repo,reference,command|

        at_version_in_git(reference) do
          code,language = capture_command_output(path_in_repo,command)
        end

      }.when_file_in_git { |path_in_repo,reference|

        at_version_in_git(reference) do
          code = File.read(path_in_repo)
        end
        language = identify_language(path_in_repo)

      }.when_shell_command { |path,command|

        code,language = capture_command_output(path,command)

      }
      css_class = if language.nil? || language.strip == ''
                    ""
                  else
                    " class=\"language-#{language}\""
                  end
      %{<pre><code#{css_class}>#{CGI.escapeHTML(code)}</code></pre>}
    end

  private

    def at_version_in_git(reference,&block)
      `git checkout #{reference} 2>&1`
      block.call
      `git checkout master 2>&1`
    end

    def capture_command_output(path,command)
      output = nil
      chdir path do
        output = `#{command}`
      end
      ["> #{command}\n#{output}",'shell']
    end
  end
end
