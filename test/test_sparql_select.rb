require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../src/reload_wikidata'

MEMBERS_RESPONSE = JSON.generate({
  "results" => {
    "bindings" => [
      { "org" => { "value" => "https://capacoa.ca/member/100" }, "wikidata_id" => { "value" => "Q4851638" } },
      { "org" => { "value" => "https://capacoa.ca/member/101" }, "wikidata_id" => { "value" => "Q112570688" } }
    ]
  }
})

class TestSparqlSelect < Minitest::Test
  def test_returns_bindings
    stub_request(:get, /db\.artsdata\.ca/)
      .to_return(status: 200, body: MEMBERS_RESPONSE)
    rows = sparql_select(ARTSDATA_ENDPOINT, "SELECT * WHERE { ?s ?p ?o }")
    assert_equal 2, rows.size
    assert_equal "Q4851638",    rows[0].dig("wikidata_id", "value")
    assert_equal "Q112570688",  rows[1].dig("wikidata_id", "value")
  end

  def test_returns_empty_array_on_http_error
    stub_request(:get, /db\.artsdata\.ca/)
      .to_return(status: 500, body: "error")
    rows = sparql_select(ARTSDATA_ENDPOINT, "SELECT * WHERE { ?s ?p ?o }")
    assert_equal [], rows
  end
end