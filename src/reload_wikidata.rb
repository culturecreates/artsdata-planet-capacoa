require 'net/http'
require 'json'
require 'uri'
require 'rdf'
require 'rdf/turtle'
require 'rdf/ntriples'
require 'json/ld'


ARTSDATA_ENDPOINT = "https://db.artsdata.ca/repositories/artsdata"
WIKIDATA_ENDPOINT = "https://query.wikidata.org/sparql"
WIKIDATA_ENTITY   = "http://www.wikidata.org/entity/"
SCHEMA            = RDF::Vocabulary.new("http://schema.org/")

REPO_ROOT   = File.expand_path("../..", __FILE__)
SPARQL_DIR  = File.join(REPO_ROOT, "sparql", "wikidata")
OUTPUT_FILE = File.join(REPO_ROOT, "output", "capacoa-wikidata.jsonld")

BATCH_SIZE  = 50


def read_sparql(filename)
  path = File.join(SPARQL_DIR, filename)
  raise "SPARQL file not found: #{path}" unless File.exist?(path)
  File.read(path)
end

def http_get(url, accept)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  req["Accept"]     = accept
  req["User-Agent"] = "artsdata-crawler (+https://kg.artsdata.ca)"
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.read_timeout = 120
    res = http.request(req)
    unless res.is_a?(Net::HTTPSuccess)
      puts "  HTTP #{res.code}: #{res.body[0..300]}"
      raise "HTTP #{res.code} #{res.message}"
    end
    res.body
  end
end

def sparql_select(endpoint, query)
  uri = URI(endpoint)
  uri.query = URI.encode_www_form(query: query)
  body = http_get(uri.to_s, "application/sparql-results+json")
  JSON.parse(body)["results"]["bindings"]
rescue => e
  puts "  SPARQL SELECT error: #{e.message}"
  []
end

def sparql_construct(query)
  uri = URI(WIKIDATA_ENDPOINT)
  uri.query = URI.encode_www_form(query: query)
  body = http_get(uri.to_s, "application/n-triples")
  graph = RDF::Graph.new
  RDF::NTriples::Reader.new(body) { |r| r.each_statement { |s| graph << s } }
  graph
rescue => e
  puts "  SPARQL CONSTRUCT error: #{e.message}"
  RDF::Graph.new
end

def construct_batched(sparql_template, wikidata_ids)
  result = RDF::Graph.new
  total  = (wikidata_ids.size.to_f / BATCH_SIZE).ceil
  wikidata_ids.each_slice(BATCH_SIZE).with_index(1) do |batch, i|
    values = batch.map { |id| "<#{WIKIDATA_ENTITY}#{id}>" }.join(" ")
    query  = sparql_template.gsub("{{wikidata_ids}}", values)
    print "    batch #{i}/#{total} ..."
    g = sparql_construct(query)
    puts " #{g.count} triples"
    result << g
    sleep(1)
  end
  result
end


def fetch_members
  rows = sparql_select(ARTSDATA_ENDPOINT, read_sparql("fetch-members.sparql"))
  rows.filter_map { |r| r.dig("wikidata_id", "value") }
      .select { |id| id.match?(/^Q\d+$/) }
      .uniq
end

def fetch_social_media(wikidata_ids)
  construct_batched(read_sparql("fetch-social-media.sparql"), wikidata_ids)
end

def fetch_venues(wikidata_ids)
  construct_batched(read_sparql("fetch-venues.sparql"), wikidata_ids)
end

def replace_images(graph)
  images_to_process = graph.query([nil, SCHEMA.image, nil]).select do |stmt|
    stmt.object.uri? && stmt.object.to_s.include?("Special:FilePath")
  end

  puts "  Found #{images_to_process.size} images to process"

  images_to_process.each do |stmt|
    place_uri = stmt.subject
    filename  = URI.decode_www_form_component(
                  stmt.object.to_s.split("Special:FilePath/").last
                )

    api_url = "https://commons.wikimedia.org/w/api.php?" +
              URI.encode_www_form(
                action:     "query",
                prop:       "imageinfo",
                iiprop:     "url",
                redirects:  "1",
                format:     "json",
                iiurlwidth: 300,
                titles:     "File:#{filename}"
              )

    begin
      body     = http_get(api_url, "application/json")
      thumburl = JSON.parse(body).dig("query", "pages")&.values&.first
                                 &.dig("imageinfo", 0, "thumburl")
      if thumburl
        graph.delete(stmt)
        graph << RDF::Statement(place_uri, SCHEMA.image, RDF::URI(thumburl))
        puts "  OK #{filename[0..60]}"
      else
        puts "  SKIP No thumburl for: #{filename[0..60]}"
      end
    rescue => e
      puts "  ERROR #{filename[0..60]}: #{e.message}"
    end

    sleep(0.5)
  end

  graph
end

def serialize(graph)
  jsonld_data = JSON::LD::API.fromRdf(graph)
  output = {
    "@context" => {
      "schema" => "http://schema.org/",
      "rdfs"   => "http://www.w3.org/2000/01/rdf-schema#",
      "wdt"    => "http://www.wikidata.org/prop/direct/",
      "wd"     => "http://www.wikidata.org/entity/"
    },
    "@graph" => jsonld_data
  }
  Dir.mkdir(File.dirname(OUTPUT_FILE)) unless Dir.exist?(File.dirname(OUTPUT_FILE))
  File.write(OUTPUT_FILE, JSON.pretty_generate(output))
  puts "  Saved #{graph.count} triples -> #{OUTPUT_FILE}"
end


def main
  puts "\n── Step 1: Fetch CAPACOA members from Artsdata ──"
  wikidata_ids = fetch_members
  puts "  Found #{wikidata_ids.size} members with Wikidata IDs"
  raise "No Wikidata IDs found" if wikidata_ids.empty?

  puts "\n── Step 2: Fetch social media from Wikidata ──"
  social_graph = fetch_social_media(wikidata_ids)
  puts "  Total triples: #{social_graph.count}"

  puts "\n── Step 3: Fetch venues from Wikidata ──"
  venues_graph = fetch_venues(wikidata_ids)
  puts "  Total triples: #{venues_graph.count}"

  graph = RDF::Graph.new
  graph << social_graph
  graph << venues_graph
  puts "\n  Combined graph: #{graph.count} triples"

  puts "\n── Step 4: Replace images with Wikimedia thumbnails ──"
  replace_images(graph)

  puts "\n── Step 5: Serialize to JSON-LD ──"
  serialize(graph)

  puts "\nDone"
end

main if __FILE__ == $0