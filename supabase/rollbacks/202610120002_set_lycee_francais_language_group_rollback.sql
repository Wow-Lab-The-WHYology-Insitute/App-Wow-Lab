-- Rollback for 202610120002 -- returns both Lycee Francais groups to NULL.
--
-- Lossless: NULL is what they held before, and 202609240003 confirmed the
-- column was never written by any UI path (addGroup's payload never included
-- it, NewSessionForm never had a field for it), so there is no earlier value
-- to lose.
--
-- Scoped to 'ro_en' on purpose. If someone has since changed a group to
-- 'fr_de_es' through the edit form, that is a newer human decision and this
-- rollback leaves it alone rather than erasing it -- and the row count below
-- will say so.

do $$
declare
  v_updated int;
begin
  update public.groups g
     set language_group = null
    from public.clients c, public.organizations o
   where g.client_id = c.id
     and c.organization_id = o.id
     and o.slug = 'wow-lab'
     and c.name ilike '%Lycee Francais%'
     and g.language_group = 'ro_en';

  get diagnostics v_updated = row_count;
  raise notice 'Reverted % Lycee Francais group(s) to a NULL language_group.', v_updated;
end $$;
