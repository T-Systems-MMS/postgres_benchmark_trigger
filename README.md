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
...
  ELSE 
    INSERT /* inner query */ INTO messages VALUES (NEW.*); 
  END IF; 
  RETURN NULL; 
END; $trigger$ 
LANGUAGE plpgsql;';
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

| implementation	| current inserts  	| time per insert  	| historic inserts  	| time per insert  	|
|---	            |---	            |---	            |---	                |---	            |
| default	        | 96837 ms          | 0.96 ms           | 48722 ms  	        | 0.49 ms  	        |
| reverse  	        |  4210 ms 	        | 0.04 ms       	| 50589 ms  	        | 0.51 ms  	        |
| logical  	        |  2747 ms          | 0.02 ms           |  2732 ms 	            | 0.02 ms         	|
| logical2 	        |  2640 ms 	        | 0.02 ms           |  2657 ms           	| 0.02 ms         	|

We see that the current implementation is especially bad for inserts with current timestamps. `IF` performs a bit better, if we use historical timestamps.
The reverse implementation is already much better for current timestamps, but degrades quickly for historical timestamps.
The logical implementation shows almost constant runtime and superior performance in all testcases.

# Replication
Start your VM with `vagrant up`
Benchmarks can be executed with `ansible-playbook /vagrant/playbooks/benchmark.yml -e trigger_type=<type>` (trigger_type can be: `default_ordered`, `reverse_ordered`, `logical`, `logical2`) 
