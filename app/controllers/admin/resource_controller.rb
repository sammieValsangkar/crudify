class Admin::ResourceController < AdminController
  include ::Resources::Callbacks

  helper_method :new_object_url, :edit_object_url, :object_url, :collection_url
  before_action :load_resource, except: :update_positions
  rescue_from ActiveRecord::RecordNotFound, :with => :resource_not_found

  respond_to :html

  def new
    invoke_callbacks(:new_action, :before)
    respond_with(@object) do |format|
      format.html do
        render :layout => !request.xhr?
      end
      if request.xhr?
        format.js   { render :layout => false }
      end
    end
  end

  def index
    @collection = generate_collection_for(model_class.name)
    @klass = model_class
  end

  def edit
    respond_with(@object) do |format|
      format.html { render :layout => !request.xhr? }
      if request.xhr?
        format.js   { render :layout => false }
      end
    end
  end

  def show
    respond_with(@object) do |format|
      format.html do
        render :layout => !request.xhr?
      end
      if request.xhr?
        format.js   { render :layout => false }
      end
    end
  end

  def update
    invoke_callbacks(:update, :before)
    if @object.update_attributes(permitted_resource_params)
      invoke_callbacks(:update, :after)
      flash[:success] = flash_message_for(@object, :successfully_updated)
      respond_with(@object) do |format|
        format.html { redirect_to location_after_save }
        format.js   { render :layout => false }
      end
    else
      invoke_callbacks(:update, :fails)
      respond_with(@object) do |format|
        format.html do
          flash.now[:error] = @object.errors.full_messages.join(", ")
          render action: 'edit'
        end
        format.js { render layout: false }
      end
    end
  end

  def create
    invoke_callbacks(:create, :before)
    @object.attributes = permitted_resource_params
    if @object.save
      invoke_callbacks(:create, :after)
      flash[:success] = flash_message_for(@object, :successfully_created)
      respond_with(@object) do |format|
        format.html { redirect_to location_after_save }
        format.js   { render :layout => false }
      end
    else
      invoke_callbacks(:create, :fails)
      respond_with(@object) do |format|
        format.html do
          flash.now[:error] = @object.errors.full_messages.join(", ")
          render action: 'new'
        end
        format.js { render layout: false }
      end
    end
  end

  def update_positions
    ActiveRecord::Base.transaction do
      params[:positions].each do |id, index|
        model_class.find(id).set_list_position(index)
      end
    end

    respond_to do |format|
      format.js  { render text: 'Ok' }
    end
  end

  def destroy
    invoke_callbacks(:destroy, :before)
    if @object.destroy
      invoke_callbacks(:destroy, :after)
      flash[:success] = flash_message_for(@object, :successfully_removed)
      respond_with(@object) do |format|
        format.html { redirect_to location_after_destroy }
        format.js   { render :partial => "admin/shared/destroy" }
      end
    else
      invoke_callbacks(:destroy, :fails)
      respond_with(@object) do |format|
        format.html { redirect_to location_after_destroy }
      end
    end
  end

  protected

    class << self
      attr_accessor :parent_data

      def belongs_to(model_name, options = {})
        @parent_data ||= {}
        @parent_data[:model_name] = model_name
        @parent_data[:model_class] = model_name.to_s.classify.constantize
        @parent_data[:find_by] = options[:find_by] || :id
      end
    end

    def resource_not_found
      flash[:error] = flash_message_for(model_class.new, :not_found)
      redirect_to collection_url
    end

    def log_details
      p model_class
      p model_name
      p object_name
      p action
    end

    def model_class
      "#{controller_name_with_namespace.singularize.classify}".constantize
    end

    def model_name
      controller_name_with_namespace.classify
    end

    def object_name
      # controller_name_with_namespace.gsub('/', '_').singularize
      model_class.table_name.singularize
    end

    def action
      action_name
    end

    def controller_name_with_namespace
      # params[:controller].gsub('admin/', '')
      # TODO getting controller name from url
      case action
      when 'new'
        request.fullpath.gsub('admin/', '').gsub("/#{action}", '')
      when 'show'
        request.fullpath.gsub('admin/', '').split('/').reverse.drop(1).reverse.join('/')
      when 'update'
        request.fullpath.gsub('admin/', '').split('/').reverse.drop(1).reverse.join('/')
      when 'destroy'
        request.fullpath.gsub('admin/', '').split('/').reverse.drop(1).reverse.join('/')
      when 'edit'
        request.fullpath.gsub('admin/', '').gsub("/#{action}", '').split('/').reverse.drop(1).reverse.join('/')
      else
        request.fullpath.gsub('admin/', '').gsub("/#{action}", '')
      end

    end

    def load_resource
      if member_action?
        @object ||= load_resource_instance

        # call authorize! a third time (called twice already in Admin::BaseController)
        # this time we pass the actual instance so fine-grained abilities can control
        # access to individual records, not just entire models.

        # we are not handling access management
        # authorize! action, @object rescue 'true'
        instance_variable_set("@#{object_name}", @object)
      else
        @collection ||= collection

        # note: we don't call authorize here as the collection method should use
        # CanCan's accessible_by method to restrict the actual records returned

        instance_variable_set("@#{controller_name}", @collection)
      end
    end

    def generate_collection_for(model_name)
      params[:q] ||= {}
      params[:q][:s] ||= 'id desc'
      includers = model_name.constantize.reflect_on_all_associations(:belongs_to)
                            .map(&:name).map(&:to_sym)
      @search = model_name.constantize.includes(includers).ransack(params[:q])
      decorated_collection(@search)
    end

    def decorated_collection(custom_search)
      custom_search.result(distinct: true)
                 .page(params[:page] || current_page)
                 .per(params[:per_page] || per_page)
    end

    def current_page
      Object.const_defined?('CURRENT_PAGE') ? CURRENT_PAGE : 1
    end

    def per_page
      Object.const_defined?('PER_PAGE') ? PER_PAGE : 10
    end

    def load_resource_instance
      if new_actions.include?(action)
        build_resource
      elsif params[:id]
        find_resource
      end
    end

    def parent_data
      p self.class
      self.class.parent_data
    end

    def parent
      if parent_data.present?
        @parent ||= parent_data[:model_class].send("find_by_#{parent_data[:find_by]}", params["#{model_name}_id"])
        instance_variable_set("@#{model_name}", @parent)
      else
        nil
      end
    end

    def find_resource
      if parent_data.present?
        parent.send(controller_name).find(params[:id])
      else
        model_class.find(params[:id])
      end
    end

    def build_resource
      if parent_data.present?
        parent.send(controller_name).build
      else
        model_class.new
      end
    end

    def flash_message_for(object, event_sym)
        resource_desc  = object.class.model_name.human
        resource_desc += " \"#{object.name}\"" if object.respond_to?(:name) && object.name.present?
        t(event_sym, resource: resource_desc)
      end

    def collection
      return parent.send(controller_name) if parent_data.present?
      if model_class.respond_to?(:accessible_by) && !current_ability.has_block?(params[:action], model_class)
        model_class.accessible_by(current_ability, action)
      else
        model_class.where(nil)
      end
    end

    def location_after_destroy
      collection_url
    end

    def location_after_save
      collection_url
    end

    # URL helpers

    def new_object_url(options = {})
      if parent_data.present?
        new_polymorphic_url([:admin, parent, model_class], options)
      else
        new_polymorphic_url([:admin, model_class], options)
      end
    end

    def edit_object_url(object, options = {})
      if parent_data.present?
        send "edit_admin_#{model_name}_#{object_name}_url", parent, object, options
      else
        send "edit_admin_#{object_name}_url", object, options
      end
    end

    def object_url(object = nil, options = {})
      target = object ? object : @object
      if parent_data.present?
        send "admin_#{model_name}_#{object_name}_url", parent, target, options
      else
        send "admin_#{object_name}_url", target, options
      end
    end

    def collection_url(options = {})
      if parent_data.present?
        polymorphic_url([:admin, parent, model_class], options)
      else
        polymorphic_url([:admin, model_class], options)
      end
    end

    # Allow all attributes to be updatable.
    #
    # Other controllers can, should, override it to set custom logic
    def permitted_resource_params
      p params[object_name].present? ? params.require(object_name).permit! : ActionController::Parameters.new
    end

    def collection_actions
      ['index']
    end

    def member_action?
      !collection_actions.include? action
    end

    def new_actions
      ['new', 'create']
    end
end
