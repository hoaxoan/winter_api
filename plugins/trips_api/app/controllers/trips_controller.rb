class TripsController < ApplicationController

  before_filter :find_trip, :except => [:index]
  before_filter :authorize, :except => [:index, :show]
  accept_api_auth :index, :show

  helper :custom_fields
  helper :issues
  helper :queries
  helper :repositories
  helper :members
  helper :attachments

  # Lists visible projects
  def index
    scope = Project.visible

    respond_to do |format|
      format.api {
        @offset, @limit = api_offset_and_limit
        @trip_count = scope.count
        @trips = scope.offset(@offset).limit(@limit).to_a
      }
    end
  end


  # Show @project
  def show
    @trackers = @trip.rolled_up_trackers.visible

    respond_to do |format|
      format.api
    end
  end

  # Find project of id params[:id]
  def find_trip
    @trip = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
