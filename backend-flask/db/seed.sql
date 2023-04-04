-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Carlos Rivero','rodrorivero@gmail.com', 'carlos_r' ,'c79e4b78-27a2-48c0-86ad-c4c28dd1a0b4'),
  ('Andrew Bayko','bayko@exampro.com', 'bayko' ,'MOCK');

SELECT * FROM public.users;

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'carlos_r' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  );

  SELECT * FROM public.activities;