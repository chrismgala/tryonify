json.shop do
  json.partial! @shop, partial: 'api/v1/shops/shop', as: :shop
end