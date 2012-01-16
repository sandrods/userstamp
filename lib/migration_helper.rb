module Ddb
  module Userstamp
    module MigrationHelper
      def userstamps(include_deleted_by = false)
        column(Ddb::Userstamp.compatibility_mode ? :created_by : :creator_id, :integer)
        column(Ddb::Userstamp.compatibility_mode ? :updated_by : :updater_id, :integer)
        column(Ddb::Userstamp.compatibility_mode ? :deleted_by : :deleter_id, :integer) if include_deleted_by
      end
    end
  end
end