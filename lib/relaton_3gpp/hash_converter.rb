module Relaton3gpp
  class HashConverter < RelatonBib::HashConverter
    class << self
      def hash_to_bib(args, nested = false)
        hash = super
        release_hash_to_bib(hash)
        hash
      end

      def release_hash_to_bib(hash)
        Release.new(**hash[:release]) if hash[:release]
      end

      # @param item_hash [Hash]
      # @return [RelatonBib::BibliographicItem]
      def bib_item(item_hash)
        BibliographicItem.new(**item_hash)
      end
    end
  end
end
