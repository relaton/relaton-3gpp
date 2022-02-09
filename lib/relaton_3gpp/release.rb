module Relaton3gpp
  class Release
    #
    # Initialize release.
    #
    # @param [String] version2g
    # @param [String] version3g
    # @param [Boolean] defunct
    # @param [String] wpn_code_2g
    # @param [String] wpn_code_3g
    # @param [String] freeze_stage1_meeting
    # @param [String] freeze_stage2_meeting
    # @param [String] freeze_stage3_meeting
    # @param [String] close_meeting
    # @param [String] project_start
    # @param [String] project_end
    #
    def initialize(**args) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      @version2g = args[:version2g]
      @version3g = args[:version3g]
      @defunct = args[:defunct]
      @wpm_code_2g = args[:wpm_code_2g]
      @wpm_code_3g = args[:wpm_code_3g]
      @freeze_meeting = args[:freeze_meeting]
      @freeze_stage1_meeting = args[:freeze_stage1_meeting]
      @freeze_stage2_meeting = args[:freeze_stage2_meeting]
      @freeze_stage3_meeting = args[:freeze_stage3_meeting]
      @close_meeting = args[:close_meeting]
      @project_start = args[:project_start]
      @project_end = args[:project_end]
    end

    #
    # Render XML.
    #
    # @param [Nokogiri::XML::Builder] builder
    #
    def to_xml(builder) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      builder.release do
        builder.version2G @version2g if @version2g
        builder.version3G @version3g if @version3g
        builder.defunct @defunct unless @defunct.nil?
        builder.send "wpm-code-2G", @wpm_code_2g if @wpm_code_2g
        builder.send "wpm-code-3G", @wpm_code_3g if @wpm_code_3g
        builder.send "freeze-meeting", @freeze_meeting if @freeze_meeting
        builder.send "freeze-stage1-meeting", @freeze_stage1_meeting if @freeze_stage1_meeting
        builder.send "freeze-stage2-meeting", @freeze_stage2_meeting if @freeze_stage2_meeting
        builder.send "freeze-stage3-meeting", @freeze_stage3_meeting if @freeze_stage3_meeting
        builder.send "close-meeting", @close_meeting if @close_meeting
        builder.send "project-start", @project_start if @project_start
        builder.send "project-end", @project_end if @project_end
      end
    end

    #
    # Render Hash.
    #
    # @return [Hash]
    #
    def to_hash
      hash = {}
      instance_variables.each do |var|
        unless instance_variable_get(var).nil?
          hash[var.to_s.delete("@")] = instance_variable_get var
        end
      end
      hash
    end
  end
end
