use evalmtl;
CREATE TABLE address_street_tmp (address_id integer, street_name varchar(200));
LOAD DATA LOCAL INFILE 'streets.csv' INTO TABLE address_street_tmp CHARACTER SET UTF8 FIELDS OPTIONALLY ENCLOSED BY "'";
CREATE INDEX address_street_tmp_address_id_index ON address_street_tmp (address_id);
CREATE TABLE address_street SELECT DISTINCT address_id, street_name FROM address_street_tmp;
CREATE INDEX address_street_address_id_index ON address_street (address_id);
CREATE INDEX address_street_street_name_index ON address_street (street_name);

