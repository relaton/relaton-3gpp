module Relaton3gpp
  class Parser
    DOCTYPES = { "TS" => "Technical Specification", "TR" => "Technical Report"}.freeze

    #
    # Document parser initalization
    #
    # @param [CSV::Row] row CSV row
    #
    def initialize(row)
      @row = row
    end

    #
    # Initialize document parser and run it
    #
    # @param [CSV:Row] row CSV row
    #
    # @return [RelatonBib:BibliographicItem, nil] bibliographic item
    #
    def self.parse(row)
      new(row).parse
    end

    #
    # Parse document
    #
    # @return [Relaton3gpp:BibliographicItem, nil] bibliographic item
    #
    def parse # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      Relaton3gpp::BibliographicItem.new(
        type: "standard",
        language: ["en"],
        script: ["Latn"],
        title: parse_title,
        link: parse_link,
        # abstract: parse_abstract,
        docid: parse_docid,
        docnumber: number,
        date: parse_date,
        doctype: parse_doctype,
        editorialgroup: parse_editorialgroup,
        version: parse_version,
        # biblionote: parse_note,
        # docstatus: parse_status,
        radiotechnology: parse_radiotechnology,
        # common_ims_spec: @spec[:ComIMS] == "1",
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
      t = RelatonBib::TypedTitleString.new content: @row["Title"], type: "main"
      RelatonBib::TypedTitleStringCollection.new [t]
    end

    #
    # Parse link
    #
    # @return [Array<RelatonBib::TypedUri>] link
    #
    def parse_link
      return [] unless @row["Link"]

      [RelatonBib::TypedUri.new(type: "src", content: @row["Link"])]
    end

    #
    # Parse abstract
    #
    # @return [Array<RelatonBib::FormattedString>]
    #
    # def parse_abstract
    #   return [] unless @spec[:description]

    #   [RelatonBib::FormattedString.new(content: @spec[:description])]
    # end

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
      num = "#{doctype_abbr} #{@row[0]}"
      num += ":#{release}" if release
      "#{num}/#{version}"
    end

    def version
      @row["Version"]
    end

    def parse_version
      [RelatonBib::BibliographicItem::Version.new(nil, version)]
    end

    def doctype_abbr
      @row["Is TS"] == "1" ? "TS" : "TR"
    end

    def release
      @release ||=  case @row["WPM Code 2G"]
                    when /Release_(\d+)/ then "REL-#{$1}"
                    when /PH(\d+)/ then "Ph#{$1}"
                    else @row["Release"]
                    end
    end

    #
    # Version
    #
    # @return [String] version
    #
    # def version
    #   "#{@row[:MAJOR_VERSION_NB]}.#{@row[:TECHNICAL_VERSION_NB]}.#{@row[:EDITORIAL_VERSION_NB]}"
    # end

    #
    # Parse date
    #
    # @return [Array<RelatonBib::BibliographicDate>] date
    #
    def parse_date
      dates = []
      if @row["Date"]
        on = Date.parse(@row["Date"]).to_s
        dates << RelatonBib::BibliographicDate.new(type: "published", on: on)
      end
      dates
    end

    def parse_doctype
      # type = DOCTYPES[doctype_abbr]
      DocumentType.new(type: doctype_abbr)
    end

    #
    # Parse editorialgroup
    #
    # @return [RelatonBib::EditorialGroup] editorialgroups
    #
    def parse_editorialgroup # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      eg = []
      prime = @row["Responsible Primary"]
      eg << create_workgroup(prime, "prime") if prime

      @row["Responsible Secondary"].strip.split(", ").each do |wg|
        eg << create_workgroup(wg, "other")
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
    # def parse_note
    #   n = []
    #   if @specrel && @specrel[:remarks] && @specrel[:remarks] != "."
    #     n << RelatonBib::BiblioNote.new(type: "remark", content: @specrel[:remarks])
    #   end
    #   if @row[:comment] && @row[:comment] != "."
    #     n << RelatonBib::BiblioNote.new(type: "comment", content: @row[:comment])
    #   end
    #   RelatonBib::BiblioNoteCollection.new n
    # end

    #
    # Prase status
    #
    # @return [RelatnoBib::DocumentStatus, nil] status
    #
    # def parse_status
    #   if @specrel && @specrel[:withdrawn] == "1"
    #     RelatonBib::DocumentStatus.new stage: "withdrawn"
    #   elsif @spec[:"For publication"] == "1"
    #     RelatonBib::DocumentStatus.new stage: "published"
    #   end
    # end

    #
    # Parse radio technology
    #
    # @return [String] radio technology
    #
    def parse_radiotechnology
      case @row["WPM Code 3G"]
      when /5G/ then "5G"
      when /4G/ then "LTE"
      when /3G/ then "3G"
      else @row["WPM Code 2G"] && "2G"
      end
    end

    #
    # Parse release
    #
    # @return [Relaton3gpp::Release, nil] release
    #
    def parse_release # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      project_start = Date.parse(@row["Project Start"]).to_s if @row["Project Start"]
      project_end = Date.parse(@row["Project End"]).to_s if @row["Project End"]
      Release.new(
        # version2g: @rel[:version_2g],
        # version3g: @rel[:version_3g],
        # defunct: @rel[:defunct] == "1",
        wpm_code_2g: @row["WPM Code 2G"],
        wpm_code_3g: @row["WPM Code 3G"],
        # freeze_meeting: @rel[:"freeze meeting"],
        freeze_stage1_meeting: @row["Stage 1 Freeze"],
        freeze_stage2_meeting: @row["Stage 2 Freeze"],
        freeze_stage3_meeting: @row["Stage 3 Freeze"],
        close_meeting: @row["Close Meeting"],
        project_start: project_start,
        project_end: project_end,
      )
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
      roles = [{ type: "author" }, { type: "publisher" }]
      contribs = [RelatonBib::ContributionInfo.new(entity: org, role: roles)]
      return contribs unless @row["Last Name"] && @row["Last Name"] != "Vacant"

      aff = []
      if @row["Organisation"]
        org = RelatonBib::Organization.new(name: @row["Organisation"])
        aff << RelatonBib::Affiliation.new(organization: org)
      end
      surname = RelatonBib::LocalizedString.new @row["Last Name"], "en", "Latn"
      forename = RelatonBib::Forename.new content: @row["First Name"], language: ["en"], script: ["Latn"]
      name = RelatonBib::FullName.new(surname: surname, forename: [forename])
      person = RelatonBib::Person.new(name: name, affiliation: aff)
      role = { type: "author" }
      contribs << RelatonBib::ContributionInfo.new(entity: person, role: [role])
    end
  end
end
