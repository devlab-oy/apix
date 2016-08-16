require File.expand_path('../test_helper', __FILE__)

class ResponseTest < Minitest::Test
  def setup
    @error_response = %{
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Response>
          <Status>ERR</Status>
          <StatusCode>7599</StatusCode>
          <FreeText language="en">2016-03-21 14:49:0008</FreeText>
          <FreeText language="en">Parameter can't be null: id.</FreeText>
          <Content/>
      </Response>
    }

    @valid_response = %{
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Response>
          <Status>OK</Status>
          <StatusCode>5500</StatusCode>
          <FreeText language="en_US">OK</FreeText>
          <Content>
              <Group>
                  <Value type="UniqueCompanyID">tgjxx-ccqo0-1291809809-f6u2nvpq5</Value>
                  <Value type="Saldo">29.88</Value>
              </Group>
          </Content>
      </Response>
    }
  end

  def teardown
  end

  def test_valid_messages
    response = Apix::Response.new(@valid_response)
    assert_equal "OK", response.status
    assert_equal "5500", response.status_code
    assert [], response.error_messages
  end

  def test_error_response
    response = Apix::Response.new(@error_response)
    assert_equal "ERR", response.status
    assert_equal "7599", response.status_code
    assert "Parameter can't be null: id.", response.error_messages[1]

    response = Apix::Response.new("")
    assert_equal nil, response.status
    assert_equal "Empty response", response.error_messages[0]
  end

  def test_response_to_hash
    hash_response = Apix::Response.new(@valid_response).to_hash
    assert_equal [{"UniqueCompanyID" => "tgjxx-ccqo0-1291809809-f6u2nvpq5", "Saldo" => "29.88"}], hash_response
  end

  def test_content
    response = Apix::Response.new(@valid_response)
    assert_equal "29.88", response.content.xpath("//Group/Value[@type='Saldo']").text
  end
end
