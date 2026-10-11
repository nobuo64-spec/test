-- =====================================================
-- ご意見掲示板 (board_posts) テーブル作成 SQL
-- Supabase の SQL Editor に貼り付けて実行してください
-- =====================================================

-- 1. テーブル作成
create table if not exists public.board_posts (
  id         bigint generated always as identity primary key,
  name       text        not null check (char_length(btrim(name)) between 1 and 20),   -- ニックネーム（最大20文字）
  message    text        not null check (char_length(btrim(message)) between 1 and 300), -- ご意見（最大300文字）
  created_at timestamptz not null default now()                                         -- 投稿日時
);

comment on table  public.board_posts            is 'ご意見掲示板の投稿';
comment on column public.board_posts.name       is 'ニックネーム（1〜20文字）';
comment on column public.board_posts.message    is 'ご意見（1〜300文字）';
comment on column public.board_posts.created_at is '投稿日時';

-- 新しい順の表示を高速化
create index if not exists board_posts_created_at_idx
  on public.board_posts (created_at desc);

-- 2. RLS（行レベルセキュリティ）を有効化
alter table public.board_posts enable row level security;

-- 3. ポリシー
--    ログイン不要の掲示板のため、匿名(anon)・ログイン済(authenticated)ともに
--    「閲覧」と「投稿」のみ許可。更新・削除のポリシーは作らない = 拒否（管理者は
--    Supabase ダッシュボード / service_role で削除）。

-- 閲覧：誰でも可
drop policy if exists "board_posts_select_all" on public.board_posts;
create policy "board_posts_select_all"
  on public.board_posts
  for select
  to anon, authenticated
  using (true);

-- 投稿：誰でも可（文字数は CHECK 制約でも担保）
drop policy if exists "board_posts_insert_all" on public.board_posts;
create policy "board_posts_insert_all"
  on public.board_posts
  for insert
  to anon, authenticated
  with check (
    char_length(btrim(name))    between 1 and 20
    and char_length(btrim(message)) between 1 and 300
  );

-- 4. ダミーデータ（SQL Editor は postgres 権限で実行されるため RLS の影響を受けません）
insert into public.board_posts (name, message, created_at) values
  ('たろう',     '無料体験を受けました！フォームの説明が動画で分かりやすく、息子も楽しそうでした。', now() - interval '3 days'),
  ('ゆうママ',   '雨の日の振替対応が丁寧で助かっています。これからもお願いします。',                 now() - interval '2 days'),
  ('野球好きおじさん', '草野球でも通えるのが嬉しいです。ビジョントレーニングも気になります！',       now() - interval '1 day'),
  ('ハルト',     'ピッチングのフォームが安定して球速が3km/hアップしました！',                       now() - interval '2 hours');
