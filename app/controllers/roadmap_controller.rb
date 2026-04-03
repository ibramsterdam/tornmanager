class RoadmapController < ApplicationController
  allow_unauthenticated_access only: [ :index ]
  before_action :require_admin, except: [ :index ]
  before_action :set_roadmap_item, only: [ :update, :destroy ]

  def index
    resume_session
    @items_by_status = RoadmapItem::STATUSES.index_with do |status|
      RoadmapItem.by_status(status)
    end
    @editing_item = RoadmapItem.find_by(id: params[:edit]) if params[:edit].present?
    @is_admin = Current.user&.admin?
  end

  def create
    @item = RoadmapItem.new(roadmap_item_params)
    @item.position ||= RoadmapItem.where(status: @item.status).maximum(:position).to_i + 1

    if @item.save
      redirect_to roadmap_path, notice: "Roadmap item created."
    else
      redirect_to roadmap_path, alert: @item.errors.full_messages.to_sentence
    end
  end

  def update
    if @item.update(roadmap_item_params)
      redirect_to roadmap_path, notice: "Roadmap item updated."
    else
      redirect_to roadmap_path(edit: @item.id), alert: @item.errors.full_messages.to_sentence
    end
  end

  def destroy
    @item.destroy
    redirect_to roadmap_path, notice: "Roadmap item deleted."
  end

  private

  def set_roadmap_item
    @item = RoadmapItem.find(params[:id])
  end

  def roadmap_item_params
    params.require(:roadmap_item).permit(:title, :description, :status, :category, :position)
  end
end
