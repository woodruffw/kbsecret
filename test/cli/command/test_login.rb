# frozen_string_literal: true

require "helpers"

# Tests for KBSecret::CLI::Command::Login
class KBSecretCommandLoginTest < Minitest::Test
  include Helpers
  include Helpers::CLI

  def test_login_help
    login_helps = [
      %w[login --help],
      %w[login -h],
      %w[help login],
    ]

    login_helps.each do |login_help|
      stdout, = kbsecret(*login_help)
      assert_match(/Usage:/, stdout)
    end
  end

  def test_login_too_few_arguments
    _, stderr = kbsecret "login"

    assert_match(/Too few arguments given/, stderr)
  end

  def test_login_no_such_records
    _, stderr = kbsecret "login", "this_record_really_should_not_exist"

    assert_match(/No such record\(s\)/, stderr)

    # this should also fail, since `kbsecret login` filters for login records only
    kbsecret "new", "environment", "test-login-with-env", input: "key\nvalue\n"
    _, stderr = kbsecret "login", "test-login-with-env"

    assert_match(/No such record\(s\)/, stderr)
  ensure
    kbsecret "rm", "test-login-with-env"
  end

  def test_login_single_record
    expected = <<~OUTPUT
      Label: test-login-single
      \tUsername: foo
      \tPassword: bar
    OUTPUT

    kbsecret "new", "login", "test-login-single", input: "foo\nbar\n"

    stdout, = kbsecret "login", "test-login-single"

    assert_equal expected, stdout
  ensure
    kbsecret "rm", "test-login-single"
  end

  def test_login_multiple_records
    expected1 = <<~OUTPUT
      Label: test-login-multi1
      \tUsername: foo
      \tPassword: bar
    OUTPUT

    expected2 = <<~OUTPUT
      Label: test-login-multi2
      \tUsername: baz
      \tPassword: quux
    OUTPUT

    kbsecret "new", "login", "test-login-multi1", input: "foo\nbar\n"
    kbsecret "new", "login", "test-login-multi2", input: "baz\nquux\n"

    stdout, = kbsecret "login", "test-login-multi1", "test-login-multi2"

    # we expect the output to include both login records, in any order
    assert stdout.include?(expected1)
    assert stdout.include?(expected2)
  ensure
    kbsecret "rm", "test-login-multi1", "test-login-multi2"
  end

  def test_login_all
    stdout, = kbsecret "login", "-a"

    count = stdout.lines.count { |line| line =~ /^Label:/ }

    assert_equal KBSecret::Session[:default].records(:login).size, count
  end

  def test_login_terse_single_record
    expected = "test-login-terse-single:foo:bar\n"

    kbsecret "new", "login", "test-login-terse-single", input: "foo\nbar\n"

    stdout, = kbsecret "login", "test-login-terse-single", "-x"

    assert_equal expected, stdout
  ensure
    kbsecret "rm", "test-login-terse-single"
  end

  def test_login_terse_multiple_records
    expecteds = %w[
      test-login-terse-multi1:foo:bar
      test-login-terse-multi2:baz:quux
    ]

    kbsecret "new", "login", "test-login-terse-multi1", input: "foo\nbar\n"
    kbsecret "new", "login", "test-login-terse-multi2", input: "baz\nquux\n"

    stdout, = kbsecret "login", "-x", "test-login-terse-multi1", "test-login-terse-multi2"

    # we expect the output to include both login records, in any order
    expecteds.each { |e| assert stdout.include?(e) }
  ensure
    kbsecret "rm", "test-login-terse-multi1", "test-login-terse-multi2"
  end

  def test_login_terse_custom_ifs
    with_env("IFS" => "@") do
      expected1 = "test-login-ifs+foo+bar\n"
      expected2 = "test-login-ifs@foo@bar\n"

      kbsecret "new", "login", "test-login-ifs", input: "foo\nbar\n"

      stdout, = kbsecret "login", "test-login-ifs", "-xi", "+"

      assert_equal expected1, stdout

      stdout, = kbsecret "login", "test-login-ifs", "-x"

      assert_equal expected2, stdout
    end
  ensure
    kbsecret "rm", "test-login-ifs"
  end

  def test_login_terse_all
    stdout, = kbsecret "login", "-xa"

    assert_equal KBSecret::Session[:default].records(:login).size, stdout.lines.size
  end

  def test_login_username_only
    expected = <<~OUTPUT
      Label: test-login-username-only
      \tUsername: foo
    OUTPUT

    kbsecret "new", "login", "test-login-username-only", input: "foo\nbar\n"

    stdout, = kbsecret "login", "-u", "test-login-username-only"

    assert_equal expected, stdout
  ensure
    kbsecret "rm", "test-login-username-only"
  end

  def test_login_terse_username_only
    expected = "test-login-terse-username-only:foo\n"

    kbsecret "new", "login", "test-login-terse-username-only", input: "foo\nbar\n"

    stdout, = kbsecret "login", "-xu", "test-login-terse-username-only"

    assert_equal expected, stdout
  ensure
    kbsecret "rm", "test-login-terse-username-only"
  end

  def test_login_accepts_session
    session_label = "login-test-session"
    expected = <<~OUTPUT
      Label: test-login-session
      \tUsername: foo
      \tPassword: bar
    OUTPUT

    kbsecret "session", "new", session_label, "-r", session_label

    kbsecret "new", "-s", session_label, "login", "test-login-session", input: "foo\nbar\n"

    stdout, = kbsecret "login", "-s", session_label, "test-login-session"

    assert_equal expected, stdout
  ensure
    kbsecret "session", "rm", "-d", session_label
  end
end
