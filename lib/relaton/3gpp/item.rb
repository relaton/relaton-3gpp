require_relative "ext"

module Relaton
  module ThreeGpp
    class Item < Relaton::Bib::Item
      model Bib::ItemData

      attribute :ext, Ext
    end
  end
end
