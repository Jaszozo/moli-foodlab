-- ============================================================
-- 茉莉的美味 Lab · 建表脚本（只跑一次）
-- 复用现有 Supabase 项目，新增 3 张表（ml_ 前缀，与海房子分开）
-- Supabase → SQL Editor → New query → 粘贴运行
-- ============================================================

-- 菜谱库
create table if not exists ml_dishes (
  id     bigint generated always as identity primary key,
  name   text unique not null,
  cats   jsonb not null default '[]'::jsonb,   -- 类别(可多选): A/B/C
  method text default '',                       -- 做法(用于估卡路里)
  ing    jsonb not null default '[]'::jsonb     -- [{n,q,u,opt}] 4人份；opt=true 为"有就加"
);

-- 冰箱
create table if not exists ml_fridge (
  id    bigint generated always as identity primary key,
  name  text not null,
  qty   numeric not null default 1,           -- 数量（用 emoji 重复显示）
  unit  text not null default '个',
  added date not null default current_date
);

-- 明日两餐计划（单行）
create table if not exists ml_plan (
  id     int primary key default 1,
  people int not null default 4,
  lunch  jsonb not null default '{"cat":"A","dishes":[]}'::jsonb,
  dinner jsonb not null default '{"cat":"C","dishes":[]}'::jsonb,
  tasks  jsonb not null default '{}'::jsonb,
  constraint ml_single check (id = 1)
);
-- 已建过表的，补这一列即可：
alter table ml_plan add column if not exists tasks jsonb not null default '{}'::jsonb;
insert into ml_plan (id) values (1) on conflict (id) do nothing;

-- 行级安全 + 公开 key 读写（单家庭共享、无登录）
alter table ml_dishes enable row level security;
alter table ml_fridge enable row level security;
alter table ml_plan   enable row level security;
drop policy if exists "pub_ml_dishes" on ml_dishes;
drop policy if exists "pub_ml_fridge" on ml_fridge;
drop policy if exists "pub_ml_plan"   on ml_plan;
create policy "pub_ml_dishes" on ml_dishes for all using (true) with check (true);
create policy "pub_ml_fridge" on ml_fridge for all using (true) with check (true);
create policy "pub_ml_plan"   on ml_plan   for all using (true) with check (true);

-- 实时同步
do $$
begin
  begin alter publication supabase_realtime add table ml_dishes; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table ml_fridge; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table ml_plan;   exception when duplicate_object then null; end;
end $$;

-- 完成。回网页点"🌱 载入茉莉的菜谱"灌入 10 道菜。
