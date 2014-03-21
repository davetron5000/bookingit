require 'forwardable'
module Bookingit
  module Views
    class IndexView < BaseView
      extend Forwardable
      self.template_name = 'index.html'

      attr_reader :front_matter, :main_matter, :back_matter
      def_delegators :@header_view, :stylesheets, :theme

      def initialize(stylesheets,theme,front_matter,main_matter,back_matter)
        @header_view = HeaderView.new(stylesheets,theme)
        @front_matter = front_matter
        @main_matter = main_matter
        @back_matter = back_matter
      end
    end
  end
end
