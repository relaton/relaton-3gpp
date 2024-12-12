module Relaton3gpp
  module HashConverter
    include RelatonBib::HashConverter
    extend self

    def hash_to_bib(args)
      hash = super
      hash[:radiotechnology] = hash[:ext][:radiotechnology] if hash.dig(:ext, :radiotechnology)
      hash[:common_ims_spec] = hash[:ext][:"common-ims-spec"] if hash.dig(:ext, :"common-ims-spec")
      release_hash_to_bib(hash)
      hash
    end

    def release_hash_to_bib(hash)
      release = hash.dig(:ext, :release) || hash[:release] # @TODO remove hash[:release] after release is moved to ext
      return unless release

      hash[:release] = Release.new(**release)
    end

    # @param item_hash [Hash]
    # @return [Relaton3gpp::BibliographicItem]
    def bib_item(item_hash)
      BibliographicItem.new(**item_hash)
    end

    def create_doctype(**type)
      DocumentType.new(**type)
    end
  end
end
