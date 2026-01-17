require 'net/http'
require 'json'
require 'uri'

BASE_URL = "https://capacoa.ca/wp-json/wp/v2/users"
PER_PAGE = 100
offset = 0
all_users = []

loop do
  uri = URI(BASE_URL)
  uri.query = URI.encode_www_form({ per_page: PER_PAGE, offset: offset })

  request = Net::HTTP::Get.new(uri)
  request['User-Agent'] = 'artsdata-crawler (compatible; +https://kg.artsdata.ca/doc/artsdata-crawler)'

  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  response = http.request(request)

  unless response.is_a?(Net::HTTPSuccess)
    puts "Error fetching data: #{response.code} message: #{response.message}"
    break
  end

  data = JSON.parse(response.body)

  break if data.empty?

  all_users.concat(data)
  offset += PER_PAGE
  puts "Fetched #{data.length} users, offset now #{offset}"
  sleep(2) # Respectful delay to avoid overwhelming the server
end

File.open("members.json", "w:utf-8") do |file|
  file.write(JSON.pretty_generate(all_users))
end

puts "Saved #{all_users.length} users to members.json"
