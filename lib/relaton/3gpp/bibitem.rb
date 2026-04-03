module Relaton
  module ThreeGpp
    # This class represents a bibliographic item as a bibitem.
    class Bibitem < Item
      include Bib::BibitemShared
    end
  end
end
