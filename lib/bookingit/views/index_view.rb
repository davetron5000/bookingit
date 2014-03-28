require 'forwardable'
module Bookingit
  module Views
    class IndexView < BaseView
      extend Forwardable
      self.template_name = 'index.html'

      attr_reader :front_matter, :main_matter, :back_matter, :config
      def_delegators :@header_view, :stylesheets, :theme

      def initialize(stylesheets,theme,front_matter,main_matter,back_matter,config)
        @header_view = HeaderView.new(stylesheets,theme,config)
        @front_matter = front_matter
        @main_matter = main_matter
        @back_matter = back_matter
        super(config)
      end
    end
  end
end
