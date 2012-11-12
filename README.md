Scraper pour le rôle d'évaluation foncière de la Ville de Montréal: http://evalweb.ville.montreal.qc.ca/

# Example Queries

## Total Value

    SELECT count(*),
        format(sum(valeur_terrain),0) as terrains,
        format(sum(valeur_batiment),0) as batiments,
        format(sum(valeur_immeuble),0) as immeubles
      FROM evaluations;

## Value by Borough

    SELECT ville, arrondissement, count(*),
        format(sum(valeur_terrain),0) as terrains,
        format(sum(valeur_batiment),0) as batiments,
        format(sum(valeur_immeuble),0) as immeubles
      FROM evaluations
      GROUP BY ville, arrondissement
      ORDER BY SUM(valeur_immeuble) DESC;

## Value by Owner

    SELECT proprietaire, count(*),
        format(sum(valeur_terrain),0) as terrains,
        format(sum(valeur_batiment),0) as batiments,
        format(sum(valeur_immeuble),0) as immeubles
      FROM evaluations
      GROUP BY proprietaire
      ORDER BY SUM(valeur_immeuble) DESC
      LIMIT 30;

## Value by Street

    SELECT
        substring(address_street.street_name, 1, LOCATE(',', address_street.street_name)-1) as street_name,
        count(*),
        format(sum(valeur_terrain),0) as terrains,
        format(sum(valeur_batiment),0) as batiments,
        format(sum(valeur_immeuble),0) as immeubles
      FROM evaluations
      JOIN address_street ON address_street.address_id = address.uef_id
      GROUP BY (street_name)
      ORDER BY SUM(valeur_immeuble) DESC
      LIMIT 30;

## Value of a Given Street, by Owner

    SELECT proprietaire, count(*),
        format(sum(valeur_terrain),0) as terrains,
        format(sum(valeur_batiment),0) as batiments,
        format(sum(valeur_immeuble),0) as immeubles
      FROM evaluations
      JOIN address_street ON address_street.address_id = address.uef_id
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
      JOIN address_street ON address_street.address_id = address.uef_id
      WHERE substring(address_street.street_name, 1, LOCATE(',', address_street.street_name)-1)
        = 'SAINTE CATHERINE'
      ORDER BY valeur_terrain/emplacement_superficie DESC
      LIMIT 30;

