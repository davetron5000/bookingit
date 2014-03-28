module Bookingit
  module Views
    class BaseView < Mustache
      attr_reader :config
      self.template_path = File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','templates'))

      def initialize(config)
        @config = config.options
      end
    end
  end
end
