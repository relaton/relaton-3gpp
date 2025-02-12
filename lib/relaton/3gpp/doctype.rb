module Relaton
  module ThreeGpp
    class Doctype < Relaton::Bib::Doctype
      VALUES = %w[TR TS].freeze

      attribute :content, :string, values: VALUES
    end
  end
end
