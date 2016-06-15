require File.expand_path('../test_helper', __FILE__)

class ApixTest < Minitest::Test
  def test_version_number
    assert_equal "0.0.1", Apix::VERSION
  end
end
