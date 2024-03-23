# frozen_string_literal: true

require "net/http"
require "relaton/index"
require "relaton_bib"
require_relative "relaton_3gpp/version"
require_relative "relaton_3gpp/util"
require_relative "relaton_3gpp/document_type"
require_relative "relaton_3gpp/release"
require_relative "relaton_3gpp/bibliographic_item"
require_relative "relaton_3gpp/hash_converter"
require_relative "relaton_3gpp/xml_parser"
require_relative "relaton_3gpp/bibliography"
require_relative "relaton_3gpp/parser"
require_relative "relaton_3gpp/data_fetcher"

module Relaton3gpp
  class Error < StandardError; end

  # Returns hash of XML reammar
  # @return [String]
  def self.grammar_hash
    # gem_path = File.expand_path "..", __dir__
    # grammars_path = File.join gem_path, "grammars", "*"
    # grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
    Digest::MD5.hexdigest Relaton3gpp::VERSION + RelatonBib::VERSION # grammars
  end
end
