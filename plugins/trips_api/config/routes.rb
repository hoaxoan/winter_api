resources :trips do
end

resources :landmarks do
end

resources :restaurants do
  collection do
    get 'categories'
  end
end

resources :searchs do
  collection do
    get 'suggests'
  end
end