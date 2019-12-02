json.array!(@links) do |link|
  json.extract! link, :id, :address, :site_id
  json.url link_url(link, format: :json)
end
