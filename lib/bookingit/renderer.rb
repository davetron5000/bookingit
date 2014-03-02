require 'redcarpet'
require 'cgi'
require 'fileutils'

module Bookingit
  class Renderer < Redcarpet::Render::HTML
    include FileUtils

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
      '.rb' => 'ruby',
      '.html' => 'html',
      '.scala' => 'scala',
    }
    def block_code(code, language)
      if code.strip =~ /file:\/\/(.*)$/
        path = $1
        code = File.read(path)
        language = EXTENSION_TO_LANGUAGE.fetch(File.extname(path))
      elsif code.strip =~ /git:\/\/(.*)$/
        path = $1
        if path =~ /(^.*).git\/(.*)#([^#]+)$/
          repo_path = $1
          path_in_repo = $2
          reference = $3
          chdir repo_path do
            if reference =~ /^(.+)\.\.(.+)$/
              code = `git diff #{reference}`
              language = 'diff'
            else
              `git checkout #{reference} 2>&1`
              code = File.read(path_in_repo)
              `git checkout master 2>&1`
              language = EXTENSION_TO_LANGUAGE.fetch(File.extname(path_in_repo))
            end
          end
        else
          raise "You must provide a SHA1 or tagname: #{path}"
        end
      elsif code.strip =~ /sh:\/\/(.+)#([^#]+)$/
        path = $1
        command = $2
        chdir path do
          output = `#{command}`
          code = "> #{command}\n#{output}"
          language = 'shell'
        end
      end
      css_class = if language.nil? || language.strip == ''
                    ""
                  else
                    " class=\"language-#{language}\""
                  end
      %{<pre><code#{css_class}>#{CGI.escapeHTML(code)}</code></pre>}
    end
  end
end
