module Relaton3gpp
  class Parser
    #
    # Document parser initalization
    #
    # @param [Hash] row row
    # @param [Array<Hash>] specrels Spec + Release table
    # @param [Array<Hash>] relaeases Releases table
    # @param [Array<Hash>] specs Specs table
    # @param [Array<Hash>] tstatus temp status-table
    #
    def initialize(row, specs, specrels, releases, tstatus) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      @row = row
      @spec = specs.detect { |s| s[:Number] == row[:spec] }
      if @spec
        @specrel = specrels.detect do |sr|
          sr[:Spec] == row[:spec] && sr[:Release] == row[:release]
        end
        @rel = releases.detect { |r| r[:Release_code] == row[:release] }
      end
      @tstatus = tstatus.detect { |t| t[:Number] == row[:spec] }
    end

    #
    # Initialize document parser and run it
    #
    # @param [Hash] row row
    # @param [Array<Hash>] specrels Spec + Release table
    # @param [Array<Hash>] relaeases Releases table
    # @param [Array<Hash>] specs Specs table
    # @param [Array<Hash>] tstatus temp status-table
    #
    # @return [RelatonBib:BibliographicItem, nil] bibliographic item
    #
    def self.parse(row, specs, specrels, relaeases, tstatus)
      new(row, specs, specrels, relaeases, tstatus).parse
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
        contributor: parse_contributor,
        place: ["Sophia Antipolis Cedex, France"],
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
      [RelatonBib::DocumentIdentifier.new(type: "3GPP", id: "3GPP #{number}", primary: true)]
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
      dates = { completed: "created", ACHIEVED_DATE: "published" }.each_with_object([]) do |(k, t), d|
      # if @row[:completed]
        next unless @row[k]

        cd = Date.parse(@row[k]).to_s
        d << RelatonBib::BibliographicDate.new(type: t, on: cd)
      end
      if @spec[:"title verified"]
        td = Date.parse(@spec[:"title verified"]).to_s
        dates << RelatonBib::BibliographicDate.new(type: "confirmed", on: td)
      end
      dates
    end

    #
    # Parse editorialgroup
    #
    # @return [RelatonBib::EditorialGroup] editorialgroups
    #
    def parse_editorialgroup # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      eg = [create_workgroup(@spec[:"WG prime"], "prime")]
      if @spec[:"WG other"] && @spec[:"WG other"] != "-"
        eg << create_workgroup(@spec[:"WG other"], "other")
      end
      if @spec[:"former WG"]
        eg << create_workgroup(@spec[:"former WG"], "former")
      end
      RelatonBib::EditorialGroup.new eg
    end

    def create_workgroup(name, type)
      wgf = RelatonBib::WorkGroup.new(name: name, type: type)
      RelatonBib::TechnicalCommittee.new(wgf)
    end

    #
    # Parse note
    #
    # @return [RelatonBib::BiblioNoteCollection] notes
    #
    def parse_note
      n = []
      if @specrel && @specrel[:remarks] && @specrel[:remarks] != "."
        n << RelatonBib::BiblioNote.new(type: "remark", content: @specrel[:remarks])
      end
      if @row[:comment] && @row[:comment] != "."
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
    # Create contributors
    #
    # @return [Array<RelatonBib::ContributionInfo>] contributor
    #
    def parse_contributor # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      address = RelatonBib::Address.new(
        street: ["c/o ETSI 650, route des Lucioles", "3GPP Mobile Competence Centre"],
        postcode: "06921", city: "Sophia Antipolis Cedex", country: "France"
      )
      org = RelatonBib::Organization.new(
        name: "3rd Generation Partnership Project", abbreviation: "3GPP", contact: [address],
      )
      contribs = [RelatonBib::ContributionInfo.new(entity: org, role: [type: "author"])]
      return contribs unless @tstatus && @tstatus[:rapporteur]

      aff = []
      if @tstatus[:"rapp org"]
        org = RelatonBib::Organization.new(name: @tstatus[:"rapp org"])
        cn = RelatonBib::LocalizedString.new @tstatus[:rapporteur], "en", "Latn"
        name = RelatonBib::FullName.new(completename: cn)
        aff << RelatonBib::Affiliation.new(organization: org)
      end
      person = RelatonBib::Person.new(name: name, affiliation: aff)
      role = { type: "author" }
      contribs << RelatonBib::ContributionInfo.new(entity: person, role: [role])
    end
  end
end
