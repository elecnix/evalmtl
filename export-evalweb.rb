#!/usr/bin/ruby
# encoding: UTF-8
# Ubuntu: sudo apt-get install rubygem libxslt1-dev && sudo gem install mechanize
require 'rubygems'
require 'mechanize'
require 'dbm'

columns = [
  {'id' =>                 ['//*[@id="AutoNumber1"]/tr[14]/td[2]/b/font', :s]}, # no_dossier
  {'municipalite' =>       ['//*[@id="AutoNumber1"]/tr[3]/td[2]/b/font', :s]},
  {'role' =>               ['//*[@id="AutoNumber1"]/tr[4]/td[2]/b/font', :i]},
  {'adresse' =>            ['//*[@id="AutoNumber1"]/tr[8]/td[2]/b/font', :s]},
  {'arrondissement' =>     ['//*[@id="AutoNumber1"]/tr[9]/td[2]/b/font', :s]},
  {'no_lot' =>             ['//*[@id="AutoNumber1"]/tr[10]/td[2]/b/font', :i]},
  {'matricule' =>          ['//*[@id="AutoNumber1"]/tr[11]/td[2]/b/font', :i]},
  {'unite_voisinage' =>    ['//*[@id="AutoNumber1"]/tr[13]/td[2]/b/font', :i]},
  {'dossier' =>            ['//*[@id="AutoNumber1"]/tr[14]/td[2]/b/font', :s]},
  {'proprietaire' =>       ['//*[@id="AutoNumber1"]/tr[18]/td[2]/b/font', :s]},
  {'statut' =>             ['//*[@id="AutoNumber1"]/tr[19]/td[2]/font/b/font', :s]},
  {'adresse_postale' =>    ['//*[@id="AutoNumber1"]/tr[20]/td[2]/b/font', :s]},
  {'date_inscription' =>   ['//*[@id="AutoNumber1"]/tr[21]/td[2]/b/font', :s]},
  {'cond_particuliere' =>  ['//*[@id="AutoNumber1"]/tr[22]/td[2]/b/font', :s]},
  {'mesure_frontale' =>    ['//*[@id="AutoNumber1"]/tr[27]/td[2]/p/b/font', :s]},
  {'superficie' =>         ['//*[@id="AutoNumber1"]/tr[28]/td[2]/p/b/font', :f]}, # m2
  {'nb_etages' =>          ['//*[@id="AutoNumber1"]/tr[27]/td[5]/p/b/font', :i]},
  {'annee_construction' => ['//*[@id="AutoNumber1"]/tr[27]/td[5]/p/b/font', :i]},
  {'aire_etages' =>        ['//*[@id="AutoNumber1"]/tr[29]/td[5]/p/font/b', :f]}, # m2
  {'genre_construction' => ['//*[@id="AutoNumber1"]/tr[30]/td[5]/p/b/font', :s]},
  {'lien_physique' =>      ['//*[@id="AutoNumber1"]/tr[31]/td[5]/p/b/font', :s]},
  {'nb_logements' =>       ['//*[@id="AutoNumber1"]/tr[32]/td[5]/p/b/font', :i]},
  {'nb_locaux_non_residentiels' =>      ['//*[@id="AutoNumber1"]/tr[33]/td[5]/p/b/font', :i]},
  {'nb_chambres_locatives' =>           ['//*[@id="AutoNumber1"]/tr[34]/td[5]/font/b', :i]},
  {'date_reference' =>     ['//*[@id="AutoNumber1"]/tr[39]/td[2]/font/b', :s]},
  {'valeur_terrain' =>     ['//*[@id="AutoNumber1"]/tr[40]/td[2]/p/b/font', :i]}, # $
  {'valeur_batiment' =>    ['//*[@id="AutoNumber1"]/tr[41]/td[2]/p/b/font', :i]}, # $
  {'valeur_immeuble' =>    ['//*[@id="AutoNumber1"]/tr[42]/td[2]/b/font', :i]},   # $
  {'date_reference_role_anterieur' =>   ['//*[@id="AutoNumber1"]/tr[39]/td[5]/p/b/font', :s]},
  {'valeur_immeuble_role_anterieur' =>  ['//*[@id="AutoNumber1"]/tr[40]/td[5]/p/b/font', :i]}, # $
  {'categorie_repartition_fiscale' =>   ['//*[@id="AutoNumber1"]/tr[46]/td[1]/b/font', :s]},
  {'valeur_imposable' =>   ['//*[@id="AutoNumber1"]/tr[47]/td[2]/p/b/font', :i]}, # $
  {'valeur_non_imposable' =>            ['//*[@id="AutoNumber1"]/tr[47]/td[5]/p/b/font', :i]}, # $
  {'mise_a_jour' =>        ['//*[@id="AutoNumber1"]/tr[50]/td[1]/font', :s]}
]

File.open("evaluations.sql", 'w') do |sql|
  sql.write("create database evalmtl ENGINE=InnoDB;\n")
  sql.write("use evalmtl\n")
  sql_types = {:s => "varchar(255)", :i => "integer", :f => "float"}
  sql.write("create table evaluations (\n" + columns.map{|c| c.map{|col,t| "  #{col} #{sql_types[t]}"}}.join(",\n") + "\n) ENGINE=InnoDB;\n")
  sql.write("LOAD DATA LOCAL INFILE 'evaluations.csv' INTO TABLE evaluations CHARACTER SET UTF8 IGNORE 1 LINES;\n")
  sql.write("CREATE INDEX adresse_index ON evaluations (adresse);\n")
  sql.write("CREATE INDEX proprietaire_index ON evaluations (proprietaire);\n")
  sql.write("CREATE INDEX arrondissement_index ON evaluations (arrondissement);\n")
  sql.write("CREATE INDEX arrondissement_no_index ON evaluations (arrondissement_no);\n")
  sql.write("CREATE INDEX type_lot_index ON evaluations (type_lot);\n")
  sql.write("CREATE INDEX uef_id_index ON evaluations (uef_id);\n")
end

db = DBM.open('address_2014')
File.open("evaluations_2014.csv", 'w:UTF-8') do |csv|
  csv.write(columns.map{|c|c.keys}.join("\t"))
  csv.write("\n")
  db.each_entry do |address_id, page_content|
    page_content.force_encoding('utf-8')
    page = Nokogiri::HTML::Document.parse(page_content, encoding='UTF-8')
    data = []
    columns.each do |c|
      value = page.xpath(c.values[0][0]).map {|elem| elem.content.gsub(/\s+/, " ").strip }.fetch(0, '')
      value = case c.values[0][1]
      when :i
        value.gsub(' ', '').gsub('$', '')
      else
        value
      end
      data.push(value)
    end
    csv.write(data.join("\t"))
    csv.write("\n")
  end
end
db.close

