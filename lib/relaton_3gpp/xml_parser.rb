module Relaton3gpp
  class XMLParser < RelatonBib::XMLParser
    class << self
      private

      #
      # Parse XML to hash
      #
      # @param [Nokofiri::XML::Element] bibitem
      #
      # @return [Hash]
      #
      def item_data(bibitem)
        hash = super
        ext = bibitem.at "./ext"
        if ext
          hash[:radiotechnology] = ext.at("./radiotechnology")&.text
          hash[:common_ims_spec] = ext.at("./common-ims-spec")&.text
          hash[:release] = fetch_release(ext)
        end
        hash
      end

      #
      # Ftech release information
      #
      # @param [Nokogiri::XML::Element] ext
      #
      # @return [Relaton3gpp::Release] release
      #
      def fetch_release(ext) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
        release = ext.at("./release")
        return unless release

        hash = {}
        hash[:version2g] = release.at("./version2G")&.text
        hash[:version3g] = release.at("./version3G")&.text
        hash[:defunct] = release.at("./defunct")&.text
        hash[:wpm_code_2g] = release.at("./wpm-code-2G")&.text
        hash[:wpm_code_3g] = release.at("./wpm-code-3G")&.text
        hash[:freeze_meeting] = release.at("./freeze-meeting")&.text
        hash[:freeze_stage1_meeting] = release.at("./freeze-stage1-meeting")&.text
        hash[:freeze_stage2_meeting] = release.at("./freeze-stage2-meeting")&.text
        hash[:freeze_stage3_meeting] = release.at("./freeze-stage3-meeting")&.text
        hash[:close_meeting] = release.at("./close-meeting")&.text
        hash[:project_start] = release.at("./project-start")&.text
        hash[:project_end] = release.at("./project-end")&.text
        Release.new(**hash)
      end

      # @param item_hash [Hash]
      # @return [RelatonSgpp::BibliographicItem]
      def bib_item(item_hash)
        BibliographicItem.new(**item_hash)
      end

      def create_doctype(type)
        DocumentType.new type: type.text, abbreviation: type[:abbreviation]
      end
    end
  end
end
