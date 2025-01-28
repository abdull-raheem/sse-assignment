require 'csv'
class BlogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_blog, only: %i[ show edit update destroy ]

  # GET /blogs or /blogs.json
  def index
    # @blogs = current_user.blogs
    @pagy, @blogs = pagy(current_user.blogs)

  end

  # GET /blogs/1 or /blogs/1.json
  def show
  end

  # GET /blogs/new
  def new
    @blog = current_user.blogs.new
  end

  # GET /blogs/1/edit
  def edit
  end

  # POST /blogs or /blogs.json
  def create
    @blog = current_user.blogs.new(blog_params)

    respond_to do |format|
      if @blog.save
        format.html { redirect_to blog_url(@blog), notice: "Blog was successfully created." }
        format.json { render :show, status: :created, location: @blog }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /blogs/1 or /blogs/1.json
  def update
    respond_to do |format|
      if @blog.update(blog_params)
        format.html { redirect_to blog_url(@blog), notice: "Blog was successfully updated." }
        format.json { render :show, status: :ok, location: @blog }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /blogs/1 or /blogs/1.json
  def destroy
    @blog.destroy

    respond_to do |format|
      format.html { redirect_to blogs_url, notice: "Blog was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def import
    file = params[:attachment]
  
    unless file.present?
      redirect_to blogs_path, alert: 'No file attached'
      return
    end
  
    # Use Tempfile safely and enqueue the job
    begin
      Tempfile.open(['import', '.csv']) do |tempfile|
        tempfile.binmode
        tempfile.write(file.read)
        tempfile.flush
  
        # Enqueue the background job with the temporary file path
        BlogImportJob.perform_later(tempfile.path, current_user.id)
      end
  
      redirect_to blogs_path, notice: 'Blogs are being imported. You will be notified once completed.'
    rescue => e
      Rails.logger.error "Blog Import Error: #{e.message}\n#{e.backtrace.join("\n")}"
      redirect_to blogs_path, alert: "Failed to import blogs: #{e.message}"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_blog
      @blog = current_user.blogs.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def blog_params
      params.require(:blog).permit(:title, :body, :user_id)
    end
end
