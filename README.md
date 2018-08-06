# Postgres Benchmark Trigger

## Purpose & Description
This is a benchmark to verify if we can improve one specific trigger in our postgres DB.
The trigger is used to distribute recorts to various child tables (split by calendar week).

## Current Solution

We currently have a trigger in this form:

````sql
CREATE FUNCTION test_trigger() 
  RETURNS trigger AS $trigger$ 
BEGIN 
  IF (NEW.ts >= timestamp '2015-01-19'::date AND NEW.ts < timestamp '2015-01-26'::date) THEN 
    INSERT /* inner query */ INTO messages_2015_04 VALUES (NEW.*); 
  IF (NEW.ts >= timestamp '2015-01-26'::date AND NEW.ts < timestamp '2015-02-02'::date) THEN 
    INSERT /* inner query */ INTO messages_2015_05 VALUES (NEW.*); 
  IF (NEW.ts >= timestamp '2015-02-02'::date AND NEW.ts < timestamp '2015-02-09'::date) THEN 
    INSERT /* inner query */ INTO messages_2015_06 VALUES (NEW.*); 
-- ...
  ELSE 
    INSERT /* inner query */ INTO messages VALUES (NEW.*); 
  END IF; 
  RETURN NULL; 
END; $trigger$ 
LANGUAGE plpgsql;
````

This is one mayor contributor for our insert performance, because with every insert we execute a lot of `IF` statements and usually we insert records with a current timestamp. 
Therefore we will traverse almost all `IF` statements in this trigger, before actually inserting a row.

## Approach
Since we mostly insert with current timestamps the order of the `IF` statements could be reversed. 
The best case however would be, if there was a dynamic approach, where we have a constant time lookup for the table.

The reverse order approach is implemented in `sql/create_trigger_reverse_ordered.sql`.
The logical selection approach is implemented in `sql/create_trigger_logical.sql` and an alternative in `sql/create_trigger_logical2.sql`.

The benchmark is done in a VM on my laptop, so the results are not 100% exact and reproducible, but the order of magnitue should be comparable.

# Results

| implementation	| current inserts  	| time per insert   | max insert time   | historic inserts  | time per insert  	| max insert time   |
|---	            |---	            |---	            |---                |---	            |---	            |---                |
| default	        | 98067 ms          | 0.980 ms          | 9.713 ms          | 47382 ms  	    | 0.483 ms          | 2.890 ms          |
| reverse  	        |  4105 ms 	        | 0.041 ms          | 1.872 ms	        | 48440 ms  	    | 0.493 ms  	    | 9.614 ms          |
| logical  	        |  2699 ms          | 0.026 ms          | 1.146 ms          |  2764 ms 	        | 0.028 ms         	| 1.154 ms          |
| logical2 	        |  2586 ms 	        | 0.025 ms          | 0.898 ms          |  2579 ms          | 0.026 ms         	| 1.045 ms    	    |

We see that the current implementation is especially bad for inserts with current timestamps. `IF` performs a bit better, if we use historical timestamps.
The reverse implementation is already much better for current timestamps, but degrades quickly for historical timestamps.
The logical implementation shows almost constant runtime and superior performance in all testcases.

# Replication
Start your VM with `vagrant up`
Benchmarks can be executed with `ansible-playbook /vagrant/playbooks/benchmark.yml -e trigger_type=<type>` (trigger_type can be: `default_ordered`, `reverse_ordered`, `logical`, `logical2`) 
