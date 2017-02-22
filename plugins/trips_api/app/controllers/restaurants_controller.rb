class RestaurantsController < ApplicationController
  default_search_scope :issues

  before_filter :find_restaurant, :only => [:show]
  before_filter :authorize, :except => [:index, :categories, :show]
  before_filter :find_optional_trip, :only => [:index, :categories]
  accept_api_auth :index, :show, :categories

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :journals
  helper :projects
  helper :custom_fields
  helper :issue_relations
  helper :watchers
  helper :attachments
  helper :queries
  include QueriesHelper
  helper :repositories
  helper :sort
  include SortHelper
  helper :timelog

  def index
    retrieve_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      @offset, @limit = api_offset_and_limit
      @query.column_names = %w(author)

      cond = " issues.category_id = #{params['category_id']}"

      @issue_count = @query.issue_count
      @issue_pages = Paginator.new @issue_count, @limit, params['page']
      @offset ||= @issue_pages.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :conditions => cond,
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @issue_count_by_group = @query.issue_count_by_group

      respond_to do |format|
        format.api {
          Issue.load_visible_relations(@issues) #if include_in_api_response?('relations')
        }
      end
    else
      respond_to do |format|
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def categories
    @offset = 0
    @limit = 10
    @restaurants = Hash.new
    @categories = @project.issue_categories.all
    @categories.each do |category|
      cond = " issues.project_id = #{@project.id}"
      cond << " AND issues.category_id = #{category.id}"
      # Give it a name, required to be valid
      @query = IssueQuery.new(:name => "_")
      @query.project = @project
      @issues = @query.issues(:include => [:tracker, :priority, :category],
                              :conditions => cond,
                              :offset => @offset,
                              :limit => @limit)

      @restaurants[category] = @issues if @issues.any?
    end

    respond_to do |format|
      format.api
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find the issue whose id is the :id parameter
  # Raises a Unauthorized exception if the issue is not visible
  def find_restaurant
    # Issue.visible.find(...) can not be used to redirect user to the login form
    # if the issue actually exists but requires authentication
    @issue = Issue.find(params[:id])
    raise Unauthorized unless @issue.visible?
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find a project based on params[:project_id]
  # TODO: some subclasses override this, see about merging their logic
  def find_optional_trip
    @project = Project.find(params[:trip_id]) unless params[:trip_id].blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end