json.array!(@activities) do |activity|
  json.extract! activity, :score, :id, :canvas_user_id, :reason, :delta, :created_at, :updated_at
end
