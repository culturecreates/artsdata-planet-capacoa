require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../src/reload_wikidata'

class TestFetchMembers < Minitest::Test
  def test_returns_member_map
    stub_request(:get, /db\.artsdata\.ca/)
      .to_return(status: 200, body: JSON.generate({
        "results" => {
          "bindings" => [
            { "wikidata_id" => { "value" => "Q4851638" },
              "org"         => { "value" => "https://capacoa.ca/member/100" },
              "type"        => { "value" => "http://schema.org/Organization" } },
            { "wikidata_id" => { "value" => "Q112570688" },
              "org"         => { "value" => "https://capacoa.ca/member/101" },
              "type"        => { "value" => "http://schema.org/Organization" } }
          ]
        }
      }))
    map = fetch_members
    assert_equal "https://capacoa.ca/member/100", map["Q4851638"][:uri]
    assert_equal "http://schema.org/Organization", map["Q4851638"][:type]
    assert_equal 2, map.size
  end

  def test_filters_out_non_wikidata_ids
    stub_request(:get, /db\.artsdata\.ca/)
      .to_return(status: 200, body: JSON.generate({
        "results" => {
          "bindings" => [
            { "wikidata_id" => { "value" => "Q4851638" },
              "org"         => { "value" => "https://capacoa.ca/member/100" },
              "type"        => { "value" => "http://schema.org/Organization" } },
            { "wikidata_id" => { "value" => "not-a-qid" },
              "org"         => { "value" => "https://capacoa.ca/member/101" },
              "type"        => { "value" => "http://schema.org/Organization" } }
          ]
        }
      }))
    map = fetch_members
    assert_equal 1, map.size
    assert map.key?("Q4851638")
  end

  def test_returns_unique_ids
    stub_request(:get, /db\.artsdata\.ca/)
      .to_return(status: 200, body: JSON.generate({
        "results" => {
          "bindings" => [
            { "wikidata_id" => { "value" => "Q4851638" },
              "org"         => { "value" => "https://capacoa.ca/member/100" },
              "type"        => { "value" => "http://schema.org/Organization" } },
            { "wikidata_id" => { "value" => "Q4851638" },
              "org"         => { "value" => "https://capacoa.ca/member/100" },
              "type"        => { "value" => "http://schema.org/Organization" } }
          ]
        }
      }))
    map = fetch_members
    assert_equal 1, map.size
  end

  def test_handles_person_type
    stub_request(:get, /db\.artsdata\.ca/)
      .to_return(status: 200, body: JSON.generate({
        "results" => {
          "bindings" => [
            { "wikidata_id" => { "value" => "Q1918953" },
              "org"         => { "value" => "https://capacoa.ca/member/230" },
              "type"        => { "value" => "http://schema.org/Person" } }
          ]
        }
      }))
    map = fetch_members
    assert_equal "http://schema.org/Person", map["Q1918953"][:type]
  end
end