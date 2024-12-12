module Relaton3gpp
  class BibliographicItem < RelatonBib::BibliographicItem
    DOCSUBTYPES = %w[spec release].freeze
    RADIOTECHNOLOGIES = %w[2G 3G LTE 5G].freeze

    # @return [String, nil]
    attr_reader :radiotechnology, :release

    #
    # Initialize bibliographic item.
    #
    # @param [String, nil] radiotechnology
    # @param [Boolean] common_ims_spec
    # @param [Relaton3gpp::Release, nil] release
    #
    def initialize(**args) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      Util.warn "Doctype is missing" if args[:type].nil?
      @radiotechnology = args.delete(:radiotechnology)
      if @radiotechnology && !RADIOTECHNOLOGIES.include?(@radiotechnology)
        Util.warn "Unknown radiotechnology type: `#{@radiotechnology}`"
        Util.warn "Possible radiotechnology types: `#{RADIOTECHNOLOGIES.join '`, `'}`"
      end
      @common_ims_spec = args.delete(:common_ims_spec)
      @release = args.delete(:release)
      if args[:docsubtype] && !DOCSUBTYPES.include?(args[:docsubtype])
        Util.warn "Unknown docsubtype: `#{args[:docsubtype]}`"
        Util.warn "Possible docsubtypes: `#{DOCSUBTYPES.join '`, `'}`"
      end
      super(**args)
    end

    #
    # Fetch the flavor shcema version
    #
    # @return [String] schema version
    #
    def ext_schema
      @ext_schema ||= schema_versions["relaton-model-3gpp"]
    end

    #
    # @override RelatonBib::BibliographicItem#makeid
    #
    # @param [RelatonBib::DocumentIdentifier, nil] identifier <description>
    # @param [Boolean, nil] attribute true if the ID attribute is needed
    #
    # @return [String, nil] id
    #
    def makeid(identifier, attribute)
      super&.sub(/^3GPP/, "")
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
          ext = b.ext do
            doctype&.to_xml b
            b.subdoctype subdoctype if subdoctype
            editorialgroup&.to_xml b
            ics.each { |i| i.to_xml b }
            b.radiotechnology radiotechnology if radiotechnology
            b.send :"common-ims-spec", @common_ims_spec if @common_ims_spec
            release&.to_xml b
          end
          ext["schema-version"] = ext_schema unless opts[:embedded]
        end
      end
    end

    def has_ext_attrs? # rubocop:disable Metrics/CyclomaticComplexity
      doctype || subdoctype || editorialgroup || ics.any? || radiotechnology ||
        @common_ims_spec || release
    end

    #
    # Convert to hash.
    #
    # @return [Hash
    #
    def to_hash(embedded: false)
      hash = super
      hash["ext"]["radiotechnology"] = radiotechnology if radiotechnology
      hash["ext"]["common-ims-spec"] = @common_ims_spec if @common_ims_spec
      hash["ext"]["release"] = release.to_hash if release
      hash
    end

    def has_ext?
      super || radiotechnology || @common_ims_spec || release
    end
  end
end
