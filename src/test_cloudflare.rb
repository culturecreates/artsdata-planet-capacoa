#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

class CloudflareDetector
  def initialize
    @artsdata_user_agent = 'artsdata-crawler'
    @regular_user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
  end

  def test_website(url)
    puts "Testing: #{url}"
    puts "=" * 50
    
    # Ensure URL has scheme
    url = "https://#{url}" unless url.start_with?('http')
    uri = URI(url)
    
    # Test with artsdata-crawler user agent
    artsdata_result = test_with_user_agent(uri, @artsdata_user_agent, "artsdata-crawler")
    
    # Test with regular browser user agent
    browser_result = test_with_user_agent(uri, @regular_user_agent, "browser")
    
    # Analyze results
    analyze_results(url, artsdata_result, browser_result)
    
    puts "\n" + "=" * 50 + "\n"
  end

  private

  def test_with_user_agent(uri, user_agent, agent_type)
    begin
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = user_agent
      request['Accept'] = 'text/html,application/xhtml+xml'
      
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = 10
      http.read_timeout = 15
      
      start_time = Time.now
      response = http.request(request)
      duration = Time.now - start_time
      
      # Check for Cloudflare headers
      cf_headers = extract_cloudflare_headers(response)
      
      # Check for challenge page
      is_challenge = cloudflare_challenge?(response)
      
      puts "#{agent_type.capitalize} test:"
      puts "  Status: #{response.code} #{response.message}"
      puts "  Duration: #{duration.round(2)}s"
      puts "  Cloudflare detected: #{!cf_headers.empty?}"
      puts "  Challenge page: #{is_challenge}"
      
      if !cf_headers.empty?
        puts "  CF Headers:"
        cf_headers.each { |k, v| puts "    #{k}: #{v}" }
      end
      
      {
        status_code: response.code.to_i,
        duration: duration,
        cloudflare_detected: !cf_headers.empty?,
        challenge_page: is_challenge,
        cf_headers: cf_headers,
        success: response.is_a?(Net::HTTPSuccess) && !is_challenge
      }
      
    rescue => e
      puts "#{agent_type.capitalize} test: ERROR - #{e.message}"
      {
        status_code: nil,
        duration: nil,
        cloudflare_detected: false,
        challenge_page: false,
        cf_headers: {},
        success: false,
        error: e.message
      }
    end
  end

  def extract_cloudflare_headers(response)
    cf_headers = {}
    
    response.each_header do |name, value|
      if name.downcase.start_with?('cf-') || 
         name.downcase == 'server' && value.downcase.include?('cloudflare')
        cf_headers[name] = value
      end
    end
    
    cf_headers
  end

  def cloudflare_challenge?(response)
    return false unless response && response.body
    
    body = response.body.to_s.downcase
    
    challenge_indicators = [
      'checking your browser',
      'cloudflare ray id',
      'please wait while we check your browser',
      'ddos protection by cloudflare',
      'browser check',
      'cf-browser-verification',
      'challenge-platform'
    ]
    
    challenge_indicators.any? { |indicator| body.include?(indicator) }
  end

  def analyze_results(url, artsdata_result, browser_result)
    puts "\nAnalysis:"
    
    if artsdata_result[:cloudflare_detected] || browser_result[:cloudflare_detected]
      puts "  ✓ Cloudflare detected on this website"
      
      if artsdata_result[:challenge_page] && !browser_result[:challenge_page]
        puts "  ⚠️  artsdata-crawler is being challenged by Cloudflare"
        puts "  📋 Recommendation: Configure Cloudflare to allow artsdata-crawler"
        puts "      See CLOUDFLARE_CONFIG.md for instructions"
      elsif artsdata_result[:success] && browser_result[:success]
        puts "  ✅ Both user agents work - Cloudflare configured correctly"
      elsif !artsdata_result[:success] && !browser_result[:success]
        puts "  ❌ Both user agents blocked - general access issue"
      end
    else
      puts "  ℹ️  No Cloudflare detected (or headers not exposed)"
    end
    
    if artsdata_result[:success]
      puts "  ✅ artsdata-crawler can access this website"
    else
      puts "  ❌ artsdata-crawler cannot access this website"
      if artsdata_result[:error]
        puts "     Error: #{artsdata_result[:error]}"
      end
    end
  end
end

# Usage
if __FILE__ == $0
  detector = CloudflareDetector.new
  
  # Test websites
  test_sites = [
    "capacoa.ca",
    "github.com",
    "stackoverflow.com",
    "example.com"
  ]
  
  if ARGV.any?
    # Use command line arguments
    ARGV.each { |site| detector.test_website(site) }
  else
    # Use default test sites
    puts "Cloudflare Detection and artsdata-crawler Compatibility Test"
    puts "Testing default websites. You can also specify websites as arguments."
    puts
    
    test_sites.each { |site| detector.test_website(site) }
    
    puts "To test your own websites:"
    puts "ruby #{__FILE__} yoursite.com anothersite.com"
  end
end
