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
  request['User-Agent'] = 'artsdata-crawler'

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  unless response.is_a?(Net::HTTPSuccess)
    puts "Error fetching data: #{response.code} message: #{response.message}"
    break
  end

  data = JSON.parse(response.body)

  break if data.empty?

  all_users.concat(data)
  offset += PER_PAGE
  puts "Fetched #{data.length} users, offset now #{offset}"
end

File.open("members.json", "w:utf-8") do |file|
  file.write(JSON.pretty_generate(all_users))
end

puts "Saved #{all_users.length} users to members.json"
