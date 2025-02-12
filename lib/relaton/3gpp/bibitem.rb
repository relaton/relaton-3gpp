module Relaton
  module ThreeGpp
    # This class represents a bibliographic item as a bibitem.
    class Bibitem < Item
      model Bib::ItemData

      # Bibtem doesn't have an ext element.
      mappings[:xml].instance_variable_get(:@elements).delete("ext")

      xml do
        root "bibitem"
      end
    end
  end
end
