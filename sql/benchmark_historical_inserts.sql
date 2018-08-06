CREATE OR REPLACE FUNCTION benchmark_current_insert()
  RETURNS VOID AS $$
DECLARE
  counter timestamp;
BEGIN
  FOR counter IN SELECT i FROM generate_series
        ( '2014-02-01'::timestamp
        , '2018-10-01'::timestamp
        , '25 minutes'::interval) AS i
  LOOP
    INSERT /* outer query */ INTO messages (ts, pl) SELECT counter, 0;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

select pg_stat_statements_reset();

SELECT benchmark_current_insert();

DROP FUNCTION IF EXISTS benchmark_current_insert();
