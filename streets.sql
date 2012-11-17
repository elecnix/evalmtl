use registre_foncier_montreal;
CREATE TABLE address_street_tmp (address_id integer, street_name varchar(255));
LOAD DATA LOCAL INFILE 'streets.csv' INTO TABLE address_street_tmp CHARACTER SET UTF8;
CREATE INDEX address_street_tmp_address_id_index ON address_street_tmp (address_id);
CREATE TABLE address_street SELECT DISTINCT address_id, street_name FROM address_street_tmp;
CREATE INDEX address_street_address_id_index ON address_street (address_id);

