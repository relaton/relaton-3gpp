require "csv"

module Relaton
  module ThreeGpp
    class Parser
      # DOCTYPES = { "TS" => "Technical Specification", "TR" => "Technical Report" }.freeze

      #
      # Document parser initalization
      #
      # @param [CSV::Row] row CSV row
      #
      def initialize(row, errors)
        @row = row
        @errors = errors
      end

      #
      # Initialize document parser and run it
      #
      # @param [CSV:Row] row CSV row
      # @param [Hash] errors collection of parsing errors
      #
      # @return [RelatonBib:BibliographicItem, nil] bibliographic item
      #
      def self.parse(row, errors = {})
        new(row, errors).parse
      end

      #
      # Parse document
      #
      # @return [Relaton3gpp:BibliographicItem, nil] bibliographic item
      #
      def parse # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        ItemData.new(
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
        @errors[:title] &&= @row["Title"].nil? || @row["Title"].empty?
        [Bib::Title.new(content: @row["Title"], type: "main")]
      end

      #
      # Parse link
      #
      # @return [Array<RelatonBib::TypedUri>] link
      #
      def parse_source
        @errors[:source] &&= @row["Link"].nil? || @row["Link"].empty?
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
        @errors[:docid] &&= @row[0].nil? || @row[0].empty?
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
        @errors[:version] &&= version.nil? || version.empty?
        [Bib::Version.new(draft: version)]
      end

      def doctype_abbr
        @row["Is TS"] == "1" ? "TS" : "TR"
      end

      def release
        @release ||= begin
          r = case @row["WPM Code 2G"]
              when /Release_(\d+)/ then "REL-#{$1}"
              when /PH(\d+)/ then "Ph#{$1}"
              else @row["Release"]
              end
          @errors[:release] &&= r.nil? || r.empty?
          r
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
        @errors[:date] &&= dates.empty?
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
        org = Bib::Organization.new(name: [name], abbreviation: abbrev, address: [address])
        contribs = [Bib::Contributor.new(organization: org, role: contributor_role)]
        if @row["Last Name"] && @row["Last Name"] != "Vacant"
          role = Bib::Contributor::Role.new type: "author"
          contribs << Bib::Contributor.new(person: person, role: [role])
        end
        @errors[:contributor] &&= contribs.empty?
        contribs + prime_contribs + other_contribs
      end

      def other_contribs
        contribs = @row["Responsible Secondary"].strip.split(", ").map do |wg|
          editorial_group_contributor(wg, "other")
        end
        @errors[:editorial_group_contributor_other] &&= contribs.empty?
        contribs
      end

      def prime_contribs
        prime = @row["Responsible Primary"]
        if prime.nil? || prime.empty?
          @errors[:editorial_group_contributor_prime] &&= true
          return []
        end

        @errors[:editorial_group_contributor_prime] &&= false
        [editorial_group_contributor(prime, "prime")]
      end

      def editorial_group_contributor(wg_name, wg_type)
        Bib::Contributor.new(
          role: [Bib::Contributor::Role.new(
            type: "author",
            description: [Bib::LocalizedMarkedUpString.new(content: "committee")],
          )],
          organization: Bib::Organization.new(
            subdivision: [Bib::Subdivision.new(
              type: "technical-committee",
              subtype: wg_type,
              name: [Bib::TypedLocalizedString.new(content: wg_name)],
            )],
          ),
        )
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
        name = Bib::FullName.new(surname: surname, forename: [forename])
        Bib::Person.new(name: name, affiliation: affiliation)
      end

      def surname
        if @row["Last Name"].nil? || @row["Last Name"].empty?
          @errors[:contributor_person_surname] &&= true
          return nil
        end

        @errors[:contributor_person_surname] &&= false
        Bib::LocalizedString.new content: @row["Last Name"], language: "en", script: "Latn"
      end

      def forename
        if @row["First Name"].nil? || @row["First Name"].empty?
          @errors[:contributor_person_forename] &&= true
          return nil
        end

        @errors[:contributor_person_forename] &&= false
        Bib::FullNameType::Forename.new content: @row["First Name"], language: "en", script: "Latn"
      end

      def affiliation
        if @row["Organisation"].nil? || @row["Organisation"].empty?
          @errors[:contributor_person_affiliation] &&= true
          return []
        end

        @errors[:contributor_person_affiliation] &&= false
        name = Bib::TypedLocalizedString.new(content: @row["Organisation"])
        org = Bib::Organization.new(name: [name])
        [Bib::Affiliation.new(organization: org)]
      end

      def parse_place
        country = Bib::Place::RegionType.new(content: "France", iso: "FR")
        [Bib::Place.new(city: "Sophia Antipolis Cedex", country: [country])]
      end

      def parse_ext
        Ext.new(
          doctype: parse_doctype,
          flavor: "3gpp",
          radiotechnology: parse_radiotechnology,
          release: parse_release,
        )
      end

      def parse_doctype
        # type = DOCTYPES[doctype_abbr]
        # Doctype.new(abbreviation: doctype_abbr, content: type)
        Doctype.new(content: doctype_abbr) # 3GPP grammar alloves only TS and TR content
      end

      #
      # Parse radio technology
      #
      # @return [String] radio technology
      #
      def parse_radiotechnology
        result = case @row["WPM Code 3G"]
                 when /5G/ then "5G"
                 when /4G/ then "LTE"
                 when /3G/ then "3G"
                 else @row["WPM Code 2G"] && "2G"
                 end
        @errors[:radiotechnology] &&= result.nil?
        result
      end

      #
      # Parse release
      #
      # @return [Relaton3gpp::Release, nil] release
      #
      def parse_release # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        unless wmp_code2g || wmp_code3g || stage1_freeze || stage2_freeze ||
            stage3_freeze || close_meeting || project_start || project_end
          return
        end

        Release.new(
          # version2g: @rel[:version_2g],
          # version3g: @rel[:version_3g],
          # defunct: @rel[:defunct] == "1",
          wpm_code_2g: wmp_code2g,
          wpm_code_3g: wmp_code3g,
          # freeze_meeting: @rel[:"freeze meeting"],
          freeze_stage1_meeting: stage1_freeze,
          freeze_stage2_meeting: stage2_freeze,
          freeze_stage3_meeting: stage3_freeze,
          close_meeting: close_meeting,
          project_start: project_start,
          project_end: project_end,
        )
      end

      def wmp_code2g
        @errors[:wmp_code_2g] &&= @row["WPM Code 2G"].nil? || @row["WPM Code 2G"].empty?
        @row["WPM Code 2G"]
      end

      def wmp_code3g
        @errors[:wmp_code_3g] &&= @row["WPM Code 3G"].nil? || @row["WPM Code 3G"].empty?
        @row["WPM Code 3G"]
      end

      def stage1_freeze
        @errors[:freeze_stage1_meeting] &&= @row["Stage 1 Freeze"].nil? || @row["Stage 1 Freeze"].empty?
        @row["Stage 1 Freeze"]
      end

      def stage2_freeze
        @errors[:freeze_stage2_meeting] &&= @row["Stage 2 Freeze"].nil? || @row["Stage 2 Freeze"].empty?
        @row["Stage 2 Freeze"]
      end

      def stage3_freeze
        @errors[:freeze_stage3_meeting] &&= @row["Stage 3 Freeze"].nil? || @row["Stage 3 Freeze"].empty?
        @row["Stage 3 Freeze"]
      end

      def close_meeting
        @errors[:close_meeting] &&= @row["Close Meeting"].nil? || @row["Close Meeting"].empty?
        @row["Close Meeting"]
      end

      def project_start
        @errors[:project_start] &&= @row["Project Start"].nil? || @row["Project Start"].empty?
        Date.parse(@row["Project Start"]) if @row["Project Start"]
      end

      def project_end
        @errors[:project_end] &&= @row["Project End"].nil? || @row["Project End"].empty?
        Date.parse(@row["Project End"]) if @row["Project End"]
      end
    end
  end
end
