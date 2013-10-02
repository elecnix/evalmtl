Scraper pour le rôle d'évaluation foncière de la Ville de Montréal: http://evalweb.ville.montreal.qc.ca/

For 2014, this represents $296,605,225,088.00 (296 *billion* dollars).

# Installation

    git clone ...
    
On Ubuntu, you may have to install some libraries first:

    sudo apt-get install rubygems libxslt1-dev
    gem install mechanize
    gem install minitar

# Usage

Start scraping:

    ./scrape-evalweb.rb

The scraper produces dir and pag files, where it stores the web pages it fetched.

Once it is done, extract the data. This will create `evaluations.csv` as well as the SQL commands to load it into MySQL:

    ./export-evalweb.rb

Let it finish (it can take hours for the tar archive generation, and an hour for the CSV export), then import the resulting files into MySQL:

    mysql --local-infile -u root < evaluations_2014.sql

You can now query the database:

    mysql -u root evalmtl

# Downloads

You may spare yourself the scraping by downloading a cache from november 2012 with BitTorrent:

    magnet:?xt=urn:btih:cf07bef9dc9264abd8a0ab9c4412bea634065b1a&dn=evalweb-cache.tgz&tr=udp%3A%2F%2Ftracker.istole.it%3A80

Or download the CSV file directly:

    magnet:?xt=urn:btih:5fdd555ff92acb6fb300a50c71d90516770aeda3&dn=evaluations.csv.gz&tr=udp%3A%2F%2Ftracker.istole.it%3A80

# Example Queries

## Total Value

    SELECT count(*),
        format(sum(valeur_terrain),0) as terrains,
        format(sum(valeur_batiment),0) as batiments,
        format(sum(valeur_immeuble),0) as immeubles
      FROM evaluations_2014;

## Value by Borough

    SELECT municipalite, arrondissement, count(*),
        format(sum(valeur_terrain),0) as terrains,
        format(sum(valeur_batiment),0) as batiments,
        format(sum(valeur_immeuble),0) as immeubles
      FROM evaluations_2014
      GROUP BY municipalite, arrondissement
      ORDER BY SUM(valeur_immeuble) DESC;

## Value by Owner

    SELECT nom, count(*),
        format(sum(valeur_terrain),0) as terrains,
        format(sum(valeur_batiment),0) as batiments,
        format(sum(valeur_immeuble),0) as immeubles
      FROM evaluations_2014
      GROUP BY nom
      ORDER BY SUM(valeur_immeuble) DESC
      LIMIT 30;

## Value by Street

    SELECT
        substring(address_street.street_name, 1, LOCATE(',', address_street.street_name)-1) as street_name,
        count(*),
        format(sum(valeur_terrain),0) as terrains,
        format(sum(valeur_batiment),0) as batiments,
        format(sum(valeur_immeuble),0) as immeubles
      FROM evaluations_2014
      JOIN address_street ON address_street.address_id = evaluations.uef_id
      GROUP BY (street_name)
      ORDER BY SUM(valeur_immeuble) DESC
      LIMIT 30;

## Value of a Given Street, by Owner

    SELECT proprietaire, count(*),
        format(sum(valeur_terrain),0) as terrains,
        format(sum(valeur_batiment),0) as batiments,
        format(sum(valeur_immeuble),0) as immeubles
      FROM evaluations_2014
      JOIN address_street ON address_street.address_id = evaluations.uef_id
      WHERE substring(address_street.street_name, 1, LOCATE(',', address_street.street_name)-1)
        = 'SAINTE CATHERINE'
      GROUP BY (proprietaire)
      ORDER BY SUM(valeur_immeuble) DESC LIMIT 30;

## Most Expensive Lots on a Given Street

    SELECT proprietaire, adresse, address_id,
        format(valeur_terrain,0) as terrain,
        emplacement_superficie as superficice,
        format(valeur_terrain/emplacement_superficie,0) as valeur_terrain
      FROM evaluations
      JOIN address_street ON address_street.address_id = evaluations.uef_id
      WHERE substring(address_street.street_name, 1, LOCATE(',', address_street.street_name)-1)
        = 'SAINTE CATHERINE'
      ORDER BY valeur_terrain/emplacement_superficie DESC
      LIMIT 30;

## Land Value Average by Street

    SELECT
        address_street.street_name,
        count(*) as nb_terrains,
        sum(valeur_terrain) as valeur_total_terrains,
        sum(emplacement_superficie) as total_superficie,
        sum(valeur_terrain) / sum(emplacement_superficie) as valeur_moyenne
      FROM evaluations_2014
      JOIN address_street ON address_street.address_id = evaluations.uef_id
      GROUP BY (street_name)
      ORDER BY street_name ASC
      LIMIT 100;

# Merge Street Name with Lot

For big queries, joining on the address_street table can be expensive, so it is a good idea to merge the two together. However, some lots have multiple addresses, so let's keep in mind we'll be picking just one per lot.

    ALTER TABLE evaluations_2014 ADD COLUMN street_name varchar(200);
    UPDATE evaluations_2014
      JOIN address_street on address_street.address_id = evaluations.uef_id
      SET evaluations_2014.street_name = address_street.street_name;
    CREATE INDEX evaluations_street_name_index ON evaluations_2014 (street_name);

## Land Value Average by Street

    SELECT
        street_name,
        count(*) as nb_terrains,
        sum(valeur_terrain) as valeur_total_terrains,
        sum(emplacement_superficie) as total_superficie,
        sum(valeur_terrain) / sum(emplacement_superficie) as valeur_moyenne
      FROM evaluations_2014
      GROUP BY (street_name)
      ORDER BY street_name ASC
      LIMIT 100;

## Land Difference with Street Average

    SELECT
        proprietaire,
        adresse,
        no_lot_renove,
        nb_etages,
        valeur_terrain,
        emplacement_superficie as superficie,
        street_average.valeur_moyenne,
        valeur_terrain / emplacement_superficie as valeur,
        valeur_terrain / emplacement_superficie - street_average.valeur_moyenne as difference,
        street_average.valeur_moyenne * emplacement_superficie - valeur_terrain as manque
      FROM evaluations_2014
      JOIN (
        SELECT
            street_name,
            sum(valeur_terrain) / sum(emplacement_superficie) as valeur_moyenne
          FROM evaluations_2014
          WHERE emplacement_superficie > 50
          GROUP BY street_name
      ) AS street_average ON street_average.street_name = evaluations_2014.street_name
      WHERE valeur_terrain / emplacement_superficie - street_average.valeur_moyenne < 50
      ORDER BY manque DESC
      LIMIT 100;

# Export Aggregate to CSV

    select 'arrondissement','cond_particuliere','municipalite','statut_scolaire','utilisation','nb_etages','annee_construction','genre_construction','lien_physique','nb_logements','nb_locaux_non_residentiels','nb_chambres_locatives','zonage_agricole','eae','mesure_frontale_sum','superficie_sum','valeur_immeuble_sum','valeur_batiment_sum','valeur_terrain_sum','valeur_imposable_sum','aire_etages_sum','valeur_immeuble_anterieur_sum','valeur_non_imposable_immeuble_sum','superficie_eae_sum','superficie_totale_eae_sum'
    UNION ALL
    SELECT * INTO OUTFILE '/tmp/evaluations_2014_aggregate.csv'
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
      ESCAPED BY '\\'
      FROM evaluations_2014_aggregate;

Now, get creative!

http://argent.canoe.ca/lca/financespersonnelles/quebec/archives/2010/01/20100111-113558.html

