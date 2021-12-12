module Relaton3gpp
  class Parser
    #
    # Document parser initalization
    #
    # @param [Hash] row row
    # @param [Array<Hash>] specrels Spec + Release table
    # @param [Array<Hash>] relaeases Releases table
    # @param [Array<Hash>] specs Specs table
    #
    def initialize(row, specs, specrels, releases) # rubocop:disable Metrics/AbcSize
      @row = row
      @spec = specs.detect { |s| s[:Number] == row[:spec] }
      if @spec
        @specrel = specrels.detect do |sr|
          sr[:Spec] == row[:spec] && sr[:Release] == row[:release]
        end
        @rel = releases.detect { |r| r[:Release_code] == row[:release] }
      end
    end

    #
    # Initialize document parser and run it
    #
    # @param [Hash] row row
    # @param [Array<Hash>] specrels Spec + Release table
    # @param [Array<Hash>] relaeases Releases table
    # @param [Array<Hash>] specs Specs table
    #
    # @return [RelatonBib:BibliographicItem, nil] bibliographic item
    #
    def self.parse(row, specs, specrels, relaeases)
      new(row, specs, specrels, relaeases).parse
    end

    #
    # Parse document
    #
    # @return [Relaton3gpp:BibliographicItem, nil] bibliographic item
    #
    def parse # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      return unless @spec && @row[:"3guId"]

      Relaton3gpp::BibliographicItem.new(
        type: "standard",
        fetched: Date.today.to_s,
        language: ["en"],
        script: ["Latn"],
        title: parse_title,
        link: parse_link,
        abstract: parse_abstract,
        docid: parse_docid,
        docnumber: number,
        date: parse_date,
        doctype: @spec[:Type],
        editorialgroup: parse_editorialgroup,
        biblionote: parse_note,
        docstatus: parse_status,
        radiotechnology: parse_radiotechnology,
        common_ims_spec: @spec[:ComIMS] == "1",
        # internal: @spec[:"For publication"] == "0",
        release: parse_release,
        # contributor: contributor,
      )
    end

    #
    # Parse title
    #
    # @return [RelatonBib::TypedTitleStringCollection] title
    #
    def parse_title
      t = RelatonBib::TypedTitleString.new content: @spec[:Title], type: "main"
      RelatonBib::TypedTitleStringCollection.new [t]
    end

    #
    # Parse link
    #
    # @return [Array<RelatonBib::TypedUri>] link
    #
    def parse_link
      return [] unless @row[:location]

      content = @row[:location].split("#").last
      [RelatonBib::TypedUri.new(type: "src", content: content)]
    end

    #
    # Parse abstract
    #
    # @return [Array<RelatonBib::FormattedString>] 
    #
    def parse_abstract
      return [] unless @spec[:description]

      [RelatonBib::FormattedString.new(content: @spec[:description])]
    end

    #
    # Parse docidentifier
    #
    # @return [Arra<RelatonBib::DocumentIdentifier>] docidentifier
    #
    def parse_docid
      [
        RelatonBib::DocumentIdentifier.new(type: "3GPP", id: "3GPP #{number}"),
        RelatonBib::DocumentIdentifier.new(type: "rapporteurId",
                                           id: @spec[:"rapporteur id"]),
      ]
    end

    #
    # Generate number
    #
    # @return [String] number
    #
    def number
      "#{@spec[:Type]} #{@row[:spec]}:#{@row[:release]}/#{version}"
    end

    #
    # Version
    #
    # @return [String] version
    #
    def version
      "#{@row[:MAJOR_VERSION_NB]}.#{@row[:TECHNICAL_VERSION_NB]}.#{@row[:EDITORIAL_VERSION_NB]}"
    end

    #
    # Parse date
    #
    # @return [Array<RelatonBib::BibliographicDate>] date
    #
    def parse_date
      d = []
      if @row[:completed]
        cd = Date.parse(@row[:completed]).to_s
        d << RelatonBib::BibliographicDate.new(type: "created", on: cd)
      end
      if @spec[:"title verified"]
        td = Date.parse(@spec[:"title verified"]).to_s
        d << RelatonBib::BibliographicDate.new(type: "confirmed", on: td)
      end
      d
    end

    #
    # Parse editorialgroup
    #
    # @return [RelatonBib::EditorialGroup] editorialgroups
    #
    def parse_editorialgroup # rubocop:disable Metrics/MethodLength
      wgp = RelatonBib::WorkGroup.new(name: @spec[:"WG prime"], type: "prime")
      eg = [RelatonBib::TechnicalCommittee.new(wgp)]
      if @spec[:"WG other"]
        wgo = RelatonBib::WorkGroup.new(name: @spec[:"WG other"], type: "other")
        eg << RelatonBib::TechnicalCommittee.new(wgo)
      end
      if @spec[:"former WG"]
        wgf = RelatonBib::WorkGroup.new(name: @spec[:"former WG"], type: "former")
        eg << RelatonBib::TechnicalCommittee.new(wgf)
      end
      RelatonBib::EditorialGroup.new eg
    end

    #
    # Parse note
    #
    # @return [RelatonBib::BiblioNoteCollection] notes
    #
    def parse_note
      n = []
      if @specrel && @specrel[:remarks]
        n << RelatonBib::BiblioNote.new(type: "remark", content: @specrel[:remarks])
      end
      if @row[:comment]
        n << RelatonBib::BiblioNote.new(type: "comment", content: @row[:comment])
      end
      RelatonBib::BiblioNoteCollection.new n
    end

    #
    # Prase status
    #
    # @return [RelatnoBib::DocumentStatus, nil] status
    #
    def parse_status
      if @specrel && @specrel[:withdrawn] == "1"
        RelatonBib::DocumentStatus.new stage: "withdrawn"
      elsif @spec[:"For publication"] == "1"
        RelatonBib::DocumentStatus.new stage: "published"
      end
    end

    #
    # Parse radio technology
    #
    # @return [String] radio technology
    #
    def parse_radiotechnology
      if @spec[:"2g"] == "1" then "2G"
      elsif @spec[:"3g"] == "1" then "3G"
      elsif @spec[:LTE] == "1" then "LTE"
      elsif @spec[:"5G"] == "1" then "5G"
      end
    end

    #
    # Parse release
    #
    # @return [Relaton3gpp::Release, nil] release
    #
    def parse_release # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      if @rel
        project_start = Date.parse(@rel[:"rel-proj-start"]).to_s if @rel[:"rel-proj-start"]
        project_end = Date.parse(@rel[:"rel-proj-end"]).to_s if @rel[:"rel-proj-end"]
        Release.new(
          version2g: @rel[:version_2g],
          version3g: @rel[:version_3g],
          defunct: @rel[:defunct] == "1",
          wpm_code_2g: @rel[:wpm_code_2g],
          wpm_code_3g: @rel[:wpm_code_3g],
          freeze_meeting: @rel[:"freeze meeting"],
          freeze_stage1_meeting: @rel[:Stage1_freeze],
          freeze_stage2_meeting: @rel[:Stage2_freeze],
          freeze_stage3_meeting: @rel[:Stage3_freeze],
          close_meeting: @rel[:Closed],
          project_start: project_start,
          project_end: project_end,
        )
      end
    end

    #
    # Create contributor
    #
    # @return [Array<RelatonBib::Contribution>] contributor
    #
    # def contributor
    #   org = RelatonBib::Organization.new(
    #     name: "Internet Assigned Numbers Authority", abbreviation: "IANA",
    #   )
    #   role = { type: "publisher" }
    #   [RelatonBib::ContributionInfo.new(entity: org, role: [role])]
    # end
  end
end
