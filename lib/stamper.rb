module Ddb #:nodoc:
  module Userstamp
    module Stamper

      def model_stamper
        send(:extend, Ddb::Userstamp::Stamper::StamperMethods)
      end

      module StamperMethods
        # Used to set the stamper for a particular request. See the Userstamp module for more
        # details on how to use this method.
        def stamper=(object)
          object_stamper = if object.is_a?(ActiveRecord::Base)
            object.send("#{object.class.primary_key}".to_sym)
          else
            object
          end

          Thread.current["#{self.to_s.downcase}_#{self.object_id}_stamper"] = object_stamper
        end

        # Retrieves the existing stamper for the current request.
        def stamper
          Thread.current["#{self.to_s.downcase}_#{self.object_id}_stamper"]
        end

        # Sets the stamper back to +nil+ to prepare for the next request.
        def reset_stamper
          Thread.current["#{self.to_s.downcase}_#{self.object_id}_stamper"] = nil
        end
      end
    end
  end
end