module Relaton3gpp
  class DocumentType < RelatonBib::DocumentType
    DOCTYPES = %w[TS TR].freeze

    def initialize(type:, abbreviation: nil)
      check type
      super
    end

    # @param type [String]
    def check(type)
      unless DOCTYPES.include? type
        Util.warn "Unknown doctype: `#{type}`"
        Util.warn "Possible doctypes: `#{DOCTYPES.join '`, `'}`"
      end
    end
  end
end
