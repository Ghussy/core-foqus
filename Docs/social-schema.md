# 📊 Schema Overview (updated)

| Table                     | Purpose                                             | Key Columns                                                                          |
| ------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **profiles**              | User profiles                                       | `id`, `username`, `avatar_url`, `updated_at`                                         |
| **friendships**           | Friend relationships                                | `id`, `user_id`, `friend_id`, `status`, `created_at`, `updated_at`                   |
| **profile_identities**    | Verified identifier hashes                          | `profile_id`, `kind`, `hash_hex`, `verified`                                         |
| **user_contacts**         | Caller’s uploaded contact hashes                    | `owner_id`, `kind`, `hash_hex`                                                       |
| **skills**                | User created skills mirrored from client “profiles” | `id` (UUID from device), `owner_id`, `name`, `created_at`, `updated_at`              |
| **skill_streak_counters** | Compact per-skill rolling streaks                   | `user_id`, `skill_id`, `current`, `best`, `last_local_date`, `updated_at`, `privacy` |

# 🔐 Row-Level Security (updated)

| Action                              | Who                                                             | Table |
| ----------------------------------- | --------------------------------------------------------------- | ----- |
| SELECT skills                       | Owner only                                                      |       |
| INSERT/UPDATE/DELETE skills         | Owner only                                                      |       |
| SELECT skill_streak_counters        | Owner and accepted friends if `privacy in ('public','friends')` |       |
| INSERT/UPDATE skill_streak_counters | RPC only. No direct client writes                               |       |

# DDL

```sql
-- 1) Skills

create table if not exists public.skills (
  id uuid primary key,                               -- same UUID as your local BlockedProfiles.id
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.skills enable row level security;

create policy skills_owner_select
on public.skills for select
using (auth.uid() = owner_id);

create policy skills_owner_write
on public.skills for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

-- 2) Per-skill rolling streak counters

create table if not exists public.skill_streak_counters (
  user_id uuid not null references public.profiles(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  current int not null default 0,
  best int not null default 0,
  last_local_date date,
  updated_at timestamptz not null default now(),
  privacy text not null default 'friends' check (privacy in ('public','friends','private')),
  primary key (user_id, skill_id)
);

alter table public.skill_streak_counters enable row level security;

create policy streak_self_read
on public.skill_streak_counters for select
using (auth.uid() = user_id);

create policy streak_friends_read
on public.skill_streak_counters for select
using (
  privacy in ('public','friends')
  and is_accepted_friend(auth.uid(), user_id)
);

-- Do not allow direct writes. Only via RPC.
create policy streak_no_direct_write
on public.skill_streak_counters for all
using (false) with check (false);
```

# 🧩 RPCs (updated)

Add these to your existing RPC list.

| Function                                                                     | Purpose                                                                                                         |
| ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `upsert_skill(p_id uuid, p_name text)`                                       | Mirror local skill id and name on the server. Idempotent.                                                       |
| `mark_skill_session_complete(p_skill_id uuid, p_tz text, p_now timestamptz)` | Increment or reset the rolling streak for that skill based on local day. Returns `{current, best, local_date}`. |
| `top_friend_streaks_for_skill(skill uuid, limit_n int)`                      | Leaderboard among accepted friends for a single skill.                                                          |

```sql
-- A) Upsert skill shell

create or replace function public.upsert_skill(
  p_id uuid,
  p_name text
) returns void
language sql
security definer
as $$
  insert into public.skills(id, owner_id, name)
  values (p_id, auth.uid(), p_name)
  on conflict (id) do update
    set name = excluded.name,
        updated_at = now();
$$;

-- B) Rolling streak update without storing daily facts

create or replace function public.mark_skill_session_complete(
  p_skill_id uuid,
  p_tz text default 'America/Denver',
  p_now timestamptz default now()
) returns table(current int, best int, local_date date)
language plpgsql
security definer
as $$
declare
  uid uuid := auth.uid();
  ld date := (timezone(p_tz, p_now))::date;
  prev date;
  cur int;
  bst int;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1 from public.skills s
    where s.id = p_skill_id and s.owner_id = uid
  ) then
    raise exception 'Skill not found or not owned by user';
  end if;

  select last_local_date, current, best
  into prev, cur, bst
  from public.skill_streak_counters
  where user_id = uid and skill_id = p_skill_id
  for update;

  if not found then
    cur := 1; bst := 1;
    insert into public.skill_streak_counters(user_id, skill_id, current, best, last_local_date)
    values (uid, p_skill_id, cur, bst, ld);
  else
    if prev = ld then
      -- already counted today
    elsif prev = ld - 1 then
      cur := cur + 1;
      if cur > bst then bst := cur; end if;
      update public.skill_streak_counters
        set current = cur, best = bst, last_local_date = ld, updated_at = now()
      where user_id = uid and skill_id = p_skill_id;
    else
      cur := 1;
      if bst is null or bst < 1 then bst := 1; end if;
      update public.skill_streak_counters
        set current = cur, best = greatest(bst, cur), last_local_date = ld, updated_at = now()
      where user_id = uid and skill_id = p_skill_id;
    end if;
  end if;

  return query select cur, bst, ld;
end $$;

-- C) Friends leaderboard for one skill

create or replace function public.top_friend_streaks_for_skill(
  skill uuid,
  limit_n int default 20
) returns table(user_id uuid, username text, current int, best int)
language sql
security definer
stable
as $$
  select s.user_id, p.username, s.current, s.best
  from public.skill_streak_counters s
  join public.profiles p on p.id = s.user_id
  where s.skill_id = skill
    and is_accepted_friend(auth.uid(), s.user_id)
    and s.privacy in ('public','friends')
  order by s.current desc, s.best desc, s.updated_at desc
  limit limit_n
$$;
```

# 👥 Friends view

```sql
create or replace view public.friend_skill_streaks as
select s.user_id, s.skill_id, s.current, s.best, s.last_local_date, s.updated_at,
       prof.username, prof.avatar_url,
       sk.name as skill_name
from public.skill_streak_counters s
join public.profiles prof on prof.id = s.user_id
join public.skills sk on sk.id = s.skill_id;
-- RLS on skill_streak_counters protects access
```

# 💻 Swift touch points

Call these from your existing code paths.

```swift
// 1) Mirror a local BlockedProfiles in Supabase whenever created or renamed
func syncSkill(profile: BlockedProfiles, client: SupabaseClient) async throws {
  try await client.rpc(fn: "upsert_skill", params: [
    "p_id": profile.id.uuidString,
    "p_name": profile.name
  ]).execute()
}

// 2) When a user completes a full session for that profile, bump the streak
struct StreakOut: Decodable { let current: Int; let best: Int; let local_date: String }

func markSessionComplete(profileId: UUID, client: SupabaseClient) async throws -> StreakOut {
  let tz = TimeZone.current.identifier
  let res: [StreakOut] = try await client
    .rpc(fn: "mark_skill_session_complete", params: [
      "p_skill_id": profileId.uuidString,
      "p_tz": tz
    ])
    .execute()
    .value
  return res.first!
}
```

Offline pattern remains simple. Queue the RPC call with the completion timestamp and pass it as `p_now` when you flush so the server derives the correct day.

# ⚖️ Why this is “right enough” for v1

- One authoritative counter per skill. No drift. A second tap on the same day is a no-op.
- Timezone safe. The server maps `p_now` to a local date using `p_tz`.
- Friends can read through RLS. Privacy is enforced at row level.
- You can add streak types later by adding a `kind text` to `skill_streak_counters` and branching logic inside the RPC without touching `skills` or Social.

If you want me to generate a single SQL migration file that adds these objects without touching your existing Social tables, say the word and I will output it ready to paste into Supabase SQL editor.
