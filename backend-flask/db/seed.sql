-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Carlos Rivero','rodroriveroe@gmail.com', 'carlos_r' ,'c79e4sd8-27a2-48c0-86ad-c4c28dd1a0b4'),
  ('Rodrigo Rivero','rodrigorivero@outlook.com', 'rodrigorivero' ,'f3526fb4-a352-4b94-9723-99c61948f908');
  ('Londo Mollari','lmollari@centari.com' ,'londo' ,'MOCK');
SELECT * FROM public.users;

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'carlos_r' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  );

  SELECT * FROM public.activities;