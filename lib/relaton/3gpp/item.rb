require_relative "item_data"
require_relative "ext"

module Relaton
  module ThreeGpp
    class Item < Bib::Item
      model ItemData

      attribute :ext, Ext
    end
  end
end
