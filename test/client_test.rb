require File.expand_path('../test_helper', __FILE__)

class ClientTest < Minitest::Test
  def setup
    Apix.configure do |config|
      config.soft = "Economix"
      config.ver = "1.0"
      config.transfer_id = "1234567890"
      config.transfer_key = "098765432"
    end

    @client = Apix::Client.new(transfer_key: 'transfer_key', transfer_id: 'transfer_id')
  end

  def test_should_not_initialize
    assert_raises(ArgumentError) { Apix::Client.new() }
    assert_raises(ArgumentError) { Apix::Client.new(password: nil) }
    assert_raises(ArgumentError) { Apix::Client.new(transfer_key: nil, transfer_id: nil) }
    assert_raises(ArgumentError) { Apix::Client.new(transfer_key: "", transfer_id: "") }
  end

  def test_should_initialize_with_transfer_key
    client = Apix::Client.new(transfer_key: 'transfer_key', transfer_id: 'transfer_id')
    assert client
  end

  def test_should_initialize_with_password
    client = Apix::Client.new(password: 'badpassword')
    assert client
  end

  def test_should_initialize_with_retrieve_transfer_id_method
    RestClient.stub :get, nil do
      Apix::Response.stub :new, Apix::Response.new(retrieve_transfer_id_response) do
        @client = Apix::Client.retrieve_transfer_id(id: "2332748-7", uid: "juha.litola@vendep.com", password: "badpassword")
        assert_kind_of Apix::Client, @client
        assert_equal "fdf09a47-5e99-4773-9379-3f26c8861eea", @client.transfer_id
        assert_equal "de6b8d40-f81b-4d51-b977-c998510b51bb", @client.transfer_key
      end
    end
  end

  def test_configure_block
    assert_equal "Economix", Apix.configuration.soft
    assert_equal "1.0", Apix.configuration.ver

    # override configure options
    Apix.configure do |config|
      config.soft = "Devlab"
      config.ver = "1.6"
    end

    assert_equal "Devlab", Apix.configuration.soft
    assert_equal "1.6", Apix.configuration.ver
  end

  def test_calculate_digest
    # with password
    # hash(params + password hash)
    # SHA-256:e8eaaaad722d3a6884b7408f911a03b255ac54d668737d2463cde81f085e6295
    timestamp = "20100621103800"

    params = {
      id: "2332748-7",
      idq: "y-tunnus",
      uid: "juha.litola@vendep.com",
      ts: timestamp,
      d: @client.send(:calculate_digest, 'badpassword')
    }

    assert_equal "e8eaaaad722d3a6884b7408f911a03b255ac54d668737d2463cde81f085e6295",
                  @client.send(:calculate_digest, params.values.join('+'))

    # Example (SendInvoiceZip)
    # hash(params + transfer_key)
    # SHA-256:4dcec9922f9729311b53363cb313425d8b31a71c5983ea2204f4bfcf7ac74d23
    params = {
      soft: "Economix",
      ver: "1.0",
      transfer_id: "18984859858",
      ts: timestamp,
      transfer_key: "8874926028"
    }

    assert_equal "4dcec9922f9729311b53363cb313425d8b31a71c5983ea2204f4bfcf7ac74d23",
                  @client.send(:calculate_digest, params.values.join('+'))
  end

  def test_calculate_digest_with_password
    timestamp = "20100621103800"
    params = {
      id: "2332748-7",
      idq: "y-tunnus",
      uid: "juha.litola@vendep.com",
      ts: timestamp
    }
    assert_equal "e8eaaaad722d3a6884b7408f911a03b255ac54d668737d2463cde81f085e6295",
                  @client.send(:calculate_digest_with_password, 'badpassword', params)
  end

  def test_calculate_digest_with_transfer_key
    timestamp = "20100621103800"
    params = {
      ts: timestamp,
      transfer_id: 18984859858
    }
    assert_equal "4dcec9922f9729311b53363cb313425d8b31a71c5983ea2204f4bfcf7ac74d23",
                  Apix::Client.send(:calculate_digest_with_transfer_key, '8874926028', params)
  end

  # SendInvoiceZIP
  def test_send_invoice_zip
    RestClient.stub :put, send_invoice_zip_response do
      assert_equal send_invoice_zip_response, Apix::Client.send_invoice_zip('test/files/test_invoice.zip').xml
    end
  end

  def test_delivery_method
    skip
  end

  def test_address_query
    RestClient.stub :put, address_query_response do
      assert_equal address_query_response, Apix::Client.address_query(id: '0838105-5').xml
    end
  end

  private

    def address_query_response
      %{<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
        <Response>
          <Status>OK</Status>
          <StatusCode>2A00</StatusCode>
          <Content>
            <Group>
              <Value type=\"ReceiverName\">Devlab Oy</Value>
              <Value type=\"ReceiverYtunnus\">0838105-5</Value>
              <Value type=\"ReceivereInvoiceAddress\">003708381055</Value>
              <Value type=\"ReceiverOperator\">Apix</Value>
              <Value type=\"ReceiverOperatorId\">00372332748700001</Value>
            </Group>
            <Group>
              <Value type=\"ReceiverName\">Devlab Oy</Value>
              <Value type=\"ReceiverYtunnus\">0838105-5</Value>
              <Value type=\"ReceivereInvoiceAddress\">@devlab.fi@</Value>
              <Value type=\"ReceiverOperator\">Apix</Value>
              <Value type=\"ReceiverOperatorId\">00372332748700001</Value>
            </Group>
          </Content>
        </Response>
      }
    end

    # Stubbed responses
    def retrieve_transfer_id_response
      %{
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Response version="1.0">
             <Status>OK</Status>
             <StatusCode>5000</StatusCode>
             <FreeText language="en">OK</FreeText>
             <Content>
                <Group>
                <Value type="TransferID">fdf09a47-5e99-4773-9379-3f26c8861eea</Value>
                <Value type="TransferKey">de6b8d40-f81b-4d51-b977-c998510b51bb</Value>
                <Value type="UniqueCompanyID">0f6aa87f-ce1d-44ce-b025-8b9801c8772c</Value>
                </Group>
             </Content>
        </Response>
      }
    end

    def send_invoice_zip_response
      %{
      <Response version="1.0">
           <Status>OK</Status>
           <StatusCode>1000</StatusCode>
           <FreeText language="en">OK</FreeText>
           <Content>
              <Group>
              <Value type="BatchID">1633b003-0315-44ca-a687-a25f92bf6123</Value>
              <Value type="Saldo">199</Value>
              <Value type="CostInCredits">1</Value>
              <Value type="NetworkedInvoices">1</Value>
              <Value type="Letters">0</Value>
              <Value type="LetterPages">0</Value>
              <Value type="AcceptedDocument">1</Value>
              </Group>
              <Group>
                      <Value type="AcceptedDocumentID">1001</Value>
                      <Value type="ValidateText">Document InvoiceID 1001 Warning:BuyerOganisationTaxCode is missing</Value>
              </Group>
           </Content>
      </Response>
      }
    end

end
