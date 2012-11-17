#!/usr/bin/ruby
# Ubuntu: sudo apt-get install rubygem libxslt1-dev && sudo gem install mechanize
require 'rubygems'
require 'mechanize'
require 'lib/cache.rb'

File.open("streets.csv", 'w:UTF-8') do |csv|
  [('aa'..'zz'),(0..9)].each do |ranges|
    ranges.each do |search_term|
      streets_body = ScrapeCache::get("street_search", search_term)
      if (!streets_body.nil?)
        puts "CACHE search: #{search_term}"
        streets_page = Nokogiri::HTML::Document.parse(streets_body, encoding='UTF-8')
        streets_page.css('/html/body/div/div/div/p[6]/select/option').each do |street_option|
          street_id = street_option.attribute('value').value
          street_name = street_option.content.gsub(/\s+/, " ").gsub("'", "''")
          street_body = ScrapeCache::get("street", street_id)
          if (!street_body.nil?)
            puts "CACHE street: " + street_id + " (" + street_name + ")"
            street_page = Nokogiri::HTML::Document.parse(street_body)
            street_page.css("option").each do |option|
              address_id = option.attribute('value').value
              csv.write("#{address_id}\t'#{street_name}'\n")
            end
          end
        end
      end
    end
  end
end

