class RegistrationsController < ApplicationController

  def new
    redirect_to closed_registration_path unless FeatureToggler.registration_active?
    registration_attributes = { contact_email: current_user.try(:email) }.merge(registration_params)
    @registration = Registration.new(registration_attributes)
  end

  def create
    if simple_registration?
      password = SecureRandom.hex
      @registration = Registration.new(registration_params)
      @user = @registration.build_user(email: registration_params[:email], password: password, password_confirmation: password)
    else
      @registration = current_user.registrations.build(registration_params)
    end
    if @registration.save
      redirect_to confirm_registration_path
    else
      respond_with @registration
    end
  end

  private

  def registration_params
    params.require(:registration).permit(:contact_email,
                                         :year,
                                         :zip,
                                         :company,
                                         :gender,
                                         :primary_role,
                                         :track_id)
  end

end
