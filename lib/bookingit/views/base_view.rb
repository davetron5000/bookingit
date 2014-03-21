module Bookingit
  module Views
    class BaseView < Mustache
      self.template_path = File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','templates'))
    end
  end
end
