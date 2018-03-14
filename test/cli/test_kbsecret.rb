# frozen_string_literal: true

require "helpers"

# tests cli commands: built-in (help, version, commands, types, & conf)
class CLIBuiltinsTest < Minitest::Test
  include Aruba::Api
  include Helpers
  include Helpers::CLI

  def setup
    setup_aruba
  end

  def test_help
    # `kbsecret help` should always run, and should produce a "Usage:" output
    kbsecret "help", interactive: false do |stdout, _|
      assert_match(/Usage/, stdout)
    end
  end

  def test_version
    exp = "kbsecret version #{KBSecret::VERSION}."

    # `kbsecret version` should always run, and should produce KBSecret's current version
    kbsecret "version", interactive: false do |stdout, _|
      assert_equal exp, stdout.chomp
    end
  end

  def test_commands
    # `kbsecret commands` should always run
    kbsecret "commands"
  end

  def test_types
    # `kbsecret types` should always run, and should produce every type known to KBSecret
    kbsecret "types", interactive: false do |stdout, _|
      KBSecret::Record.record_types.each do |type|
        assert_includes stdout, type.to_s
      end
    end
  end
end
