class MemoryLeakJob < ApplicationJob
  queue_as :default
  
  BATCH_SIZE = 1000
 
  def perform
    Blog.find_in_batches(BATCH_SIZE: 1000) do |blogs|
      blogs.each do |blog|
        validate_and_process(blog)
      end
    end
  end

  private

  def validate_and_process(blog)
    if blog_valid?(blog)
      ProcessBlogApiJob.perform_later(blog.id)
    else
      Rails.logger.info "Invalid blog: #{blog.id}"
    end
  end

  def blog_valid?(blog)
    blog.title.present? && blog.body.present?
  end
end