require 'test_helper'
require 'tempfile'
require 'fileutils'
require 'json'

class Bookingit::ConfigTest < Test::Unit::TestCase

  def setup
    @tempdir = Dir.mktmpdir
  end

  def teardown
    remove_entry @tempdir
  end

  test_that "wraps single files in arrays" do
    Given :some_markdown_files
    And {
      @config = {
        front_matter: "foo.md",
        main_matter: "bar.md",
        back_matter: "baz.md",
      }
    }
    When {
      @normalized_config = Bookingit::Config.new(@config.to_json,@tempdir)
    }
    Then {
      assert_equal 1,@normalized_config.front_matter.chapters.size
      assert_equal File.join(@tempdir,'foo.md'),@normalized_config.front_matter.chapters[0].path
      assert_equal 1,@normalized_config.main_matter.chapters.size
      assert_equal File.join(@tempdir,'bar.md'),@normalized_config.main_matter.chapters[0].path
      assert_equal 0,@normalized_config.main_matter.chapters[0].sections.size
      assert_equal 1,@normalized_config.back_matter.chapters.size
      assert_equal File.join(@tempdir,'baz.md'),@normalized_config.back_matter.chapters[0].path
    }
  end

  test_that "does nothing to arrays" do
    Given :some_markdown_files
    And {
      @config = {
        front_matter: ["foo.md"],
        main_matter: ["bar.md"],
        back_matter: ["baz.md"],
      }
    }
    When {
      @normalized_config = Bookingit::Config.new(@config.to_json,@tempdir)
    }
    Then {
      assert_equal 1,@normalized_config.front_matter.chapters.size
      assert_equal File.join(@tempdir,'foo.md'),@normalized_config.front_matter.chapters[0].path
      assert_equal 1,@normalized_config.main_matter.chapters.size
      assert_equal File.join(@tempdir,'bar.md'),@normalized_config.main_matter.chapters[0].path
      assert_equal 0,@normalized_config.main_matter.chapters[0].sections.size
      assert_equal 1,@normalized_config.back_matter.chapters.size
      assert_equal File.join(@tempdir,'baz.md'),@normalized_config.back_matter.chapters[0].path
    }
  end

  test_that "parses sections" do
    Given :some_markdown_files
    And {
      @config = {
        front_matter: ["foo.md"],
        main_matter: [
          "bar.md",
          ["blah1.md","blah2.md"],
        ],
        back_matter: ["baz.md"],
      }
    }
    When {
      @normalized_config = Bookingit::Config.new(@config.to_json,@tempdir)
    }
    Then {
      assert_equal 2,@normalized_config.main_matter.chapters.size,"chapters"
      assert_equal 2,@normalized_config.main_matter.chapters[1].sections.size,"sections"
    }
  end

  test_that "globs" do
    Given :some_markdown_files
    And {
      @config = {
        front_matter: ["foo.md"],
        main_matter: [
          "bar.md",
          "blah*.md",
        ],
        back_matter: ["baz.md"],
      }
    }
    When {
      @normalized_config = Bookingit::Config.new(@config.to_json,@tempdir)
    }
    Then {
      assert_equal 2,@normalized_config.main_matter.chapters.size
      assert_equal 3,@normalized_config.main_matter.chapters[1].sections.size
      assert_equal File.join(@tempdir,'blah1.md'),@normalized_config.main_matter.chapters[1].sections[0].path
      assert_equal File.join(@tempdir,'blah2.md'),@normalized_config.main_matter.chapters[1].sections[1].path
      assert_equal File.join(@tempdir,'blah3.md'),@normalized_config.main_matter.chapters[1].sections[2].path
    }
  end

  test_that "converts rendering config" do
    Given {
      @config = {
        rendering: {
          stylesheets: 'blah.css',
          languages: {
            ".coffee" => "coffeescript",
            "/^Bowerfile$/" => "ruby",
          },
          git_repos_basedir: "/tmp",
        }
      }
    }
    When {
      @normalized_config = Bookingit::Config.new(@config.to_json,@tempdir)
    }
    Then  {
      assert_equal "/tmp",@normalized_config.rendering_config[:basedir]
      assert_equal({ ".coffee" => "coffeescript", /^Bowerfile$/ => "ruby" },@normalized_config.rendering_config[:languages])
      assert_equal ['blah.css'],@normalized_config.rendering_config[:stylesheets]
    }
  end

private

  def some_markdown_files
    chdir @tempdir do
      system "touch foo.md"
      system "touch baz.md"
      system "touch bar.md"
      system "touch blah1.md"
      system "touch blah2.md"
      system "touch blah3.md"
    end
  end
end
