require_relative "doctype"
require_relative "release"

module Relaton
  module ThreeGpp
    class Ext < Bib::Ext
      attribute :doctype, Doctype
      attribute :release, Release
      attribute :subdoctype, :string, values: %w[spec release]
      attribute :radiotechnology, :string, values: %w[2G 3G LTE 5G]
      attribute :common_ims_spec, :boolean
      attribute :internal, :boolean

      def get_schema_version = Relaton.schema_versions["relaton-model-3gpp"]

      xml do
        map_element "radiotechnology", to: :radiotechnology
        map_element "common-ims-spec", to: :common_ims_spec
        map_element "internal", to: :internal
        map_element "release", to: :release
      end

      key_value do
        map_element "radiotechnology", to: :radiotechnology
        map_element "common_ims_spec", to: :common_ims_spec
        map_element "internal", to: :internal
        map_element "release", to: :release
      end
    end
  end
end
