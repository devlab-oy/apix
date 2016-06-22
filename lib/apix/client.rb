module Apix
  class Client
    attr_accessor :transfer_id, :transfer_key

    def initialize(transfer_id: nil, transfer_key: nil, password: nil, unique_company_id: nil)
      @transfer_id       = transfer_id
      @transfer_key      = transfer_key
      @password          = password
      @unique_company_id = unique_company_id

      validate_arguments!
    end

    # Retrieves the system generated TransferID,TransferKey and UniqueCompanyID.
    # The application should store these interally.
    # GET /app-transferID?id=<company y-tunnus>&idq=<id qualifier>&uid=<UserID>&ts=<timestamp>&d=SHA-256:<digest>
    def self.retrieve_transfer_id(id: nil, idq: nil, uid: nil, password: nil)
      raise ArgumentError.new('Missing arguments [id, uid, password]') if id.nil? || uid.nil? || password.nil?

      idq = idq || 'y-tunnus'
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')

      password_digest = Digest::SHA256.hexdigest( password )
      digest_param = "SHA-256:#{Digest::SHA256.hexdigest( [id, idq, uid, timestamp, password_digest].join('+') )}"

      # Get transfer ids
      url = URI::HTTPS.build(
        host: Apix.configuration.url,
        path: '/app-transferID',
        query: URI.encode_www_form({id: id, idq: idq, uid: uid, ts: timestamp, d: digest_param})
      )
      response = Response.new(RestClient.get url.to_s)

      # Parse response
      params = {}
      response.content.xpath('Group/Value').each do |value|
        case value.attributes["type"].value
        when "TransferID"
          params[:transfer_id] = value.text
        when "TransferKey"
          params[:transfer_key] = value.text
        when "UniqueCompanyID"
          params[:unique_company_id] = value.text
        else
          raise
        end
      end

      # Returns instance of Apix::Client
      new(transfer_id: params[:transfer_id], transfer_key: params[:transfer_key], unique_company_id: params[:unique_company_id])
    end

    # Allows sending of a ZIP-file containing one to several invoices (inhouse format) and their corresponding PDF-images (as single files) and optionally also attachments (as single zip-files) to the invoices.
    # Note: Usage of this service requires a valid contract of type 'Lähetä'.
    # PUT /invoices?soft=<software>&ver=<version>&TraID=<TransferID>&t=<Timestamp>&d=SHA-256:<digest>
    def self.send_invoice_zip(filepath)
      return unless File.exists?(filepath)

      file_content = File.open(filepath).read
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')

      params = {
        soft: Apix.configuration.soft,
        ver: Apix.configuration.ver,
        TraID: Apix.configuration.transfer_id,
        t: timestamp,
        d: "SHA-256:" + self.calculate_digest_with_transfer_key(Apix.configuration.transfer_key, {transfer_id: Apix.configuration.transfer_id, ts: timestamp})
      }

      self.request(:put, '/invoices', params, file_content, { content_type: 'application/octet-stream', content_length: file_content.size })
    end

    # Returns the delivery channel and price for individual documents.
    # Note Preferred way is to use DeliveryMethod instead of PricingInfo
    # PUT /method?uid=<TransferID>&t=<timestamp>&d=SHA-256:<digest>
    # Authentication with SHA-256 hash (<SHA-256:digest>) using the TransferKey as the 'shared secret'
    def delivery_method(sender_name: nil, sender_ytunnus: nil, receiver_name: nil, receiver_ytunnus: nil)
      url = build_url('/method', uid: @transfer_id, t: Time.now.strftime('%Y%m%d%H%M%S'))

      request_template = %{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Request version="1.0">
          <Content>
            <Group>
              <Value type="SenderName">#{sender_name}</Value>
              <Value type="SenderYtunnus">#{sender_ytunnus}</Value>
              <Value type="ReceiverName">#{receiver_name}</Value>
              <Value type="ReceiverYtunnus">#{receiver_ytunnus}</Value>
             </Group>
          </Content>
        </Request>
      }

      response = Response.new(RestClient.put url, request_template, { content_type: "text/xml" })
      return response.to_hash
    end

    # Returns all of the einvoice addresses and operators for given company name and / or businessId.
    # PUT /addressquery?uid=<TransferID>&t=<timestamp>&d=SHA-256:<digest>
    def self.address_query(id: nil)
      url = self.build_url('/addressquery', uid: Apix.configuration.transfer_id, t: Time.now.strftime('%Y%m%d%H%M%S'))

      request_template =  %{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Request version="1.0">
         <Content>
           <Group>
            <Value type="ReceiverYtunnus">#{id}</Value>
           </Group>
         </Content>
        </Request>
      }

      response = Response.new(RestClient.put url, request_template, { content_type: "text/xml" })
      return response.to_hash
    end

    # Allows sending of a ZIP-file containing one to several documents in PDF format accompanied with an XML-metadata file. The letters are sent as defined in the agreements (customer settable options in the Apix management www-appliaction).
    # Note: Usage of this service requires a valid contract of type 'Lähetä'.
    # PUT /print?soft=<software>&ver=<version>&TraID=<TransferID>&t=<Timestamp>&d=SHA-256:<digest>
    def send_print_zip(filepath)
      return unless File.exists?(filepath)

      file_content = File.open(filepath).read
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')

      params = {
        soft: Apix.configuration.soft,
        ver: Apix.configuration.ver,
        TraID: @transfer_id,
        t: timestamp,
        d: "SHA-256:" + calculate_digest_with_transfer_key(@transfer_key, {transfer_id: @transfer_id, ts: timestamp})
      }

      request(:put, '/print', params, file_content, { content_type: 'application/octet-stream', content_length: file_content.size })
    end

    private

      def validate_arguments!
        error = ArgumentError.new("transfer_key or password must be present")
        fail error if (@transfer_key.nil? || @transfer_key.empty?) && (@password.nil? || @password.empty?)
      end

      def self.build_url(endpoint, params)
        string = (params.values << Apix.configuration.transfer_key).join('+')
        d     = "SHA-256:" + Digest::SHA256.hexdigest(string)
        query = URI.encode_www_form(params.merge(d: d))

        URI::HTTPS.build(host: Apix.configuration.url, path: endpoint, query: query).to_s
      end

      def self.request(method, url, query_string, content = nil, options = {})
        url = URI::HTTPS.build(host: Apix.configuration.url, path: url, query: URI.encode_www_form(query_string))

        case method
        when :get
          response = RestClient.get url.to_s
        when :put
          response = RestClient.put url.to_s, content, options
        else
          raise
        end

        Response.new(response)
      end

      def calculate_digest(string)
        Digest::SHA256.hexdigest(string)
      end

      def calculate_digest_with_password(password, params = {})
        raise ArgumentError if password.nil?
        password_digest = Digest::SHA256.hexdigest password
        Digest::SHA256.hexdigest [params[:id], params[:idq], params[:uid], params[:ts], password_digest].join('+')
      end

      def self.calculate_digest_with_transfer_key(transfer_key, params = {})
        raise ArgumentError if transfer_key.nil?

        Digest::SHA256.hexdigest [
          Apix.configuration.soft,
          Apix.configuration.ver,
          params[:transfer_id],
          params[:ts],
          transfer_key
          ].join('+')
      end

  end # Client
end # Apix
