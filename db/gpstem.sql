-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler  version: 0.9.0-alpha1
-- PostgreSQL version: 9.6
-- Project Site: pgmodeler.com.br
-- Model Author: Geert-Johan Riemer

SET check_function_bodies = false;
-- ddl-end --

-- object: rutte | type: ROLE --
-- DROP ROLE IF EXISTS rutte;
CREATE ROLE rutte WITH 
	SUPERUSER
	LOGIN
	UNENCRYPTED PASSWORD 'rutte';
-- ddl-end --


-- Database creation must be done outside an multicommand file.
-- These commands were put in this file only for convenience.
-- -- object: gpstem | type: DATABASE --
-- -- DROP DATABASE IF EXISTS gpstem;
-- CREATE DATABASE gpstem
-- ;
-- -- ddl-end --
-- 

-- object: members | type: SCHEMA --
-- DROP SCHEMA IF EXISTS members CASCADE;
CREATE SCHEMA members;
-- ddl-end --
ALTER SCHEMA members OWNER TO postgres;
-- ddl-end --

SET search_path TO pg_catalog,public,members;
-- ddl-end --

-- object: members.accounts | type: TABLE --
-- DROP TABLE IF EXISTS members.accounts CASCADE;
CREATE TABLE members.accounts(
	id serial NOT NULL,
	email varchar(200) NOT NULL,
	nickname varchar(30),
	given_name varchar(100),
	first_names varchar(200),
	initials varchar(20) NOT NULL,
	last_name varchar(200) NOT NULL,
	birthdate date NOT NULL,
	phonenumber varchar(15),
	postalcode varchar(10),
	housenumber varchar(10),
	housenumber_suffix varchar(10),
	streetname varchar(200),
	city varchar(200),
	province varchar(100),
	country varchar(100),
	last_payment_date date NOT NULL,
	verified_email boolean NOT NULL DEFAULT false,
	verified_identity boolean NOT NULL DEFAULT false,
	verified_voting_entitlement boolean NOT NULL DEFAULT false,
	CONSTRAINT accounts_pk PRIMARY KEY (id),
	CONSTRAINT accounts_uq_email UNIQUE (email)

);
-- ddl-end --
COMMENT ON COLUMN members.accounts.first_names IS 'Separated by space';
-- ddl-end --
COMMENT ON COLUMN members.accounts.initials IS 'Initials, no separation signs';
-- ddl-end --
COMMENT ON COLUMN members.accounts.last_name IS 'Includes prefix';
-- ddl-end --
ALTER TABLE members.accounts OWNER TO postgres;
-- ddl-end --

-- Appended SQL commands --
CREATE OR REPLACE FUNCTION is_adult(members.accounts) RETURNS boolean AS $$
	SELECT date_part('year', age($1.birthdate)) >= 18
$$ VOLATILE LANGUAGE SQL;
-- ddl-end --

INSERT INTO members.accounts (id, email, nickname, given_name, first_names, initials, last_name, birthdate, phonenumber, postalcode, housenumber, housenumber_suffix, streetname, city, province, country, last_payment_date, verified_email, verified_identity, verified_voting_entitlement) VALUES (E'1', E'geertjohan@geertjohan.net', E'GeertJohan', E'Geert-Johan', E'Geert Johan', E'GJ', E'Riemer', E'01-01-1990', E'31612345678', E'1234AB', E'10', E'A', E'Somestreet', E'Peilstad', E'Noord-Holland', E'Nederland', E'2017-01-01', E'f', E'f', E'f');
-- ddl-end --

-- object: members.accounts_fn_lock_identity | type: FUNCTION --
-- DROP FUNCTION IF EXISTS members.accounts_fn_lock_identity() CASCADE;
CREATE FUNCTION members.accounts_fn_lock_identity ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
DECLARE
	item_dimension_id integer;
	image_dimension_id integer;
BEGIN
	IF OLD.verified_identity AND NOT NEW.verified_identity THEN 
		RAISE EXCEPTION 'Cannot undo verified identity';
	END IF;
	IF OLD.verified_identity THEN
		IF OLD.initials != NEW.initials THEN
			RAISE EXCEPTION 'Cannot change initials when identity is verified';
		END IF;
		IF OLD.last_name != NEW.last_name THEN
			RAISE EXCEPTION 'Cannot change last_name when identity is verified';
		END IF;
		IF OLD.birthdate != NEW.birthdate THEN
			RAISE EXCEPTION 'Cannot change birthdate when identity is verified';
		END IF;
	END IF;
	RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION members.accounts_fn_lock_identity() OWNER TO postgres;
-- ddl-end --

-- object: accounts_tr_lock_identity | type: TRIGGER --
-- accounts_tr_lock_identity ON members.accounts CASCADE;
CREATE CONSTRAINT TRIGGER accounts_tr_lock_identity
	AFTER UPDATE
	ON members.accounts
	NOT DEFERRABLE 
	FOR EACH ROW
	EXECUTE PROCEDURE members.accounts_fn_lock_identity();
-- ddl-end --

-- object: members.sessions | type: TABLE --
-- DROP TABLE IF EXISTS members.sessions CASCADE;
CREATE TABLE members.sessions(
	id serial NOT NULL,
	account_id integer NOT NULL,
	token varchar(200) NOT NULL,
	timeout timestamp NOT NULL DEFAULT NOW(),
	CONSTRAINT sessions_pk PRIMARY KEY (id)

);
-- ddl-end --
ALTER TABLE members.sessions OWNER TO postgres;
-- ddl-end --

-- object: members.entitlement_proofs | type: TABLE --
-- DROP TABLE IF EXISTS members.entitlement_proofs CASCADE;
CREATE TABLE members.entitlement_proofs(
	id serial NOT NULL,
	account_id integer NOT NULL,
	filename varchar(100) NOT NULL,
	original_filename varchar(200) NOT NULL,
	CONSTRAINT entitlement_proofs_pk PRIMARY KEY (id),
	CONSTRAINT entitlement_proofs_uq_filename UNIQUE (filename)

);
-- ddl-end --
ALTER TABLE members.entitlement_proofs OWNER TO postgres;
-- ddl-end --

-- object: sessions_fk_account | type: CONSTRAINT --
-- ALTER TABLE members.sessions DROP CONSTRAINT IF EXISTS sessions_fk_account CASCADE;
ALTER TABLE members.sessions ADD CONSTRAINT sessions_fk_account FOREIGN KEY (account_id)
REFERENCES members.accounts (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: entitlement_proofs_fk_account | type: CONSTRAINT --
-- ALTER TABLE members.entitlement_proofs DROP CONSTRAINT IF EXISTS entitlement_proofs_fk_account CASCADE;
ALTER TABLE members.entitlement_proofs ADD CONSTRAINT entitlement_proofs_fk_account FOREIGN KEY (account_id)
REFERENCES members.accounts (id) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --


