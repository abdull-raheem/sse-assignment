class ProcessBlogApiJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(blog_id)
    blog = Blog.find_by(id: blog_id)
    
    # If blog is found and rate limit allows, process the blog
    if blog && can_make_api_call?
      blog_to_api(blog)
    else
      # Retry if rate limit is hit or blog is not found
      retry_job_later(blog)
    end
  end

  private

  def blog_to_api(blog)
    # Mock API call - can be replaced with real HTTP call
    sleep(0.1)
  
    api_response_id = generate_api_response_id(blog)
  
    begin
      blog.api_responses.create!(
        api_response_id: api_response_id, 
        api_status: ApiResponse.api_statuses.keys.sample
      )
    rescue ActiveRecord::RecordInvalid => e
      log_error(blog, e)
      retry_job_later(blog)
    rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout => e
      log_error(blog, "Timeout error: #{e.message}")
      retry_job_later(blog)
    rescue StandardError => e
      log_error(blog, e)
      retry_job_later(blog)
    end
  end

  def generate_api_response_id(blog)
    temp_id = 'blog-id'
    temp_id.gsub("id", "#{SecureRandom.hex}-#{blog.id}")
  end

  # Rate limiting logic: This assumes the use of Redis for tracking API calls
  def can_make_api_call?
    current_time = Time.now.to_i
    redis_key = "api_call_timestamp"
    
    last_call_timestamp = Redis.current.get(redis_key).to_i
    if last_call_timestamp == 0 || current_time - last_call_timestamp >= 60
      Redis.current.set(redis_key, current_time)
      true
    else
      false
    end
  end

  # Log errors for debugging purposes
  def log_error(blog, error)
    Rails.logger.error("Error processing blog #{blog.id}: #{error.message}")
  end

  # Consolidated retry logic
  def retry_job_later(blog)
    ProcessBlogApiJob.set(wait: 10.seconds).perform_later(blog.id)
  end
end