module Bookingit
  module Views
    class FooterView < BaseView
      self.template_name = 'footer.html'

      attr_reader :chapter

      def initialize(chapter)
        @chapter = chapter
        super()
      end
    end
  end
end
