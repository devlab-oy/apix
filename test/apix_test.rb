require File.expand_path('../test_helper', __FILE__)

class ApixTest < Minitest::Test
  def test_version_number
    assert_match /0.0.\d/, Apix::VERSION
  end
end
