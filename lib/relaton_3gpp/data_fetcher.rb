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
      CSV.open(file, "r:bom|utf-8", headers: true, col_sep: ";").each do |row|
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

      c = case @format
          when "xml" then bib.to_xml(bibdata: true)
          when "yaml" then bib.to_hash.to_yaml
          else bib.send("to_#{@format}")
          end
      file = file_name(bib)
      if @files.include? file
        Util.warn "File #{file} already exists. Document: #{bib.docnumber}"
      else
        @files << file
      end
      index.add_or_update bib.docnumber, file
      File.write file, c, encoding: "UTF-8"
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
