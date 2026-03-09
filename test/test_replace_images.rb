require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../src/reload_wikidata'

WIKIMEDIA_RESPONSE = JSON.generate({
  "query" => {
    "pages" => {
      "1" => {
        "imageinfo" => [{ "thumburl" => "https://upload.wikimedia.org/thumb/Test.jpg/300px-Test.jpg" }]
      }
    }
  }
})

WIKIMEDIA_NO_THUMB = JSON.generate({
  "query" => { "pages" => { "1" => {} } }
})

class TestReplaceImages < Minitest::Test
  def setup
    @graph     = RDF::Graph.new
    @place_uri = RDF::URI("http://www.wikidata.org/entity/Q123")
  end

  def test_replaces_filepath_with_thumburl
    @graph << RDF::Statement(@place_uri, SCHEMA.image,
                RDF::URI("http://commons.wikimedia.org/wiki/Special:FilePath/Test.jpg"))
    stub_request(:get, /commons\.wikimedia\.org/)
      .to_return(status: 200, body: WIKIMEDIA_RESPONSE)

    replace_images(@graph)

    images = @graph.query([nil, SCHEMA.image, nil]).map { |s| s.object.to_s }
    assert_equal 1, images.size
    assert_includes images.first, "300px"
    refute_includes images.first, "Special:FilePath"
  end

  def test_skips_image_without_filepath
    plain_uri = RDF::URI("https://upload.wikimedia.org/thumb/Already-thumb.jpg")
    @graph << RDF::Statement(@place_uri, SCHEMA.image, plain_uri)

    replace_images(@graph)

    images = @graph.query([nil, SCHEMA.image, nil]).map { |s| s.object.to_s }
    assert_equal 1, images.size
    assert_equal plain_uri.to_s, images.first
  end

  def test_keeps_original_when_no_thumburl_returned
    original_uri = RDF::URI("http://commons.wikimedia.org/wiki/Special:FilePath/Test.jpg")
    @graph << RDF::Statement(@place_uri, SCHEMA.image, original_uri)
    stub_request(:get, /commons\.wikimedia\.org/)
      .to_return(status: 200, body: WIKIMEDIA_NO_THUMB)

    replace_images(@graph)

    images = @graph.query([nil, SCHEMA.image, nil]).map { |s| s.object.to_s }
    assert_equal 1, images.size
    assert_includes images.first, "Special:FilePath"
  end

  def test_handles_multiple_images
    (1..3).each do |i|
      @graph << RDF::Statement(@place_uri, SCHEMA.image,
                  RDF::URI("http://commons.wikimedia.org/wiki/Special:FilePath/Test#{i}.jpg"))
    end

    call_count = 0
    stub_request(:get, /commons\.wikimedia\.org/).to_return do
      call_count += 1
      body = JSON.generate({
        "query" => {
          "pages" => {
            "1" => { "imageinfo" => [{ "thumburl" => "https://upload.wikimedia.org/thumb/#{call_count}/300px.jpg" }] }
          }
        }
      })
      { status: 200, body: body }
    end

    replace_images(@graph)

    images = @graph.query([nil, SCHEMA.image, nil]).map { |s| s.object.to_s }
    assert_equal 3, images.size
    images.each { |img| refute_includes img, "Special:FilePath" }
  end
end