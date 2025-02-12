module Relaton
  module ThreeGpp
    # This class represents a bibliographic item as a bibdata.
    class Bibdata < Item
      model Bib::ItemData

      attribute :ext, Ext

      # Bibtem doesn't have an id attribute.
      mappings[:xml].instance_variable_get(:@attributes).delete("id")

      xml do
        root "bibdata"
      end
    end
  end
end
