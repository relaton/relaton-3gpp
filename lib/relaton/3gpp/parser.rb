require "csv"

module Relaton
  module ThreeGpp
    class Parser
      DOCTYPES = { "TS" => "Technical Specification", "TR" => "Technical Report" }.freeze

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
        Bib::ItemData.new(
          type: "standard",
          language: ["en"],
          script: ["Latn"],
          title: parse_title,
          source: parse_source,
          # abstract: parse_abstract,
          docidentifier: parse_docid,
          docnumber: number,
          date: parse_date,
          version: parse_version,
          contributor: parse_contributor,
          place: parse_place,
          ext: parse_ext,
          # biblionote: parse_note,
          # docstatus: parse_status,
          # common_ims_spec: @spec[:ComIMS] == "1",
          # internal: @spec[:"For publication"] == "0",
        )
      end

      #
      # Parse title
      #
      # @return [RelatonBib::TypedTitleStringCollection] title
      #
      def parse_title
        [Bib::Title.new(content: @row["Title"], type: "main")]
        # RelatonBib::TypedTitleStringCollection.new [t]
      end

      #
      # Parse link
      #
      # @return [Array<RelatonBib::TypedUri>] link
      #
      def parse_source
        return [] unless @row["Link"]

        [Bib::Uri.new(type: "src", content: @row["Link"])]
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
        [Bib::Docidentifier.new(type: "3GPP", content: "3GPP #{number}", primary: true)]
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
        [Bib::Version.new(draft: version)]
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
          dates << Bib::Date.new(type: "published", at: on)
        end
        dates
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
      # Create contributors
      #
      # @return [Array<RelatonBib::ContributionInfo>] contributor
      #
      def parse_contributor # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        name = Bib::TypedLocalizedString.new(content: "3rd Generation Partnership Project")
        abbrev = Bib::LocalizedString.new content: "3GPP"
        org = Bib::Organization.new(name: [name], abbreviation: abbrev, contact: [address])
        contribs = [Bib::Contributor.new(organization: org, role: contributor_role)]
        return contribs unless @row["Last Name"] && @row["Last Name"] != "Vacant"

        role = Bib::Contributor::Role.new type: "author"
        contribs << Bib::Contributor.new(person: person, role: [role])
      end

      def address
        Bib::Address.new(
          street: ["c/o ETSI 650, route des Lucioles", "3GPP Mobile Competence Centre"],
          postcode: "06921", city: "Sophia Antipolis Cedex", country: "France"
        )
      end

      def contributor_role
        [Bib::Contributor::Role.new(type: "author"), Bib::Contributor::Role.new(type: "publisher")]
      end

      def person
        surname = Bib::LocalizedString.new content: @row["Last Name"], language: "en", script: "Latn"
        forename = Bib::FullNameType::Forename.new content: @row["First Name"], language: "en", script: "Latn"
        name = Bib::FullName.new(surname: surname, forename: [forename])
        Bib::Person.new(name: name, affiliation: affiliation)
      end

      def affiliation
        return [] if @row["Organisation"].nil? || @row["Organisation"].empty?

        name = Bib::TypedLocalizedString.new(content: @row["Organisation"])
        org = Bib::Organization.new(name: [name])
        [Bib::Affiliation.new(organization: org)]
      end

      def parse_place
        [Bib::Place.new(formatted_place: "Sophia Antipolis Cedex, France")]
      end

      def parse_ext
        Ext.new(
          doctype: parse_doctype,
          editorialgroup: parse_editorialgroup,
          radiotechnology: parse_radiotechnology,
          release: parse_release,
        )
      end

      def parse_doctype
        type = DOCTYPES[doctype_abbr]
        Doctype.new(abbreviation: doctype_abbr, content: type)
      end

      #
      # Parse editorialgroup
      #
      # @return [RelatonBib::EditorialGroup] editorialgroups
      #
      def parse_editorialgroup # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        eg = []
        prime = @row["Responsible Primary"]
        eg << create_workgroup(prime, "prime") unless prime.nil? || prime.empty?

        @row["Responsible Secondary"].strip.split(", ").each do |wg|
          eg << create_workgroup(wg, "other")
        end
        Bib::EditorialGroup.new technical_committee: eg
      end

      def create_workgroup(name, type)
        Bib::WorkGroup.new(content: name, type: type)
      end

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
        project_start = Date.parse(@row["Project Start"]) if @row["Project Start"]
        project_end = Date.parse(@row["Project End"]) if @row["Project End"]
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
    end
  end
end
