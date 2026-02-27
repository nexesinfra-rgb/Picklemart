SELECT 
    event_object_schema as table_schema,
    event_object_table as table_name,
    trigger_name,
    action_orientation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

-- Also check for public.users/profiles triggers if any
SELECT 
    event_object_schema as table_schema,
    event_object_table as table_name,
    trigger_name,
    action_orientation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table IN ('users', 'profiles')
AND event_object_schema = 'public';
