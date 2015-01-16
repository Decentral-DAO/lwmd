class MembersController < ApplicationController
  before_action :authenticate_member!
  before_action :check_for_admin!,
    except: [:show, :edit, :update]
  before_action ->(member=params[:id]) { check_for_admin_or_current_member! member },
    only: %w{show edit update}

  def index
    @members = Member.includes(:address).order('last_name')
  end

  def new
    @member = Member.new
    @address = @member.build_address
  end

  def create
    @member = Member.new(member_params)
    @member.password = 'default_password'
    if @member.save
      @member.invite!(current_member)
      flash[:notice] = "Member added successfully"
      redirect_to members_path
    else
      render "new"
    end
  end

  def show
    @member = Member.find(params[:id])
  end

  def edit
    @member = Member.find(params[:id])
    if @member.address.present?
      @address = @member.address
    else
      @member.build_address
    end
  end

  def update
    @member = Member.find(params[:id])
    if params[:member][:password].blank?
      params[:member].delete(:password)
      params[:member].delete(:password_confirmation)
    end
    if @member.update(member_params)
      flash[:notice] = "Member updated successfully"
      redirect_to members_path
    else
      render "edit"
    end
  end

  def invite
    @member = Member.find(params[:id])
    @member.invite!(current_member)
    flash[:notice] = "Successfully invited #{@member.name}"
    redirect_to memberships_path #since it's called from memberships
  end

  private
    def member_params
      params.require(:member)
            .permit(:first_name,
                    :last_name,
                    :avatar,
                    :email,
                    :birthdate,
                    :gender,
                    :active,
                    :usat_number,
                    :cell_phone,
                    :home_phone,
                    :notes,
                    {address_attributes: [:full_address, :id]})
    end
end
