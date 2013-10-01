#!/usr/bin/ruby
# encoding: UTF-8
# Ubuntu: sudo apt-get install rubygem libxslt1-dev && sudo gem install mechanize
require 'rubygems'
require 'mechanize'
require 'dbm'

fields = [
  ["Adresse", :s, 'adresse'],
  ["Adresse postale", :s, 'adresse_postale'],
  ["Arrondissement", :s, 'arrondissement'],
  ["Condition particulière d'inscription", :s, 'cond_particuliere'],
  ["Date de référence au marché", :s, 'date_reference'],
  ["Date d'inscription au rôle", :s, 'date_inscription'],
  ["Dossier n°", :s, 'dossier_no'],
  ["En vigueur pour les exercices financiers", :s, 'en_vigueur'],
  ["Mesure frontale", :i, 'mesure_frontale'],
  ["Municipalité de", :s, 'municipalite'],
  ["Nom", :s, 'nom'],
  ["Numéro de lot", :s, 'numero_lot'],
  ["Numéro d'unité de voisinage", :s, 'unite_voisinage'],
  ["Numéro matricule", :s, 'numero_matricule'],
  ["Statut aux fins d'imposition scolaire", :s, 'statut_scolaire'],
  ["Superficie", :i, 'superficie'],
  ["Utilisation prédominante", :s, 'utilisation'],
  ["Valeur de l'immeuble", :i, 'valeur_immeuble'],
  ["Valeur du bâtiment", :i, 'valeur_batiment'],
  ["Valeur du terrain", :i, 'valeur_terrain'],
  ["Valeur imposable de l'immeuble", :i, 'valeur_imposable'],
  ["Nombre d'étages", :i, 'nb_etages'],
  ["Année de construction", :i, 'annee_construction'],
  ["Aire d'étages", :i, 'aire_etages'],
  ["Genre de construction", :s, 'genre_construction'],
  ["Lien physique", :s, 'lien_physique'],
  ["Nombre de logements", :i, 'nb_logements'],
  ["Nombre de locaux non résidentiels", :i, 'nb_locaux_non_residentiels'],
  ["Nombre de chambres locatives", :i, 'nb_chambres_locatives'],
  ["Valeur de l'immeuble au rôle antérieur", :i, 'valeur_immeuble_anterieur'],
  ["Valeur non imposable de l'immeuble", :i, 'valeur_non_imposable_immeuble'],
  ["Zonage agricole", :s, 'zonage_agricole'],
  ["Exploitation agricole enregistrée (EAE)", :s, 'eae'],
  ["Superficie zonée EAE", :i, 'superficie_eae'],
  ["Superficie totale EAE", :i, 'superficie_totale_eae']
]

File.open("evaluations.sql", 'w') do |sql|
  sql.write("create database evalmtl ENGINE=InnoDB;\n")
  sql.write("use evalmtl\n")
  sql_types = {:s => "varchar(255)", :i => "integer", :f => "float"}
  fields.map{|c|c[0] }.join("\t")
  sql.write("create table evaluations (\n" + fields.map{|c| "  #{c[2]} #{sql_types[c[1]]}"}.join(",\n") + "\n) ENGINE=InnoDB;\n")
  sql.write("LOAD DATA LOCAL INFILE 'evaluations_2014.csv' INTO TABLE evaluations CHARACTER SET UTF8 IGNORE 1 LINES;\n")
  sql.write("CREATE INDEX adresse_index ON evaluations (adresse);\n")
  sql.write("CREATE INDEX proprietaire_index ON evaluations (proprietaire);\n")
  sql.write("CREATE INDEX arrondissement_index ON evaluations (arrondissement);\n")
  sql.write("CREATE INDEX arrondissement_no_index ON evaluations (arrondissement_no);\n")
  sql.write("CREATE INDEX type_lot_index ON evaluations (type_lot);\n")
  sql.write("CREATE INDEX uef_id_index ON evaluations (uef_id);\n")
end

def clean(value)
  value.gsub(/[\s ]+/, " ").strip
end
def clean_label(value)
  clean(value).gsub(/:/, '').strip
end
def is_valid_label(value)
  !(value.empty? || value =~ /^\d/)
end

db = DBM.open('address_2014')
File.open("evaluations_2014.csv", 'w:UTF-8') do |csv|
  csv.write(fields.map{|c|c[0] }.join("\t"))
  csv.write("\n")
  db.each_entry do |address_id, page_content|
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
      else
        data[i] = values.map { |v|
          case col[1]
          when :i
            v.gsub(' ', '').strip.gsub(/\$/, '').gsub(/m2/, '').gsub(/m/, '').gsub(/\./, ',')
          else
            v
          end
        }.join('&')
      end
    end
    field_values.each do |v|
      puts "[#{address_id}] Not mapped: #{v}"
    end
    csv.write(data.join("\t"))
    csv.write("\n")
  end
end
db.close

