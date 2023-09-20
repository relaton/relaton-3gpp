module Relaton3gpp
  module Util
    extend RelatonBib::Util

    def self.logger
      Relaton3gpp.configuration.logger
    end
  end
end
