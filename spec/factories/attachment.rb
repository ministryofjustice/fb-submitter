FactoryBot.define do
  factory :attachment do
    type { 'output' }
    filename { SecureRandom.alphanumeric }
    url { "example.com/#{filename}" }
    mimetype { 'image/jpeg' }
    path {}
    size {}

    initialize_with { new(filename: filename, mimetype: mimetype) }
  end
end
