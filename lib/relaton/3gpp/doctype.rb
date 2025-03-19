module Relaton
  module ThreeGpp
    class Doctype < Relaton::Bib::Doctype
      TYPES = %w[TR TS].freeze

      attribute :content, :string, values: TYPES
    end
  end
end
