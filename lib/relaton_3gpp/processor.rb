require "relaton/processor"

module Relaton3gpp
  class Processor < Relaton::Processor
    attr_reader :idtype

    def initialize # rubocop:disable Lint/MissingSuper
      @short = :relaton_3gpp
      @prefix = "3GPP"
      @defaultprefix = %r{^3GPP\s}
      @idtype = "3GPP"
      @datasets = %w[status-smg-3GPP]
    end

    # @param code [String]
    # @param date [String, NilClass] year
    # @param opts [Hash]
    # @return [RelatonBib::BibliographicItem]
    def get(code, date, opts)
      ::Relaton3gpp::Bibliography.get(code, date, opts)
    end

    #
    # Fetch all the documents from http://xml2rfc.tools.ietf.org/public/rfc/bibxml-3gpp-new/
    #
    # @param [String] _source source name
    # @param [Hash] opts
    # @option opts [String] :output directory to output documents
    # @option opts [String] :format
    #
    def fetch_data(_source, opts)
      DataFetcher.fetch(**opts)
    end

    # @param xml [String]
    # @return [RelatonBib::BibliographicItem]
    def from_xml(xml)
      ::Relaton3gpp::XMLParser.from_xml xml
    end

    # @param hash [Hash]
    # @return [RelatonBib::BibliographicItem]
    def hash_to_bib(hash)
      item_hash = ::Relaton3gpp::HashConverter.hash_to_bib(hash)
      ::Relaton3gpp::BibliographicItem.new(**item_hash)
    end

    # Returns hash of XML grammar
    # @return [String]
    def grammar_hash
      @grammar_hash ||= ::Relaton3gpp.grammar_hash
    end
  end
end
