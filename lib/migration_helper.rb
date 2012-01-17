module Ddb
  module Userstamp
    module MigrationHelper
      def userstamps(include_deleted_by = false)
        column(:creator_id, :integer)
        column(:updater_id, :integer)
        column(:deleter_id, :integer) if include_deleted_by
      end
    end
  end
end