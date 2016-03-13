require "application_responder"

class ApplicationController < ActionController::Base

  before_action :configure_permitted_parameters, if: :devise_controller?

  self.responder = ApplicationResponder
  respond_to :html

  helper_method :registered?
  helper_method :current_user
  helper_method :current_registration
  helper_method :current_body_class
  helper_method :in_mercury_invasion?
  helper_method :simple_registration?

  layout(lambda do |c|
    if c.respond_to?(:current_page) && c.template_exists?(c.current_page.template, 'layouts')
      c.current_page.template
    else
      'application'
    end
  end)

  protect_from_forgery with: :exception

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,
      keys: [:email, :remember_me, :uid, :provider, :name, :description])
  end

  def registered?
    current_registration.present?
  end

  def ensure_linkedin_and_admin!
    redirect_to main_app.new_user_session_path unless current_user && current_user.is_admin?
  end

  def in_mercury_invasion?
    params[:mercury_frame] && (params[:mercury_frame] == true || params[:mercury_frame] == 'true')
  end

  def current_registration
    current_user && current_user.current_registration
  end

  def simple_registration?
    cookies.signed[:simple_registration] == true
  end

  def current_body_class
    if respond_to?(:current_page)
      current_page.try(:template)
    else
      controller_name
    end
  end

  def user_for_paper_trail
    current_user || 'Unknown user'
  end

  def after_sign_in_path_for(user)
    if user.registered?
      main_app.schedules_path
    elsif FeatureToggler.registration_active?
      main_app.register_path
    elsif FeatureToggler.submission_active?
      main_app.new_submission_path
    elsif FeatureToggler.feedback_active?
      main_app.submissions_path
    elsif user.is_admin?
      main_app.admin_root_path
    else
      main_app.cmsimple_path
    end
  end

end
