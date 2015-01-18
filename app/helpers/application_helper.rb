module ApplicationHelper

  def resource_name
    :member
  end

  def resource
    @resource ||= Member.new
  end

  def resource_class
    devise_mapping.to
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:member]
  end

  def flash_class(level)
    case level
      when "success" then "ui green message"
      when "error" then "ui red message"
      else "ui blue message"
    end
  end

  def title(page_title)
    content_for(:title) { page_title }
  end
end
