#!/usr/bin/ruby
# Ubuntu: sudo apt-get install rubygem libxslt1-dev && sudo gem install mechanize
require 'rubygems'
require 'mechanize'

class ScrapeCache
  def self.put(key, value)
    if (value.include?("Votre session n'est pas valide"))
      puts "INVALID PUT: #{key}"
      return
    end
    puts "GOOD PUT: #{key}"
    dirname = File.dirname("cache/" + key)
    FileUtils.mkdir_p(dirname)
    File.open("cache/" + key, 'w') do |f|
      f.write(value)
    end
  end
  def self.get(key)
    value = File.open("cache/" + key, 'rb') { |f| f.read } if (File.exists?("cache/" + key))
    if (value.include?("Votre session n'est pas valide"))
      puts "INVALID CACHE: #{key}"
      nil
    else
      value
    end
  end
end

a = Mechanize.new
weird_page = a.get('http://evalweb.ville.montreal.qc.ca/')
search_page = weird_page.meta_refresh[0].click
[('aa'..'zz'),(0..9)].each do |range|
  range.map.reverse.each do |search_term|
    # The session can expire, so do not cache queries in hope of avoiding that.
    #streets_body = ScrapeCache::get('street_search/' + search_term)
    streets_body = nil
    streets_page = if (streets_body.nil?)
      puts 'GET streets: ' + search_term
      search_page.forms.first['text1'] = search_term
      cookie = Mechanize::Cookie.new('nom_rue', search_term)
      cookie.domain = "evalweb.ville.montreal.qc.ca"
      cookie.path = "/"
      a.cookie_jar.add(a.history.last.uri, cookie)
      page = search_page.forms.first.click_button
      ScrapeCache::put('street_search/' + search_term, page.body)
      page.parser
    else
      puts 'CACHE ' + search_term
      Nokogiri::HTML::Document.parse(streets_body)
    end
    streets_page.css('/html/body/div/div/div/p[6]/select/option').each do |street_option|
      street_id = street_option.attribute('value').value
      street_name = street_option.content.gsub(/\s+/, " ")
      begin
        street_key = 'street/' + street_id
        street_body = ScrapeCache::get(street_key)
        street_page = if (street_body.nil?)
          puts "GET street: " + street_id + " (" + street_name + ")"
          page = a.get("RechAdresse.ASP?IdAdrr=" + street_id)
          ScrapeCache::put(street_key, page.body)
          page.parser
        else
          puts "CACHE street: " + street_id + " (" + street_name + ")"
          Nokogiri::HTML::Document.parse(street_body)
        end
        street_page.css("option").each do |option|
          address_id = option.attribute('value').value
          address_name = option.content
          begin
            address_key = 'address/' + address_id
            address_body = ScrapeCache::get(address_key)
            address_page = if (address_body.nil?)
              puts 'GET address: ' + address_id + " (" + address_name + ")"
              page = a.get("CompteFoncier.ASP?id_uef=" + address_id)
              ScrapeCache::put(address_key, page.body)
              page.parser
            else
              puts "CACHE address: " + address_id + " (" + address_name + ")"
              Nokogiri::HTML::Document.parse(address_body)
            end
          rescue
            puts "ERROR address: " + address_id + " (" + address_name + ")"
          end
        end
      rescue
        puts "ERROR street: " + street_id + " (" + street_name + ")"
      end
    end
  end
end

