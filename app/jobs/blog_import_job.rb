require 'csv'

class BlogImportJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 1000

  def perform(file_path, user_id)
    user = User.find_by(id: user_id)

    raise 'File or user not found' unless user || File.exist?(file_path)

    data = CSV.foreach(file_path, headers: true, encoding: 'utf8')
    blogs = []

    data.each_with_index do |row, index|
      begin
        blogs << row.to_h.merge(user_id: user.id)

        if blogs.size >= BATCH_SIZE || data.eof?
          Blog.insert_all!(blogs) # Bulk insert
          blogs.clear # Clear the array after batch insert
        end
      rescue => e
        Rails.logger.error "Failed to process row #{index + 1}: #{e.message}"
      end
    end
  rescue => e
    Rails.logger.error "Blog Import Error for user #{user_id}: #{e.message}"
  ensure
    File.delete(file_path) if File.exist?(file_path) # Cleanup temporary file
  end
end
