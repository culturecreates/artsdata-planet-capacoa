require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../src/reload_wikidata'

NTRIPLES_BATCH = <<~NT
  <http://www.wikidata.org/entity/Q4851638> <http://www.wikidata.org/prop/direct/P2002> "balletjorgen" .
NT

class TestConstructBatched < Minitest::Test
  
  # Override sleep to no-op for faster tests
  def sleep(*)
  end

  def test_merges_results_from_all_batches
    stub_request(:get, /query\.wikidata\.org/)
      .to_return(status: 200, body: NTRIPLES_BATCH)
    ids   = ["Q1", "Q2", "Q3"]
    graph = construct_batched("CONSTRUCT { ?s ?p ?o } WHERE { VALUES ?s { {{wikidata_ids}} } }", ids)
    assert graph.count > 0
  end

  def test_makes_one_call_per_batch
    call_count = 0
    stub_request(:get, /query\.wikidata\.org/).to_return do
      call_count += 1
      { status: 200, body: NTRIPLES_BATCH }
    end
    # 3 IDs with BATCH_SIZE=50 should be 1 batch
    construct_batched("CONSTRUCT { ?s ?p ?o } WHERE { VALUES ?s { {{wikidata_ids}} } }", ["Q1", "Q2", "Q3"])
    assert_equal 1, call_count
  end

  def test_makes_multiple_calls_for_large_input
    call_count = 0
    stub_request(:get, /query\.wikidata\.org/).to_return do
      call_count += 1
      { status: 200, body: NTRIPLES_BATCH }
    end
    # 51 IDs with BATCH_SIZE=50 should be 2 batches
    ids = (1..51).map { |i| "Q#{i}" }
    construct_batched("CONSTRUCT { ?s ?p ?o } WHERE { VALUES ?s { {{wikidata_ids}} } }", ids)
    assert_equal 2, call_count
  end

  def test_substitutes_wikidata_ids_in_template
    captured_query = nil
    stub_request(:get, /query\.wikidata\.org/).to_return do |req|
      captured_query = URI.decode_www_form(URI(req.uri).query).to_h["query"]
      { status: 200, body: NTRIPLES_BATCH }
    end
    construct_batched("VALUES ?s { <WIKIDATA_IDS_PLACEHOLDER> }", ["Q4851638"])
    assert_includes captured_query, "<http://www.wikidata.org/entity/Q4851638>"
  end
end