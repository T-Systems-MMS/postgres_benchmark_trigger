CREATE OR REPLACE FUNCTION create_trigger()
  RETURNS VOID AS $$
DECLARE
  createtable  RECORD;
  stmt        VARCHAR;
BEGIN
  stmt:= '';
  FOR createtable IN
  SELECT to_char(dd::date, 'YYYY_WW') as datestring,
    date_trunc('week', dd)::date as datestart,
    (date_trunc('week', dd) + '7 days'::interval)::date as dateend
  FROM generate_series
        ( '2014-02-01'::timestamp
        , '2018-10-01'::timestamp
        , '1 week'::interval) dd
  LOOP
    stmt := stmt || 'IF (NEW.ts >= timestamp ''' || createtable.datestart || ''' AND NEW.ts < timestamp ''' || createtable.dateend || ''') THEN INSERT INTO messages_' || createtable.datestring || ' VALUES (NEW.*); ELS';
  END LOOP;
  stmt := 'CREATE FUNCTION test_trigger() RETURNS trigger AS $trigger$ BEGIN ' || stmt || 'E INSERT INTO messages VALUES (NEW.*); END IF; RETURN NULL; END; $trigger$ LANGUAGE plpgsql;';
  EXECUTE stmt;
END;
$$
LANGUAGE plpgsql;

SELECT create_trigger();
CREATE TRIGGER test_trigger
  BEFORE INSERT
  ON messages
  FOR EACH ROW EXECUTE PROCEDURE test_trigger();

DROP FUNCTION IF EXISTS create_trigger();