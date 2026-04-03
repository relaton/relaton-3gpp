module Relaton
  module ThreeGpp
    class ItemData < Bib::ItemData
      def to_xml(bibdata: false, **opts)
        add_notes opts[:note] do
          bibdata ? Bibdata.to_xml(self) : Bibitem.to_xml(self)
        end
      end

      def to_yaml(**opts)
        add_notes opts[:note] do
          Item.to_yaml(self)
        end
      end

      def to_json(**opts)
        add_notes opts[:note] do
          Item.to_json(self)
        end
      end
    end
  end
end
