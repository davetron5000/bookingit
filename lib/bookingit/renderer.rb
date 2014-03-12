require 'redcarpet'
require 'cgi'
require 'fileutils'

module Bookingit
  class Renderer < Redcarpet::Render::HTML
    include FileUtils

    # options:: control aspects of rendering
    #           basedir:: Base directory from which all relative paths are referenced from
    #           stylesheets:: Array of CSS files to include in the preamble
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
      @basedir              = String(options[:basedir]).strip
      @basedir              = '.' if @basedir == ''
      @stylesheets          = Array(options[:stylesheets])
      @theme                = options[:theme] || "default"
      @cachedir             = options[:cacher]
    end

    attr_accessor :headers
    def header(text,header_level,anchor)
      @headers[header_level] ||= []
      @headers[header_level] << text
      "<h#{header_level}>#{text}</h#{header_level}>"
    end

    def header_text
      %{<!DOCTYPE html>
<html>
<head>
} + @stylesheets.map { |stylesheet|
        "  <link href='#{stylesheet}' rel='stylesheet' type='text/css' media='all'>"
      }.join("\n") + %{
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1">
  <meta charset="utf-8">
  <link rel="stylesheet" href="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.0/styles/#{@theme}.min.css">
  <script src="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.0/highlight.min.js"></script>
  <script>hljs.initHighlightingOnLoad();</script>
</head>
<body>
      }
    end

    def doc_header
      @headers = {}
      header_text
    end

    def doc_footer
      "</body></html>"
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
        .when_file(                &method(:read_file))
        .when_git_diff(            &method(:read_git_diff))
        .when_shell_command_in_git(&method(:run_shell_command_in_git))
        .when_file_in_git(         &method(:read_file_in_git))
        .when_shell_command(       &method(:run_shell_command))
        .otherwise {
          [code,language,nil]
        }.result

        result = %{<article class='code-listing'><pre><code#{css_class(language)}>#{CGI.escapeHTML(code)}</code></pre>#{filename_footer(filename)}</article>}
      end
      result
    end

  private

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
      if filename
        %{<footer><h1>#{filename}</h1></footer>}
      else
        ''
      end
    end
  end
end
