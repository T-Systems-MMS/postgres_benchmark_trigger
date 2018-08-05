CREATE OR REPLACE FUNCTION create_partition_tables()
  RETURNS VOID AS $$
DECLARE
  createtable  RECORD;
  stmt        VARCHAR;
BEGIN
  FOR createtable IN
  SELECT to_char(dd::date, 'YYYY_WW') as datestring
  FROM generate_series
        ( '2014-02-01'::timestamp
        , '2018-10-01'::timestamp
        , '1 week'::interval) dd
  LOOP
    stmt := 'CREATE TABLE IF NOT EXISTS messages_' || createtable.datestring || '() INHERITS (messages)';
    EXECUTE stmt;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

DROP TABLE IF EXISTS messages CASCADE;

CREATE TABLE IF NOT EXISTS messages( ts timestamp, pl int);
SELECT create_partition_tables();

DROP FUNCTION IF EXISTS create_partition_tables();
