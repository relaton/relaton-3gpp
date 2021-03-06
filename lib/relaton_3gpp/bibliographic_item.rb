module Relaton3gpp
  class BibliographicItem < RelatonBib::BibliographicItem
    DOCTYPES = %w[TR TS].freeze
    DOCSUBTYPES = %w[spec release].freeze
    RADIOTECHNOLOGIES = %w[2G 3G LTE 5G].freeze

    #
    # Initialize bibliographic item.
    #
    # @param [String] radiotechnology
    # @param [Boolean] common_ims_spec
    # @param [Relaton3gpp::Release] release
    #
    def initialize(**args) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @radiotechnology = args.delete(:radiotechnology)
      if @radiotechnology && !RADIOTECHNOLOGIES.include?(@radiotechnology)
        warn "[relaton-3gpp] Unknown radiotechnology type: #{@radiotechnology}"
        warn "[relaton-3gpp] Possible radiotechnology types: #{RADIOTECHNOLOGIES.join ' '}"
      end
      @common_ims_spec = args.delete(:common_ims_spec)
      @release = args.delete(:release)
      if args[:doctype].nil? then warn "[relaton-3gpp] doctype is missing"
      elsif !DOCTYPES.include?(args[:doctype])
        warn "[relaton-3gpp] Unknown doctype: #{args[:doctype]}"
        warn "[relaton-3gpp] Possible doctypes: #{DOCTYPES.join ' '}"
      end
      if args[:docsubtype] && !DOCSUBTYPES.include?(args[:docsubtype])
        warn "[relaton-3gpp] Unknown docsubtype: #{args[:docsubtype]}"
        warn "[relaton-3gpp] Possible docsubtypes: #{DOCSUBTYPES.join ' '}"
      end
      super(**args)
    end

    # @param opts [Hash]
    # @option opts [Nokogiri::XML::Builder] :builder XML builder
    # @option opts [Boolean] :bibdata
    # @option opts [String] :lang language
    # @return [String] XML
    def to_xml(**opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      super do |b|
        if block_given? then yield b
        elsif opts[:bibdata] && has_ext_attrs?
          b.ext do
            b.doctype doctype if doctype
            b.subdoctype subdoctype if subdoctype
            editorialgroup&.to_xml b
            ics.each { |i| i.to_xml b }
            b.radiotechnology @radiotechnology if @radiotechnology
            b.send "common-ims-spec", @common_ims_spec if @common_ims_spec
            @release&.to_xml b if @release
          end
        end
      end
    end

    def has_ext_attrs? # rubocop:disable Metrics/CyclomaticComplexity
      doctype || subdoctype || editorialgroup || ics.any? || @radiotechnology ||
        @common_ims_spec || @release
    end

    #
    # Convert to hash.
    #
    # @return [Hash
    #
    def to_hash
      hash = super
      hash["radiotechnology"] = @radiotechnology if @radiotechnology
      hash["common-ims-spec"] = @common_ims_spec if @common_ims_spec
      hash["release"] = @release.to_hash if @release
      hash
    end
  end
end
