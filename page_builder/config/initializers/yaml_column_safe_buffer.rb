# Spree.t returns ActiveSupport::SafeBuffer, which Psych.safe_dump rejects when
# storing translated defaults in serialized preference columns.
if defined?(ActiveSupport::SafeBuffer)
  ActiveSupport::SafeBuffer.class_eval do
    unless method_defined?(:encode_with)
      def encode_with(coder)
        coder.represent_scalar(nil, to_s)
      end
    end
  end
end

Rails.application.config.after_initialize do
  permitted_classes = ActiveRecord.yaml_column_permitted_classes
  next if permitted_classes.include?(ActiveSupport::SafeBuffer)

  ActiveRecord.yaml_column_permitted_classes = permitted_classes + [ActiveSupport::SafeBuffer]
end
