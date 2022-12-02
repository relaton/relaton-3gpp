# frozen_string_literal: true

module Relaton3gpp
  # Methods for search IANA standards.
  module Bibliography
    # SOURCE = "http://xml2rfc.tools.ietf.org/public/rfc/bibxml-3gpp-new/"
    SOURCE = "https://raw.githubusercontent.com/relaton/relaton-data-3gpp/main/data/"

    # @param text [String]
    # @return [RelatonBib::BibliographicItem]
    def search(text) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      file = text.sub(/^3GPP\s/, "").gsub(/[\s,:\/]/, "_").squeeze("_").upcase
      url = "#{SOURCE}#{file}.yaml"
      resp = Net::HTTP.get_response URI(url)
      return unless resp.code == "200"

      hash = YAML.safe_load resp.body
      bib_hash = Relaton3gpp::HashConverter.hash_to_bib(hash)
      bib_hash[:fetched] = Date.today.to_s
      Relaton3gpp::BibliographicItem.new(**bib_hash)
    rescue SocketError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
           EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
           Net::ProtocolError, Errno::ETIMEDOUT => e
      raise RelatonBib::RequestError, e.message
    end

    # @param ref [String] the W3C standard Code to look up
    # @param year [String, NilClass] not used
    # @param opts [Hash] options
    # @return [RelatonBib::BibliographicItem]
    def get(ref, _year = nil, _opts = {})
      warn "[relaton-3gpp] (\"#{ref}\") fetching..."
      result = search(ref)
      unless result
        warn "[relaton-3gpp] (\"#{ref}\") not found"
        return
      end

      warn "[relaton-3gpp] (\"#{ref}\") found #{result.docidentifier[0].id}"
      result
    end

    extend Bibliography
  end
end
