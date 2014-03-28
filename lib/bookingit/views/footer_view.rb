module Bookingit
  module Views
    class FooterView < BaseView
      self.template_name = 'footer.html'

      attr_reader :chapter

      def initialize(chapter,config)
        @chapter = chapter
        super(config)
      end
    end
  end
end
