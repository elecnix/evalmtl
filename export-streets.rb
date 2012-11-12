#!/usr/bin/ruby
# Ubuntu: sudo apt-get install rubygem libxslt1-dev && sudo gem install mechanize
require 'rubygems'
require 'mechanize'
require 'foncier/cache.rb'

File.open("streets.sql", 'w') do |sql|
  sql.write("use registre_foncier_montreal;\n")
  sql.write("CREATE TABLE streets_tmp (address_id integer, street_name varchar(255));\n")
  sql.write("LOAD DATA LOCAL INFILE 'streets.csv' INTO TABLE streets_tmp;\n")
  sql.write("CREATE INDEX address_tmp_id_index ON streets_tmp (address_id);\n")
  sql.write("CREATE TABLE address_street SELECT DISTINCT address_id, street_name FROM streets_tmp;\n")
  sql.write("CREATE INDEX address_street_address_id_index ON address_street (address_id);")
  # Note: Can't create a UNIQUE INDEX because there are lots that have more than one address!
end

File.open("streets.csv", 'w') do |csv|
  [('aa'..'zz'),(0..9)].each do |ranges|
    ranges.each do |search_term|
      streets_body = ScrapeCache::get("street_search", search_term)
      if (!streets_body.nil?)
        puts "CACHE search: #{search_term}"
        streets_page = Nokogiri::HTML::Document.parse(streets_body)
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

