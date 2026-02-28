module Admin
  class ScriptVersionsController < ApplicationController
    before_action :require_admin
    before_action :set_script_version, only: [ :edit, :update, :destroy ]

    def index
      @script_versions = ScriptVersion.ordered
      @script_version = ScriptVersion.new(released_at: Date.current)
    end

    def new
      @script_version = ScriptVersion.new(released_at: Date.current)
    end

    def create
      @script_version = ScriptVersion.new(script_version_params)
      assign_script_file

      if @script_version.save
        redirect_to admin_script_versions_path, notice: "Script version #{@script_version.version} created."
      else
        @script_versions = ScriptVersion.ordered
        render :index, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @script_version.assign_attributes(script_version_params)
      assign_script_file

      if @script_version.save
        redirect_to admin_script_versions_path, notice: "Script version #{@script_version.version} updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      version = @script_version.version
      @script_version.destroy
      redirect_to admin_script_versions_path, notice: "Script version #{version} deleted."
    end

    private

    def set_script_version
      @script_version = ScriptVersion.find(params[:id])
    end

    def script_version_params
      params.require(:script_version).permit(:version, :changelog, :released_at)
    end

    def assign_script_file
      return unless params[:script_version][:script_file].present?

      @script_version.script_content = params[:script_version][:script_file].read.force_encoding("UTF-8")
    end
  end
end
