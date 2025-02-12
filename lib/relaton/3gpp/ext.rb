require_relative "doctype"
require_relative "release"

module Relaton
  module ThreeGpp
    class Ext < Lutaml::Model::Serializable
      attribute :schema_version, :string
      attribute :doctype, Doctype
      attribute :subdoctype, :string, values: %w[spec release]
      attribute :editorialgroup, Relaton::Bib::EditorialGroup
      attribute :ics, Relaton::Bib::ICS, collection: true
      attribute :radiotechnology, :string, values: %w[2G 3G LTE 5G]
      attribute :common_ims_spec, :boolean
      attribute :internal, :boolean
      attribute :release, Release

      xml do
        map_attribute "schema-version", to: :schema_version
        map_element "doctype", to: :doctype
        map_element "subdoctype", to: :subdoctype
        map_element "editorialgroup", to: :editorialgroup
        map_element "ics", to: :ics
        map_element "radiotechnology", to: :radiotechnology
        map_element "common-ims-spec", to: :common_ims_spec
        map_element "internal", to: :internal
        map_element "release", to: :release
      end
    end
  end
end
