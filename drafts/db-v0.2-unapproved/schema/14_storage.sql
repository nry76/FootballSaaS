-- =====================================================================
-- 14_storage.sql — Supabase Storage buckets + policies
--
-- Path convention (first two folders are checked by the policies):
--   {club_id}/{player_id | profile_id}/{filename}
-- All buckets are PRIVATE. Browsers get short-lived signed URLs only.
--   player-docs : Emirates ID, birth certificate, medical clearance ...
--   staff-docs  : licences, certificates, contracts
--   identity    : ID photo + selfie for verification. WRITE-ONLY for the uploader;
--                 only reviewers (members.approve) can read; purged by a job (service role).
--   media       : match photos / highlights, visible per media_assets rules
-- =====================================================================

create function private.try_uuid(p text) returns uuid
language plpgsql immutable as $$
begin return p::uuid; exception when others then return null; end $$;

insert into storage.buckets (id, name, public) values
  ('player-docs','player-docs',false), ('staff-docs','staff-docs',false),
  ('identity','identity',false),       ('media','media',false)
on conflict (id) do nothing;

-- ---- player-docs ----------------------------------------------------------
create policy "player-docs read" on storage.objects for select to authenticated
using (bucket_id = 'player-docs' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and ((select private.has_permission('players.docs'))
       or (select private.is_guardian_of(private.try_uuid((storage.foldername(name))[2])))
       or (select private.is_self_player(private.try_uuid((storage.foldername(name))[2])))));
create policy "player-docs insert" on storage.objects for insert to authenticated
with check (bucket_id = 'player-docs' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and private.is_processing_allowed(private.try_uuid((storage.foldername(name))[2]))
  and ((select private.has_permission('players.docs'))
       or (select private.is_guardian_of(private.try_uuid((storage.foldername(name))[2])))
       or (select private.is_self_player(private.try_uuid((storage.foldername(name))[2])))));
create policy "player-docs delete" on storage.objects for delete to authenticated
using (bucket_id = 'player-docs' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and (select private.has_permission('players.docs')));

-- ---- staff-docs -----------------------------------------------------------
create policy "staff-docs read" on storage.objects for select to authenticated
using (bucket_id = 'staff-docs' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and (private.try_uuid((storage.foldername(name))[2]) = (select auth.uid()) or (select private.has_permission('staff.docs'))));
create policy "staff-docs insert" on storage.objects for insert to authenticated
with check (bucket_id = 'staff-docs' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and (private.try_uuid((storage.foldername(name))[2]) = (select auth.uid()) or (select private.has_permission('staff.docs'))));
create policy "staff-docs delete" on storage.objects for delete to authenticated
using (bucket_id = 'staff-docs' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and (select private.has_permission('staff.docs')));

-- ---- identity (write-only for uploader) ----------------------------------------
create policy "identity insert" on storage.objects for insert to authenticated
with check (bucket_id = 'identity' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and (private.try_uuid((storage.foldername(name))[2]) = (select auth.uid())
       or ((select private.is_guardian_of(private.try_uuid((storage.foldername(name))[2]))) and private.is_processing_allowed(private.try_uuid((storage.foldername(name))[2])))
       or ((select private.is_self_player(private.try_uuid((storage.foldername(name))[2]))) and private.is_processing_allowed(private.try_uuid((storage.foldername(name))[2])))));
create policy "identity reviewers read" on storage.objects for select to authenticated
using (bucket_id = 'identity' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and (select private.has_permission('members.approve')));

-- ---- media (visibility inherited from media_assets RLS) ----------------------------
create policy "media read" on storage.objects for select to authenticated
using (bucket_id = 'media' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and exists (select 1 from public.media_assets a where a.storage_path = objects.name or a.thumbnail_path = objects.name));
create policy "media insert" on storage.objects for insert to authenticated
with check (bucket_id = 'media' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and ((select private.has_permission('media.moderate')) or (select private.has_role('coach'))));
create policy "media delete" on storage.objects for delete to authenticated
using (bucket_id = 'media' and private.try_uuid((storage.foldername(name))[1]) = (select private.current_club_id())
  and ((select private.has_permission('media.moderate')) or owner = (select auth.uid())));
