module Bookingit
  module Views
    class HeaderView < BaseView
      self.template_name = 'header.html'

      attr_reader :stylesheets, :theme

      def initialize(stylesheets, theme)
        @stylesheets = stylesheets.map { |stylesheet|
          OpenStruct.new(path: stylesheet, media: "all")
        }
        @theme = theme
      end
    end
  end
end
