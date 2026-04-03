# frozen_string_literal: true

module Relaton
  module ThreeGpp
    # Methods for search IANA standards.
    module Bibliography
      # SOURCE = "http://xml2rfc.tools.ietf.org/public/rfc/bibxml-3gpp-new/"
      SOURCE = "https://raw.githubusercontent.com/relaton/relaton-data-3gpp/refs/heads/data-v2/"

      # @param text [String]
      # @return [RelatonBib::BibliographicItem]
      def search(text) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        index = Relaton::Index.find_or_create "3GPP", url: "#{SOURCE}#{INDEXFILE}.zip", file: "#{INDEXFILE}.yaml"
        row = index.search(text.sub(/^3GPP\s/, "")).min_by { |r| r[:id] }
        return unless row

        # file = text.sub(/^3GPP\s/, "").gsub(/[\s,:\/]/, "_").squeeze("_").upcase
        url = "#{SOURCE}#{row[:file]}"
        resp = Net::HTTP.get_response URI(url)
        return unless resp.code == "200"

        item = Item.from_yaml(resp.body)
        item.fetched = Date.today.to_s
        item
      rescue SocketError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
            EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
            Net::ProtocolError, Errno::ETIMEDOUT => e
        raise Relaton::RequestError, e.message
      end

      # @param ref [String] the W3C standard Code to look up
      # @param year [String, NilClass] not used
      # @param opts [Hash] options
      # @return [RelatonBib::BibliographicItem]
      def get(ref, _year = nil, _opts = {})
        Util.info "Fetching from Relaton repository ...", key: ref
        result = search(ref)
        unless result
          Util.info "Not found.", key: ref
          return
        end

        Util.info "Found: `#{result.docidentifier[0].content}`", key: ref
        result
      end

      extend Bibliography
    end
  end
end
