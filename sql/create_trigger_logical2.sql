CREATE FUNCTION test_trigger()
  RETURNS trigger AS $trigger$
DECLARE
  tablename VARCHAR;
BEGIN
  tablename := concat('messages_',to_char(NEW.ts::date, 'YYYY_WW'));
  IF ( to_regclass(tablename) IS NOT NULL) THEN
    EXECUTE ' INSERT /* inner query */ INTO ' || tablename || ' VALUES ($1.*)' USING NEW;
   RETURN NULL;
  END IF;
  RETURN NEW;
END;
$trigger$
LANGUAGE plpgsql;

CREATE TRIGGER test_trigger
  BEFORE INSERT
  ON messages
  FOR EACH ROW EXECUTE PROCEDURE test_trigger();
