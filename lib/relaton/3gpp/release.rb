module Relaton
  module ThreeGpp
    class Release < Lutaml::Model::Serializable
      attribute :version2g, :string
      attribute :version3g, :string
      attribute :defunct, :boolean
      attribute :wpm_code_2g, :string
      attribute :wpm_code_3g, :string
      attribute :freeze_meeting, :string
      attribute :freeze_stage1_meeting, :string
      attribute :freeze_stage2_meeting, :string
      attribute :freeze_stage3_meeting, :string
      attribute :close_meeting, :string
      attribute :project_start, :date
      attribute :project_end, :date

      xml do
        root "release"
        map_element "version2G", to: :version2g
        map_element "version3G", to: :version3g
        map_element "defunct", to: :defunct
        map_element "wpm-code-2G", to: :wpm_code_2g
        map_element "wpm-code-3G", to: :wpm_code_3g
        map_element "freeze-meeting", to: :freeze_meeting
        map_element "freeze-stage1-meeting", to: :freeze_stage1_meeting
        map_element "freeze-stage2-meeting", to: :freeze_stage2_meeting
        map_element "freeze-stage3-meeting", to: :freeze_stage3_meeting
        map_element "close-meeting", to: :close_meeting
        map_element "project-start", to: :project_start
        map_element "project-end", to: :project_end
      end
    end
  end
end
