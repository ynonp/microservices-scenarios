json.extract! contact_info, :id, :name, :email, :phone, :created_at, :updated_at
json.url contact_info_url(contact_info, format: :json)
