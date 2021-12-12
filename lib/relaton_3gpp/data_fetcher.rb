require "fileutils"
require "net/ftp"
require "zip"
require "mdb"

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
      @output = output
      @format = format
      @ext = format.sub(/^bib/, "")
      @files = []
    end

    #
    # Initialize fetcher and run fetch
    #
    # @param [Strin] output directory to save files, default: "data"
    # @param [Strin] format format of output files (xml, yaml, bibxml), default: yaml
    #
    def self.fetch(output: "data", format: "yaml")
      t1 = Time.now
      puts "Started at: #{t1}"
      FileUtils.mkdir_p output unless Dir.exist? output
      new(output, format).fetch
      t2 = Time.now
      puts "Stopped at: #{t2}"
      puts "Done in: #{(t2 - t1).round} sec."
    end

    #
    # Parse documents
    #
    def fetch # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      file = get_file
      return unless file

      Zip::File.open(file) do |zip_file|
        enntry = zip_file.glob("status_smg_3GPP.mdb").first
        File.write "status_smg_3GPP.mdb", enntry.get_input_stream.read
      end
      dbs = Mdb.open "status_smg_3GPP.mdb"
      specs = dbs["Specs_GSM+3G"]
      specrels = dbs["Specs_GSM+3G_release-info"]
      releases = dbs["Releases"]
      dbs["2001-04-25_schedule"].each do |row|
        fetch_doc row, specs, specrels, releases
      end
    end

    #
    # Get file from FTP
    #
    # @return [String] file name
    #
    def get_file # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      current = YAML.load_file CURRENT if File.exist? CURRENT
      current ||= {}
      ftp = Net::FTP.new("www.3gpp.org")
      ftp.resume = true
      ftp.login
      ftp.chdir "/Information/Databases/Spec_Status/"
      d, t, _, file = ftp.list("*.zip").first.split
      dt = DateTime.strptime("#{d} #{t}", "%m-%d-%y %I:%M%p")
      return if file == current["file"] && dt == DateTime.parse(current["date"])

      ftp.getbinaryfile file
      current["file"] = file
      current["date"] = dt.to_s
      File.write CURRENT, current.to_yaml, encoding: "UTF-8"
      file
    end

    #
    # Fetch document
    #
    # @param [Hash] row row from mdb
    # @param [Mdb] dbs mdb
    #
    # @return [Relaton3gpp::BibliographicItem, nil] bibliographic item
    #
    def fetch_doc(row, specs, specrels, releases)
      doc = Parser.parse row, specs, specrels, releases
      save_doc doc
    rescue StandardError => e
      warn "Error: #{e.message}"
      warn "PubID: #{row[:spec]}:#{row[:release]}/#{row[:MAJOR_VERSION_NB]}."\
           "#{row[:TECHNICAL_VERSION_NB]}.#{row[:EDITORIAL_VERSION_NB]}"
      warn e.backtrace[0..5].join("\n")
    end

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
        warn "File #{file} already exists. Document: #{bib.docnumber}"
      else
        @files << file
      end
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
