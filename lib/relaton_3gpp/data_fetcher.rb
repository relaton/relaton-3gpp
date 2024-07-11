module Relaton3gpp
  class DataFetcher
    CURRENT = "current.yaml".freeze
    #
    # Data fetcher initializer
    #
    # @param [String] output directory to save files
    # @param [String] format format of output files (xml, yaml, bibxml)
    #
    def initialize(output, format)
      require "fileutils"
      require "net/ftp"
      require "csv"

      @output = output
      @format = format
      @ext = format.sub(/^bib/, "")
      @files = []
    end

    def index
      @index ||= Relaton::Index.find_or_create "3gpp", file: "index-v1.yaml"
    end

    #
    # Initialize fetcher and run fetch
    #
    # @param [Strin] source source name
    # @param [Strin] output directory to save files, default: "data"
    # @param [Strin] format format of output files (xml, yaml, bibxml), default: yaml
    #
    def self.fetch(source, output: "data", format: "yaml")
      t1 = Time.now
      puts "Started at: #{t1}"
      FileUtils.mkdir_p output
      new(output, format).fetch(source == "status-smg-3GPP-force")
      t2 = Time.now
      puts "Stopped at: #{t2}"
      puts "Done in: #{(t2 - t1).round} sec."
    end

    #
    # Parse documents
    #
    # @param [Boolean] renewal force to update all documents
    #
    def fetch(renewal) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      file = get_file renewal
      return unless file && File.exist?(file) && File.size(file) > 20_000_000

      if renewal
        FileUtils.rm_f File.join(@output, "/*") # if renewal && dbs["2001-04-25_schedule"].any?
        index.remove_all # if renewal
      end
      CSV.open(file, "r:bom|utf-8", headers: true).each do |row|
        save_doc Parser.parse(row)
      end
      File.write CURRENT, @current.to_yaml, encoding: "UTF-8"
      index.save
    end

    #
    # Get file from FTP. If file does not exist or changed, return nil
    #
    # @param [Boolean] renewal force to update all documents
    #
    # @return [String, nil] file name
    #
    def get_file(renewal) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @current = YAML.load_file CURRENT if File.exist? CURRENT
      @current ||= {}
      n = 0
      begin
        ftp = Net::FTP.new("www.3gpp.org")
        ftp.resume = true
        ftp.login
        ftp.chdir "/Information/Databases/"
        file_path = ftp.list("*.csv").first
        return unless file_path

        d, t, _, file = file_path.split
        dt = DateTime.strptime("#{d} #{t}", "%m-%d-%y %I:%M%p")
        if !renewal && file == @current["file"] && !@current["date"].empty? && dt == DateTime.parse(@current["date"])
          return
        end

        tmp_file = File.join Dir.tmpdir, "3gpp.csv"
        ftp.get(file, tmp_file)
      rescue Net::ReadTimeout => e
        n += 1
        retry if n < 5
        raise e
      end
      @current["file"] = file
      @current["date"] = dt.to_s
      tmp_file
    end

    #
    # Fetch document
    #
    # @param [Hash] row row from mdb
    # @param [Array<Hash>] specs specs
    # @param [Array<Hash>] specrels specrels
    # @param [Array<Hash>] releases releases
    # @param [Array<Hash>] tstatus tstatus
    #
    # @return [Relaton3gpp::BibliographicItem, nil] bibliographic item
    #
    # def fetch_doc(row, specs, specrels, releases, tstatus)
    #   doc = Parser.parse row, specs, specrels, releases, tstatus
    #   save_doc doc
    # rescue StandardError => e
    #   warn "Error: #{e.message}"
    #   warn "PubID: #{row[:spec]}:#{row[:release]}/#{row[:MAJOR_VERSION_NB]}."\
    #        "#{row[:TECHNICAL_VERSION_NB]}.#{row[:EDITORIAL_VERSION_NB]}"
    #   warn e.backtrace[0..5].join("\n")
    # end

    #
    # Save document to file
    #
    # @param [RelatonW3c::W3cBibliographicItem, nil] bib bibliographic item
    #
    def save_doc(bib) # rubocop:disable Metrics/MethodLength
      return unless bib

      bib1 = bib
      file = file_name(bib1)
      if @files.include? file
        bib1 = merge_duplication bib1, file
        Util.warn "File #{file} already exists. Document: #{bib.docnumber}" if bib1.nil?
      else
        @files << file
        index.add_or_update bib1.docnumber, file
      end
      File.write file, serialise(bib1), encoding: "UTF-8" unless bib1.nil?
    end

    #
    # Merge duplication
    #
    # @param [Relaton3gpp::BibliographicItem] bib new bibliographic item
    # @param [String] file file name of existing bibliographic item
    #
    # @return [Relaton3gpp::BibliographicItem, nil] merged bibliographic item or nil if no merge has been done
    #
    def merge_duplication(bib, file)
      hash = YAML.load_file file
      existed = BibliographicItem.from_hash hash
      changed = update_link bib, existed
      bib1, bib2, chng = transposed_relation bib, existed
      changed ||= chng
      chng = add_contributor(bib1, bib2)
      changed ||= chng
      bib1 if changed
    end

    #
    # Update link in case one of bibliographic items has no link
    #
    # @param [Relaton3gpp::BibliographicItem] bib1
    # @param [Relaton3gpp::BibliographicItem] bib2
    #
    # @return [Boolean] true if link has been updated
    #
    def update_link(bib1, bib2)
      if bib1.link.any? && bib2.link.empty?
        bib2.instance_variable_set(:@link, bib1.link)
        true
      elsif bib1.link.empty? && bib2.link.any?
        bib1.instance_variable_set(:@link, bib2.link)
        true
      else false
      end
    end

    #
    # If one of bibliographic items has date gereater than anotherm=, make it relation
    #
    # @param [Relaton3gpp::BibliographicItem] bib new bibliographic item
    # @param [Relaton3gpp::BibliographicItem] existed existing bibliographic item
    #
    # @return [Array<Relaton3gpp::BibliographicItem, Boolean>] main bibliographic item,
    #   related bibliographic item, true if relation has been added
    #
    def transposed_relation(bib, existed) # rubocop:disable Metrics/CyclomaticComplexity
      return [bib, existed, false] if bib.date.none? && existed.date.none? ||
        bib.date.any? && existed.date.none?
      return [existed, bib, true] if bib.date.none? && existed.date.any?

      check_transposed_date bib, existed
    end

    #
    # Check if date of one bibliographic item is transposed to another
    #
    # @param [Relaton3gpp::BibliographicItem] bib new bibliographic item
    # @param [Relaton3gpp::BibliographicItem] existed existing bibliographic item
    #
    # @return [Array<Relaton3gpp::BibliographicItem, Boolean>] main bibliographic item,
    #   related bibliographic item, true if relation has been added
    #
    def check_transposed_date(bib, existed)
      if bib.date[0].on < existed.date[0].on
        add_transposed_relation bib, existed
        [bib, existed, true]
      elsif bib.date[0].on > existed.date[0].on
        add_transposed_relation existed, bib
        [existed, bib, true]
      else [bib, existed, false]
      end
    end

    #
    # Add transposed relation
    #
    # @param [Relaton3gpp::BibliographicItem] bib1 the main bibliographic item
    # @param [Relaton3gpp::BibliographicItem] bib2 the transposed bibliographic item
    #
    # @return [Relaton3gpp::BibliographicItem]
    #
    def add_transposed_relation(bib1, bib2)
      bib2.relation.each { |r| bib1.relation << r }
      bib2.instance_variable_set :@relation, RelatonBib::DocRelationCollection.new([])
      dec = RelatonBib::FormattedString.new content: "equivalent"
      rel = RelatonBib::DocumentRelation.new(type: "adoptedAs", bibitem: bib2, description: dec)
      bib1.relation << rel
    end

    def add_contributor(bib1, bib2) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      changed = false

      bib2.contributor.each do |bc|
        next if bc.entity.is_a? RelatonBib::Organization

        existed = bib1.contributor.find { |ic| ic.entity.name == bc.entity.name }
        if existed
          chng = add_affiliation existed, bc.entity.affiliation
          changed ||= chng
        else
          bib1.contributor << bc
          changed = true
        end
      end

      changed
    end

    def add_affiliation(contrib, affiliation)
      changed = false

      affiliation.each do |a|
        unless contrib.entity.affiliation.include? a
          contrib.entity.affiliation << a
          changed = true
        end
      end

      changed
    end

    def serialise(bib)
      case @format
      when "xml" then bib.to_xml(bibdata: true)
      when "yaml" then bib.to_hash.to_yaml
      else bib.send("to_#{@format}")
      end
    end

    #
    # Generate file name
    #
    # @param [RelatonW3c::W3cBibliographicItem] bib bibliographic item
    #
    # @return [String] file name
    #
    def file_name(bib)
      name = bib.docnumber.gsub(/[\s,:\/]/, "_").squeeze("_").upcase
      File.join @output, "#{name}.#{@ext}"
    end
  end
end
