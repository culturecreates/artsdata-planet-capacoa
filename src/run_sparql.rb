require 'linkeddata'
require 'sparql'


graph = RDF::Graph.load("ontorefine-output.ttl")
file = File.read("capacoa-infer-presenter-type.sparql")
graph.query(SPARQL.parse(file, update: true))
prefixes = {
  schema:   RDF::Vocabulary.new("http://schema.org/"),
  skos:     RDF::Vocabulary.new("http://www.w3.org/2004/02/skos/core#"),
  capacoa:  RDF::Vocabulary.new("http://capacoa.ca/vocabulary#"),
  member:  RDF::Vocabulary.new("http://capacoa.ca/member/"),
  wikidata_property: RDF::Vocabulary.new("http://www.wikidata.org/prop/direct"),
  wikidata_entity: RDF::Vocabulary.new("http://www.wikidata.org/entity/"),
  ebu_core: RDF::Vocabulary.new("http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#"),
}
output_dir = "output"
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
output_file = File.join(output_dir, "data.ttl")
File.open(output_file, "w") do |f|
  f.write(graph.dump(:ttl, prefixes: prefixes))
end

puts("File saved to #{output_file}")