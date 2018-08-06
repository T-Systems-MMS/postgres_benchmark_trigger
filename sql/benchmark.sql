-- reset stats!
select pg_stat_statements_reset();

INSERT INTO messages (ts, pl) SELECT now(), i FROM generate_Series(1,10000) AS i;

-- output statistics
SELECT query, calls, total_time FROM pg_stat_statements WHERE query LIKE '%message%';

-- reset stats!
select pg_stat_statements_reset();
