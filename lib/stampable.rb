module Ddb #:nodoc:
  module Userstamp

    mattr_accessor :stamper_klass
    @@stamper_klass = defined?(User) ? User : nil

    # Extends the stamping functionality of ActiveRecord by automatically recording the model
    # responsible for creating, updating, and deleting the current object. See the Stamper
    # and Userstamp modules for further documentation on how the entire process works.
    module Stampable
      def self.included(base) #:nodoc:
        super

        base.extend(ClassMethods)
        base.class_eval do
          include InstanceMethods

          # Should ActiveRecord record userstamps? Defaults to true.
          class_attribute  :record_userstamp
          self.record_userstamp = true

          # What column should be used for the creator stamp?
          class_attribute  :creator_attribute

          # What column should be used for the updater stamp?
          class_attribute  :updater_attribute

          # What column should be used for the deleter stamp?
          class_attribute  :deleter_attribute
          
          #you can change your link method
          # default 'belongs_to' 
          class_attribute  :link_method

          self.stampable
        end
      end

      module ClassMethods
        # This method is automatically called on for all classes that inherit from
        # ActiveRecord, but if you need to customize how the plug-in functions, this is the
        # method to use. Here's an example:
        #
        #   class Post < ActiveRecord::Base
        #     stampable :creator_attribute  => :create_user,
        #               :updater_attribute  => :update_user,
        #               :deleter_attribute  => :delete_user
        #   end
        #
        # The method will automatically setup all the associations, and create <tt>before_save</tt>
        # and <tt>before_create</tt> filters for doing the stamping.
        def stampable(options = {})

          defaults  = {
                        :link_method => :belongs_to,
                        :creator_attribute  => :creator_id,
                        :updater_attribute  => :updater_id,
                        :deleter_attribute  => :deleter_id
                      }.merge(options)

          self.creator_attribute  = defaults[:creator_attribute].to_sym
          self.updater_attribute  = defaults[:updater_attribute].to_sym
          self.deleter_attribute  = defaults[:deleter_attribute].to_sym
          self.link_method = defaults[:link_method].to_sym

          class_eval do
             send(self.link_method, :creator, :class_name => Ddb::Userstamp.stamper_klass.to_s,
                                 :foreign_key => self.creator_attribute)

             send(self.link_method, :updater, :class_name => Ddb::Userstamp.stamper_klass.to_s,
                                 :foreign_key => self.updater_attribute)
                                 
            before_validation :set_updater_attribute
            before_validation :set_creator_attribute, :on => :create
                                 
            if defined?(Caboose::Acts::Paranoid) or defined?(Paranoia)
              belongs_to :deleter, :class_name => Ddb::Userstamp.stamper_klass.to_s,
                                   :foreign_key => self.deleter_attribute
              before_destroy  :set_deleter_attribute
            end
          end
        end

        # Temporarily allows you to turn stamping off. For example:
        #
        #   Post.without_stamps do
        #     post = Post.find(params[:id])
        #     post.update_attributes(params[:post])
        #     post.save
        #   end
        def without_stamps
          original_value = self.record_userstamp
          self.record_userstamp = false
          yield
        ensure
          self.record_userstamp = original_value
        end

      end

      module InstanceMethods #:nodoc:
        private

          def set_creator_attribute
            return unless self.record_userstamp
            if respond_to?(self.creator_attribute.to_sym)
              self.send("#{self.creator_attribute}=".to_sym, Ddb::Userstamp.stamper_klass.stamper)
            end
          end

          def set_updater_attribute
            raise "You must define the Stamper Class. Use 'Ddb::Userstamp.stamper_klass = <class>'" unless Ddb::Userstamp.stamper_klass

            return unless self.record_userstamp
            if respond_to?(self.updater_attribute.to_sym)
              self.send("#{self.updater_attribute}=".to_sym, Ddb::Userstamp.stamper_klass.stamper)
            end
          end

          def set_deleter_attribute
            return unless self.record_userstamp
            if respond_to?(self.deleter_attribute.to_sym)
              self.send("#{self.deleter_attribute}=".to_sym, Ddb::Userstamp.stamper_klass.stamper)
              save unless defined?(Paranoia) # don't save now with Paranoia
            end
          end
        #end private
      end
    end
  end
end
