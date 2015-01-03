require 'redcarpet'
require 'cgi'
require 'fileutils'

module Bookingit
  class HtmlRenderer < Bookingit::Renderer
    include FileUtils

    def render_header(text,header_level,anchor)
      "<a name='#{anchor}'></a><h#{header_level+1}>#{text}</h#{header_level+1}>"
    end

    def render_image(link, title, alt_text)
      "<img src='#{link}' alt='#{alt_text}' title='#{title}'>"
    end

    def render_doc_header
      Views::HeaderView.new(@stylesheets,@theme,@config).render
    end

    def render_doc_footer
      Views::FooterView.new(@chapter,@config).render
    end

    def render_block_code(code,filename,language)
      Views::CodeView.new(code,filename,language,@config).render.strip
    end

    def css_class(language)
      if language.nil? || language.strip == ''
        ""
      else
        " class=\"language-#{language}\""
      end
    end
  end
end
