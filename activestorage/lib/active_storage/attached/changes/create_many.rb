# frozen_string_literal: true

module ActiveStorage
  class Attached::Changes::CreateMany #:nodoc:

    attr_reader :name, :record, :attachables, :for_upload

    def initialize(name, record, attachables, for_upload = nil)
      @name, @record, @attachables, @for_upload = name, record, Array(attachables), Array(for_upload)
      blobs.each(&:identify_without_saving)
      attachments
    end

    def attachments
      @attachments ||= subchanges.collect(&:attachment)
    end

    def blobs
      @blobs ||= subchanges.collect(&:blob)
    end

    def upload
      for_upload.each(&:upload)
    end

    def save
      assign_associated_attachments
      reset_associated_blobs
    end

    private
      def subchanges
        @subchanges ||= attachables.collect { |attachable| build_subchange_from(attachable) }.tap do |subs|
          @for_upload += subs.reject { |sub| sub.attachable.is_a?(ActiveStorage::Blob) }
        end
      end

      def build_subchange_from(attachable)
        ActiveStorage::Attached::Changes::CreateOneOfMany.new(name, record, attachable)
      end

      def assign_associated_attachments
        record.public_send("#{name}_attachments=", persisted_or_new_attachments)
      end

      def reset_associated_blobs
        record.public_send("#{name}_blobs").reset
      end

      def persisted_or_new_attachments
        attachments.select { |attachment| attachment.persisted? || attachment.new_record? }
      end
  end
end
