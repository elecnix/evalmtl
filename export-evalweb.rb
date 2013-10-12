#!/usr/bin/ruby
# encoding: UTF-8
# Ubuntu: sudo apt-get install rubygem libxslt1-dev && sudo gem install mechanize
require 'rubygems'
require 'mechanize'
require 'dbm'

fields = [
  ["Adresse", :s, 'adresse', :na],
  ["Adresse postale", :s, 'adresse_postale', :na],
  ["Arrondissement", :s, 'arrondissement', :values],
  ["Condition particulière d'inscription", :s, 'cond_particuliere', :values],
  ["Date de référence au marché", :s, 'date_reference', :na],
  ["Date d'inscription au rôle", :s, 'date_inscription', :na],
  ["Dossier n°", :s, 'dossier_no', :na],
  ["En vigueur pour les exercices financiers", :s, 'en_vigueur', :na],
  ["Mesure frontale", :f, 'mesure_frontale', :sum],
  ["Municipalité de", :s, 'municipalite', :values],
  ["Nom", :s, 'nom', :na],
  ["Numéro de lot", :s, 'numero_lot', :na],
  ["Numéro d'unité de voisinage", :s, 'unite_voisinage', :na],
  ["Numéro matricule", :s, 'numero_matricule', :na],
  ["Statut aux fins d'imposition scolaire", :s, 'statut_scolaire', :values],
  ["Superficie", :f, 'superficie', :sum],
  ["Utilisation prédominante", :s, 'utilisation', :values],
  ["Valeur de l'immeuble", :i, 'valeur_immeuble', :sum],
  ["Valeur du bâtiment", :i, 'valeur_batiment', :sum],
  ["Valeur du terrain", :i, 'valeur_terrain', :sum],
  ["Valeur imposable de l'immeuble", :i, 'valeur_imposable', :sum],
  ["Nombre d'étages", :i, 'nb_etages', :values],
  ["Année de construction", :i, 'annee_construction', :values],
  ["Aire d'étages", :f, 'aire_etages', :sum],
  ["Genre de construction", :s, 'genre_construction', :values],
  ["Lien physique", :s, 'lien_physique', :values],
  ["Nombre de logements", :i, 'nb_logements', :values],
  ["Nombre de locaux non résidentiels", :i, 'nb_locaux_non_residentiels', :values],
  ["Nombre de chambres locatives", :i, 'nb_chambres_locatives', :values],
  ["Valeur de l'immeuble au rôle antérieur", :i, 'valeur_immeuble_anterieur', :sum],
  ["Valeur non imposable de l'immeuble", :i, 'valeur_non_imposable_immeuble', :sum],
  ["Zonage agricole", :s, 'zonage_agricole', :values],
  ["Exploitation agricole enregistrée (EAE)", :s, 'eae', :values],
  ["Superficie zonée EAE", :f, 'superficie_eae', :sum],
  ["Superficie totale EAE", :f, 'superficie_totale_eae', :sum]
]

File.open("evaluations_2014.sql", 'w') do |sql|
  sql.write("create database evalmtl ENGINE=InnoDB;\n")
  sql.write("use evalmtl\n")
  sql_types = {:s => "varchar(10000)", :i => "integer", :f => "NUMERIC(20, 4)"}
  fields.map{|c|c[0] }.join("\t")
  sql.write("create table evaluations_2014 (street_name varchar(255), \n" + fields.map{|c| "  #{c[2]} #{sql_types[c[1]]}"}.join(",\n") + "\n) ENGINE=InnoDB;\n")
  sql.write("LOAD DATA LOCAL INFILE 'evaluations_2014.csv' INTO TABLE evaluations_2014 CHARACTER SET UTF8 IGNORE 1 LINES;\n")
  sql.write("CREATE INDEX street_name_index ON evaluations_2014 (street_name);\n")
  sql.write("CREATE INDEX adresse_index ON evaluations_2014 (adresse);\n")
  sql.write("CREATE INDEX nom_index ON evaluations_2014 (nom);\n")
  sql.write("CREATE INDEX arrondissement_index ON evaluations_2014 (arrondissement);\n")
  sql.write("CREATE INDEX cond_particuliere_index ON evaluations_2014 (cond_particuliere);\n")
  sql.write("CREATE INDEX utilisation_index ON evaluations_2014 (utilisation);\n")
  sql.write("CREATE INDEX statut_scolaire_index ON evaluations_2014 (statut_scolaire);\n")
  sql.write("CREATE INDEX genre_construction_index ON evaluations_2014 (genre_construction);\n")
  sql.write("CREATE INDEX lien_physique_index ON evaluations_2014 (lien_physique);\n")
  sql.write("CREATE INDEX nb_etages_index ON evaluations_2014 (nb_etages);\n")
  sql.write("CREATE INDEX nb_logements_index ON evaluations_2014 (nb_logements);\n")
  sql.write("CREATE INDEX nb_locaux_non_residentiels_index ON evaluations_2014 (nb_locaux_non_residentiels);\n")
  sql.write("CREATE INDEX nb_chambres_locatives_index ON evaluations_2014 (nb_chambres_locatives);\n")
  sql.write("ALTER TABLE evaluations_2014 ADD COLUMN code_postal_proprio varchar(7);\n")
  sql.write("UPDATE evaluations_2014 SET code_postal_proprio = substr(adresse_postale,-7,7);");
  sql.write("CREATE INDEX code_postal_proprio_index ON evaluations_2014 (code_postal_proprio);\n")
  value_fields = fields.select{|c| c[3] == :values}
  sum_fields = fields.select{|c| c[3] == :sum}
  sql.write("CREATE TABLE evaluations_2014_aggregate SELECT street_name, " + value_fields.map{|c| " #{c[2]}"}.join(",\n") + ",\n" + sum_fields.map{|c| " sum(#{c[2]}) as #{c[2]}_sum"}.join(",\n") + "\n  FROM evaluations_2014\n  GROUP BY " + value_fields.map{|c| " #{c[2]}"}.join(",\n") + ";\n");
end
#return

def clean(value)
  value.gsub(/[\s ]+/, " ").strip
end
def clean_label(value)
  clean(value).gsub(/:/, '').strip
end
def is_valid_label(value)
  !(value.empty? || value =~ /^\d/)
end

streets = DBM.open('street_2014')
street_for_address = DBM.open('address_street')

skip_street_index = false

if (!skip_street_index) then
  puts "Opening search DB..."
  street_search = DBM.open('street_search_2014')
  street_search.each_entry do |term, results_body|
    puts "Indexing: #{term}"
    results_page = Nokogiri::HTML::Document.parse(results_body.force_encoding('utf-8')) 
    results_page.css('select[@id=select1]/option').each do |street_option|
      street_id = street_option.attribute('value').value
      street_name = street_option.content.gsub(/\s+/, " ")
      street_body = streets[street_id].force_encoding('utf-8')
      street_page = Nokogiri::HTML::Document.parse(street_body) 
      street_page.css("option").each do |option|
        address_id = option.attribute('value').value
        street_for_address[address_id] = street_name
  #      puts "#{term} -> #{street_name} -> #{address_id}"
      end
    end
  end
  street_search.close
end

db = DBM.open('address_2014')
File.open("evaluations_2014.csv", 'w:UTF-8') do |csv|
  csv.write("street_name\t")
  csv.write(fields.map{|c|c[0] }.join("\t"))
  csv.write("\n")
  db.each_entry do |address_id, page_content|
    address_id.force_encoding('utf-8')
    page_content.force_encoding('utf-8')
    page = Nokogiri::HTML::Document.parse(page_content, encoding='UTF-8')
    @databases = Hash.new { |dbs, namespace| dbs[namespace] = DBM.open(namespace + "_2014") }
    field_values = Hash.new { |h, label| h[label] = [] }
    page.xpath('//*[@id="AutoNumber1"]/tr').map {|tr|
      tds = tr.xpath('td')
      case tds.count
      when 3
        label = clean_label(tds[0].content)
        field_values[label] << clean(tds[1].content) if (is_valid_label(label))
      when 6
        label = clean_label(tds[0].content)
        field_values[label] << clean(tds[1].content) if (is_valid_label(label))
        label = clean_label(tds[3].content)
        field_values[label] << clean(tds[4].content) if (is_valid_label(label))
      end
    }
    data = []
    fields.each_with_index do |col, i|
      values = field_values.delete(col[0])
      if (values.nil? || values.empty?) then
        puts "[#{address_id}] missing: #{col[0]}"
        data[i] = nil
      else
        data[i] = values.map { |v|
          case col[1]
          when :i, :f
            v.gsub(' ', '').strip.gsub(/\$/, '').gsub(/m2/, '').gsub(/m/, '').gsub(/\(estiée\)/, '')
          else
            v
          end
        }.join('&')
      end
    end
    field_values.each do |v|
      puts "[#{address_id}] Not mapped: #{v}"
    end
    street_name = street_for_address[address_id]
    if street_name.nil? then
      puts "No street name! #{address_id}"
    else
      street_name.force_encoding('utf-8') 
      street_name = street_name.split('/')[0].strip
      puts "#{street_name} -> #{address_id}"
    end
    csv.write("#{street_name}\t")
    csv.write(data.join("\t"))
    csv.write("\n")
  end
end
db.close

street_for_address.close

