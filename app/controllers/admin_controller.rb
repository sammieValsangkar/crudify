# admin controller
class AdminController < ApplicationController
  # include Pundit
  # add_flash_types :success, :warning, :danger, :info
  # respond_to :html, :xml, :json
  # layout 'admin'

  # # before_action :authenticate_user!, :can_access?
  # before_action :authenticate_user!, :load_notifications, :prepare_exception_notifier
  # before_action :strip_ransack_params

  # before_action :set_current_user


  def csv_format(format, result)
    return unless result.present?
    if result.is_a?(Hash) && result.has_key?(:result)
      result = result[:result]
    end
    format.csv do
      respond_csv(result.first.keys.map(&:to_s), result) if result.present?
    end
  end

  def respond_csv(headers, data)
    exported_csv = ExportService.new(headers, data).to_csv
    send_data exported_csv
  end

  def decorated_collection(custom_search)
    custom_search.result(distinct: true)
                 .page(params[:page] || CURRENT_PAGE)
                 .per(params[:per_page] || PER_PAGE)
  end

  def generate_collection_for(model_name)
    params[:q] ||= {}
    params[:q][:s] ||= 'id desc'
    @search = model_name.constantize.ransack(params[:q])
    decorated_collection(@search)
  end

  def generate_collection(instance_name)
    params[:q] ||= {}
    params[:q][:s] ||= 'id desc'
    @search = instance_name.ransack(params[:q])
    decorated_collection(@search)
  end


  def decorate(active_record)
    ActiveDecorator::Decorator.instance.decorate active_record
  end

  def respond_with_partial(partial_name)
    html = render_to_string(partial_name, layout: false, visa_enquiry: @visa_enquiry)
    respond_to do |format|
      format.json { render json: { html: html } }
    end
  end

  private

  def prepare_exception_notifier
    request.env['exception_notifier.exception_data'] = {
      current_user: current_user.inspect
    }
  end
end
