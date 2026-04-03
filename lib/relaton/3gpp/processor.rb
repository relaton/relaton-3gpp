require "relaton/core/processor"

module Relaton
  module ThreeGpp
    class Processor < Relaton::Core::Processor
      attr_reader :idtype

      def initialize # rubocop:disable Lint/MissingSuper
        @short = :relaton_3gpp
        @prefix = "3GPP"
        @defaultprefix = %r{^3GPP\s}
        @idtype = "3GPP"
        @datasets = %w[status-smg-3GPP status-smg-3GPP-force]
      end

      # @param code [String]
      # @param date [String, NilClass] year
      # @param opts [Hash]
      # @return [RelatonBib::BibliographicItem]
      def get(code, date, opts)
        require_relative "../3gpp"
        Bibliography.get(code, date, opts)
      end

      #
      # Fetch all the documents from http://xml2rfc.tools.ietf.org/public/rfc/bibxml-3gpp-new/
      #
      # @param [String] source source name
      # @param [Hash] opts
      # @option opts [String] :output directory to output documents
      # @option opts [String] :format
      #
      def fetch_data(source, opts)
        require_relative "data_fetcher"
        DataFetcher.fetch(source, **opts)
      end

      # @param xml [String]
      # @return [RelatonBib::BibliographicItem]
      def from_xml(xml)
        require_relative "../3gpp"
        Item.from_xml xml
      end

      # @param yaml [String]
      # @return [Relaton::ThreeGpp::Item]
      def from_yaml(yaml)
        require_relative "../3gpp"
        Item.from_yaml(yaml)
      end

      # Returns hash of XML grammar
      # @return [String]
      def grammar_hash
        require_relative "../3gpp"
        @grammar_hash ||= ThreeGpp.grammar_hash
      end

      #
      # Remove index file
      #
      def remove_index_file
        require_relative "../3gpp"
        Relaton::Index.find_or_create("3GPP", url: true, file: "#{INDEXFILE}.yaml").remove_file
      end
    end
  end
end
