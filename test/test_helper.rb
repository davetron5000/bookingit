require 'test/unit'
require 'clean_test/test_case'
require 'bookingit'
require "mocha/test_unit"

# Add test libraries you want to use here, e.g. mocha

class Test::Unit::TestCase
  include Clean::Test::GivenWhenThen
  include Clean::Test::TestThat
  include Clean::Test::Any

  # Add global extensions to the test case class here
  
end
I18n.enforce_available_locales = false 
