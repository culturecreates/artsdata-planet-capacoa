require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../src/reload_wikidata'

NTRIPLES_SOCIAL = <<~NT
  <http://www.wikidata.org/entity/Q4851638> <http://www.wikidata.org/prop/direct/P2002> "balletjorgen" .
  <http://www.wikidata.org/entity/Q4851638> <http://www.wikidata.org/prop/direct/P2003> "balletjorgen" .
NT

class TestSparqlConstruct < Minitest::Test
  def test_returns_graph_with_triples
    stub_request(:get, /query\.wikidata\.org/)
      .to_return(status: 200, body: NTRIPLES_SOCIAL)
    graph = sparql_construct("CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o }")
    assert_equal 2, graph.count
  end

  def test_returns_empty_graph_on_http_error
    stub_request(:get, /query\.wikidata\.org/)
      .to_return(status: 500, body: "error")
    graph = sparql_construct("CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o }")
    assert_equal 0, graph.count
  end

  def test_graph_contains_correct_subject
    stub_request(:get, /query\.wikidata\.org/)
      .to_return(status: 200, body: NTRIPLES_SOCIAL)
    graph = sparql_construct("CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o }")
    subjects = graph.map(&:subject).map(&:to_s).uniq
    assert_includes subjects, "http://www.wikidata.org/entity/Q4851638"
  end
end