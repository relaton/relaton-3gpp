require "net/http"
require "relaton/index"
require "relaton/bib"
require_relative "3gpp/version"
require_relative "3gpp/util"
require_relative "3gpp/item"
require_relative "3gpp/bibitem"
require_relative "3gpp/bibdata"
require_relative "3gpp/data_fetcher"

module Relaton
  module ThreeGpp
    # Returns hash of XML reammar
    # @return [String]
    def self.grammar_hash
      # gem_path = File.expand_path "..", __dir__
      # grammars_path = File.join gem_path, "grammars", "*"
      # grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
      Digest::MD5.hexdigest Relaton3gpp::VERSION + RelatonBib::VERSION # grammars
    end
  end
end
