CREATE OR REPLACE FUNCTION benchmark_current_insert()
  RETURNS VOID AS $$
DECLARE
  counter int;
BEGIN
  FOR counter IN SELECT i FROM generate_Series(1,100000) AS i
  LOOP
    INSERT /* outer query */ INTO messages (ts, pl) SELECT now(), 0;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

select pg_stat_statements_reset();

SELECT benchmark_current_insert();

DROP FUNCTION IF EXISTS benchmark_current_insert();
