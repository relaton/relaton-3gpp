require "fileutils"
require "net/ftp"
require "zip"
require "mdb"

module Relaton3gpp
  class DataFetcher
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
    def fetch
      file = get_file
      Zip::File.open(file) do |zip_file|
        enntry = zip_file.glob("status_smg_3GPP.mdb").first
        File.write "status_smg_3GPP.mdb", enntry.get_input_stream.read
      end
      dbs = Mdb.open "status_smg_3GPP.mdb"
      dbs["2001-04-25_schedule"].each do |row|
        fetch_doc row, dbs
      end
    end

    #
    # Get file from FTP
    #
    # @return [String] file name
    #
    def get_file
      ftp = Net::FTP.new("www.3gpp.org")
      ftp.resume = true
      ftp.login
      ftp.chdir "/Information/Databases/Spec_Status/"
      file_size, file = ftp.list("*.zip").first.split[2..3]
      unless File.exist?(file) && file_size.to_i == File.size(file)
        ftp.getbinaryfile file
      end
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
    def fetch_doc(row, dbs)
      doc = Parser.parse row, dbs
      save_doc doc
    rescue StandardError => e
      warn "Error: #{e.message}. Number: #{row[:Number]}"
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
      name = bib.docnumber.gsub(/[\s,:\/]/, "_").squeeze("_")
      File.join @output, "#{name}.#{@ext}"
    end
  end
end
