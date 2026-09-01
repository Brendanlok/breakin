-- 07-delete-bot-scores.sql
-- Remove the 16 bot scores Claude posted to the live leaderboard on 2026-09-01 at 00:25 UTC
-- while verifying the endless-rally fix. Authorised by Lok on 2026-09-01.
--
-- Run this in the Supabase SQL editor (project ekcnpuwclkjnqnntlvot).
-- It deletes by explicit row id, so it cannot match anything else by accident.
-- The genuine 'SHARP WASP' run (score 48, 2026-08-31 23:17 UTC) is NOT in this list and is kept.
--
-- The rows being removed, for the record:
--   2026-09-01 00:25:01  score 111  8f6e11d8-a8d1-496d-9789-700882202769
--   2026-09-01 00:25:01  score 117  77c4a872-78e0-46c8-b096-53be4cb451c9
--   2026-09-01 00:25:02  score 285  6e267811-00f9-4b1d-bcca-72023e39b702
--   2026-09-01 00:25:03  score 78   a838ff14-79ec-419a-86b3-a58fb19274ff
--   2026-09-01 00:25:04  score 156  c242cace-c156-4ded-93f2-c6faf0ed4720
--   2026-09-01 00:25:05  score 276  0f2766c4-5157-439f-ac7d-38f86cba4256
--   2026-09-01 00:25:06  score 123  64bc12c9-4cd5-4cde-86c1-9fab6e35835e
--   2026-09-01 00:25:07  score 129  af78ea7e-7dc2-495a-a7c5-65d03a3b5eda
--   2026-09-01 00:25:08  score 117  d80c3754-5f95-4c3b-b741-1c59b18fa3e7
--   2026-09-01 00:25:09  score 237  77eaa73c-7b37-4469-939b-a601c8de2f3b
--   2026-09-01 00:25:10  score 132  eb61dd3b-c23a-495b-b7d3-4bca1c759f20
--   2026-09-01 00:25:11  score 159  dc484a3e-f5ed-4596-afff-73b988120622
--   2026-09-01 00:25:23  score 129  dff4b4b8-4470-4b6e-837c-b80de823e45c
--   2026-09-01 00:25:23  score 147  afd3c3c1-fd99-4dfe-9f99-f0a0b9c9a299
--   2026-09-01 00:25:24  score 309  7cd23964-e0d5-427f-b557-16f663c119ab
--   2026-09-01 00:25:25  score 132  a1c2dc1c-706f-4603-a968-63009fe45190

-- 1. LOOK FIRST - this should return exactly these 16 rows and nothing else.
select id, name, score, secs, blocks, mult, created_at
from public.breakin_scores
where id in (
  '8f6e11d8-a8d1-496d-9789-700882202769',
  '77c4a872-78e0-46c8-b096-53be4cb451c9',
  '6e267811-00f9-4b1d-bcca-72023e39b702',
  'a838ff14-79ec-419a-86b3-a58fb19274ff',
  'c242cace-c156-4ded-93f2-c6faf0ed4720',
  '0f2766c4-5157-439f-ac7d-38f86cba4256',
  '64bc12c9-4cd5-4cde-86c1-9fab6e35835e',
  'af78ea7e-7dc2-495a-a7c5-65d03a3b5eda',
  'd80c3754-5f95-4c3b-b741-1c59b18fa3e7',
  '77eaa73c-7b37-4469-939b-a601c8de2f3b',
  'eb61dd3b-c23a-495b-b7d3-4bca1c759f20',
  'dc484a3e-f5ed-4596-afff-73b988120622',
  'dff4b4b8-4470-4b6e-837c-b80de823e45c',
  'afd3c3c1-fd99-4dfe-9f99-f0a0b9c9a299',
  '7cd23964-e0d5-427f-b557-16f663c119ab',
  'a1c2dc1c-706f-4603-a968-63009fe45190'
)
order by created_at;

-- 2. Then delete them.
delete from public.breakin_scores
where id in (
  '8f6e11d8-a8d1-496d-9789-700882202769',
  '77c4a872-78e0-46c8-b096-53be4cb451c9',
  '6e267811-00f9-4b1d-bcca-72023e39b702',
  'a838ff14-79ec-419a-86b3-a58fb19274ff',
  'c242cace-c156-4ded-93f2-c6faf0ed4720',
  '0f2766c4-5157-439f-ac7d-38f86cba4256',
  '64bc12c9-4cd5-4cde-86c1-9fab6e35835e',
  'af78ea7e-7dc2-495a-a7c5-65d03a3b5eda',
  'd80c3754-5f95-4c3b-b741-1c59b18fa3e7',
  '77eaa73c-7b37-4469-939b-a601c8de2f3b',
  'eb61dd3b-c23a-495b-b7d3-4bca1c759f20',
  'dc484a3e-f5ed-4596-afff-73b988120622',
  'dff4b4b8-4470-4b6e-837c-b80de823e45c',
  'afd3c3c1-fd99-4dfe-9f99-f0a0b9c9a299',
  '7cd23964-e0d5-427f-b557-16f663c119ab',
  'a1c2dc1c-706f-4603-a968-63009fe45190'
);

-- 3. Confirm: no 'SHARP WASP' rows should remain except the real 48.
select name, score, created_at
from public.breakin_scores
where name = 'SHARP WASP'
order by created_at;
