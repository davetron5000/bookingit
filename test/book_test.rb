require 'test_helper'
require 'fileutils'

include FileUtils

class Bookingit::BookTest < Test::Unit::TestCase

  def setup
    @tempdir = Dir.mktmpdir
  end

  def teardown
    remove_entry @tempdir
  end

  test_that "we blow up if our markdown doesn't have any H1's" do
  end


end
