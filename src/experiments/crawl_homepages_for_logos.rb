require 'linkeddata'
$VERBOSE = nil

# This script get URLs for CAPACOA members from the Artsdata graph
# and then crawls each URL to find images to use as logos of the members.

require 'rdf'
require 'rdf/vocab'
require 'rdf/sparql'
require 'cgi'

# Ensure that the RDF gem is loaded
RDF::Vocabulary.load!

# Helper method to parse SPARQL queries
def parse_sparql(query)
  SPARQL.parse(query)
end

# Helper method to silence output
def silence_output
  original_stdout = $stdout
  original_stderr = $stderr
  $stdout = $stderr = File.new('/dev/null', 'w')
  yield
ensure
  $stdout = original_stdout
  $stderr = original_stderr
end

graph_uri = 'http://kg.artsdata.ca/culture-creates/artsdata-planet-capacoa/capacoa-members'
g = RDF::Graph.load("http://db.artsdata.ca/repositories/artsdata/rdf-graphs/service?graph=#{CGI.escape(graph_uri)}")
urls = g.query([nil, RDF::Vocab::SCHEMA.url, nil]).objects 
puts urls
urls.each do |url|
  begin
    site = RDF::Graph.new
    silence_output do
      site = RDF::Graph.load(url.to_s)
    end
    query = SPARQL.parse("select * where { ?s a <http://schema.org/LocalBusiness> ; <http://schema.org/image> ?image . ?image <http://schema.org/url> ?imageUrl . }")
    query.execute(site) do |solution|
      puts "At #{url} found image: #{solution[:imageUrl]}"
    end
  rescue StandardError
    # puts "Error loading #{url}"
  end
end
puts "Crawling complete."

