#!/usr/bin/ruby
# Ubuntu: sudo apt-get install rubygem libxslt1-dev && sudo gem install mechanize
require 'rubygems'
require 'mechanize'
require 'digest/md5'
require 'cache.rb'

class EvalWebScraper
  def initialize
    @agent = Mechanize.new
    weird_page = @agent.get('http://evalweb.ville.montreal.qc.ca/')
    @search_page = weird_page.meta_refresh[0].click
  end
  def perform_request
    tries = 0
    begin
      page = yield
      if (!page.nil? && page.body.include?("Votre session n'est pas valide"))
        puts "ERROR: Session expired!"
        raise "Session expired" # trigger a retry
      end
      page
    rescue
      tries += 1
      if ($!.page && $!.page.body.include?("Requested operation requires a current record"))
        puts "Missing!"
      else
        puts "RETRY #{tries} " + $!
        retry if tries <= 1
        puts "ERROR (tried #{tries})"
      end
      nil
    end
  end
  def search_street(search_term)
    perform_request do
      @search_page.forms.first['text1'] = search_term
      cookie = Mechanize::Cookie.new('nom_rue', search_term)
      cookie.domain = "evalweb.ville.montreal.qc.ca"
      cookie.path = "/"
      @agent.cookie_jar.add(@agent.history.last.uri, cookie)
      @search_page.forms.first.click_button
    end
  end
  def get_street(street_id)
    perform_request do
      @agent.get("RechAdresse.ASP?IdAdrr=" + street_id)
    end
  end
  def get_evaluation(id_uef)
    perform_request do
      @agent.get("CompteFoncier.ASP?id_uef=" + id_uef)
    end
  end
end

evalweb = EvalWebScraper.new
[('aa'..'zz'),(0..9)].each do |range|
  range.map.each do |search_term|
  #range.map.reverse.each do |search_term| # reverse when resuming near the end
    # The session can expire, so do not cache queries in hope of avoiding that.
    streets_body = ScrapeCache::get('street_search', search_term)
    #streets_body = nil
    streets_page = if (streets_body.nil?)
      puts "[#{search_term}] GET streets: #{search_term}"
      page = evalweb.search_street(search_term)
      ScrapeCache::put('street_search', search_term, page.body)
      page.parser
    else
      puts "[#{search_term}] CACHE search: #{search_term}"
      Nokogiri::HTML::Document.parse(streets_body)
    end
    streets_page.css('/html/body/div/div/div/p[6]/select/option').each do |street_option|
      street_id = street_option.attribute('value').value
      street_name = street_option.content.gsub(/\s+/, " ")
      street_body = ScrapeCache::get('street', street_id)
      street_page = if (street_body.nil?)
        puts "[#{search_term}] GET street: #{street_id} (#{street_name})"
        page = evalweb.get_street(street_id)
        ScrapeCache::put('street', street_id, page.body)
        page.parser
      else
        puts "[#{search_term}] CACHE street: #{street_id} (#{street_name})"
        Nokogiri::HTML::Document.parse(street_body)
      end
      street_page.css("option").each do |option|
        address_id = option.attribute('value').value
        address_name = option.content
        begin
          address_body = ScrapeCache::get('address', address_id)
          address_page = if (address_body.nil?)
            puts "[#{search_term}] GET address: #{address_id} (#{address_name})"
            page = evalweb.get_evaluation(address_id)
            if (!page.nil?)
              ScrapeCache::put('address', address_id, page.body)
              page.parser
            end
          else
            puts "[#{search_term}] CACHE address: #{address_id} (#{address_name})"
            Nokogiri::HTML::Document.parse(address_body)
          end
          # Do something with address_page?
        rescue
          puts "[#{search_term}] ERROR address: #{address_id} (#{address_name}) " + $!
        end
      end
    end
  end
end

