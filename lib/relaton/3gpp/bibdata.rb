module Relaton
  module ThreeGpp
    # This class represents a bibliographic item as a bibdata.
    class Bibdata < Item
      include Bib::BibdataShared
    end
  end
end
