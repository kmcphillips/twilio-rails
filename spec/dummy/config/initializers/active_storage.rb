::Twilio::Rails::Engine.config.to_prepare do
  ActiveStorage::Attachment.skip_callback(:commit, :after, :analyze_blob_later)
end
