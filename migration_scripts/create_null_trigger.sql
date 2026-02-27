CREATE OR REPLACE FUNCTION auth.ensure_no_null_tokens()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.confirmation_token IS NULL THEN
    NEW.confirmation_token := '';
  END IF;
  IF NEW.recovery_token IS NULL THEN
    NEW.recovery_token := '';
  END IF;
  IF NEW.email_change_token_new IS NULL THEN
    NEW.email_change_token_new := '';
  END IF;
  IF NEW.email_change_token_current IS NULL THEN
    NEW.email_change_token_current := '';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ensure_no_null_tokens_trigger ON auth.users;

CREATE TRIGGER ensure_no_null_tokens_trigger
BEFORE INSERT OR UPDATE ON auth.users
FOR EACH ROW
EXECUTE FUNCTION auth.ensure_no_null_tokens();
