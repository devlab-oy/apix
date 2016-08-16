require 'nokogiri'

module Apix
  class Response
    attr_accessor :xml

    def initialize(xml)
      @xml = xml
      @doc = Nokogiri::XML(xml)
    end

    def status
      status = @doc.xpath('//Status').text
      return status unless status.empty?
    end

    def status_code
      @doc.xpath('//StatusCode').text
    end

    def error_messages
      if status.nil?
        ["Empty response"]
      elsif status == "ERR"
        @doc.xpath('//FreeText').text
      else
        []
      end
    end

    def content
      @doc.xpath('//Content')
    end

    def to_hash
      # Parse response to hash of values
      content.xpath('Group').map do |group|
        group.xpath('Value').inject({}) {|hash, value| hash[value.attributes["type"].value] = value.text; hash}
      end
    end
  end
end
