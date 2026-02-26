require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../src/reload_wikidata'

class TestFetchMembers < Minitest::Test
  def test_returns_wikidata_ids
    stub_request(:get, /db\.artsdata\.ca/)
      .to_return(status: 200, body: JSON.generate({
        "results" => {
          "bindings" => [
            { "wikidata_id" => { "value" => "Q4851638" } },
            { "wikidata_id" => { "value" => "Q112570688" } }
          ]
        }
      }))
    ids = fetch_members
    assert_equal ["Q4851638", "Q112570688"], ids
  end

  def test_filters_out_non_wikidata_ids
    stub_request(:get, /db\.artsdata\.ca/)
      .to_return(status: 200, body: JSON.generate({
        "results" => {
          "bindings" => [
            { "wikidata_id" => { "value" => "Q4851638" } },
            { "wikidata_id" => { "value" => "not-a-qid" } }
          ]
        }
      }))
    ids = fetch_members
    assert_equal ["Q4851638"], ids
  end

  def test_returns_unique_ids
    stub_request(:get, /db\.artsdata\.ca/)
      .to_return(status: 200, body: JSON.generate({
        "results" => {
          "bindings" => [
            { "wikidata_id" => { "value" => "Q4851638" } },
            { "wikidata_id" => { "value" => "Q4851638" } }
          ]
        }
      }))
    ids = fetch_members
    assert_equal 1, ids.size
  end
end