-- =====================================================================
-- Relatório de Serviços CSN | Prime Soluções Ambientais
-- Script de configuração do banco (Supabase)
-- Cole TODO este arquivo em: Supabase > SQL Editor > New query > Run
-- Pode ser executado mais de uma vez sem problema.
-- =====================================================================

-- 1) Tabelas ------------------------------------------------------------

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create table if not exists public.areas (
  tipo   text not null default 'LF',
  numero text not null,
  nome   text not null
);

-- áreas identificadas por tipo: LF (linha férrea) ou SE (subestação)
alter table public.areas add column if not exists tipo text not null default 'LF';
do $$
begin
  if exists (select 1 from pg_constraint where conname = 'areas_pkey' and conrelid = 'public.areas'::regclass) then
    alter table public.areas drop constraint areas_pkey;
  end if;
  alter table public.areas add constraint areas_pkey primary key (tipo, numero);
  if not exists (select 1 from pg_constraint where conname = 'areas_tipo_chk' and conrelid = 'public.areas'::regclass) then
    alter table public.areas add constraint areas_tipo_chk check (tipo in ('LF', 'SE'));
  end if;
end $$;

create table if not exists public.registros (
  id          uuid primary key default gen_random_uuid(),
  criado_em   timestamptz not null default now(),
  autor       uuid not null default auth.uid() references auth.users(id),
  autor_nome  text,
  data        date not null,
  os          text not null,
  area_numero text not null,
  area_nome   text not null,
  foto_path   text not null,
  observacao  text,
  conferido   boolean not null default false
);

alter table public.registros add column if not exists area_tipo text not null default 'LF';
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'registros_tipo_chk' and conrelid = 'public.registros'::regclass) then
    alter table public.registros add constraint registros_tipo_chk check (area_tipo in ('LF', 'SE'));
  end if;
end $$;

-- status da área: percentual concluído (10 a 100)
alter table public.registros add column if not exists status_pct smallint;
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'registros_status_chk' and conrelid = 'public.registros'::regclass) then
    alter table public.registros add constraint registros_status_chk check (status_pct between 10 and 100);
  end if;
end $$;

-- tipo de serviço executado
alter table public.registros add column if not exists servico text;
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'registros_servico_chk' and conrelid = 'public.registros'::regclass) then
    alter table public.registros add constraint registros_servico_chk check (servico in ('Capina química', 'Roçada mecanizada'));
  end if;
end $$;

create index if not exists registros_data_idx on public.registros (data);

-- 2) Quem é administrador -----------------------------------------------

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

grant execute on function public.is_admin() to authenticated;

-- 3) Regras de acesso (Row Level Security) ------------------------------

alter table public.admins    enable row level security;
alter table public.areas     enable row level security;
alter table public.registros enable row level security;

drop policy if exists "admins: ver o proprio" on public.admins;
create policy "admins: ver o proprio" on public.admins
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "areas: todos leem" on public.areas;
create policy "areas: todos leem" on public.areas
  for select to authenticated using (true);

drop policy if exists "areas: admin altera" on public.areas;
create policy "areas: admin altera" on public.areas
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "registros: inserir os proprios" on public.registros;
create policy "registros: inserir os proprios" on public.registros
  for insert to authenticated with check (autor = auth.uid());

drop policy if exists "registros: ver os proprios ou admin" on public.registros;
create policy "registros: ver os proprios ou admin" on public.registros
  for select to authenticated using (autor = auth.uid() or public.is_admin());

drop policy if exists "registros: admin altera" on public.registros;
create policy "registros: admin altera" on public.registros
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "registros: excluir" on public.registros;
create policy "registros: excluir" on public.registros
  for delete to authenticated
  using (public.is_admin() or (autor = auth.uid() and conferido = false));

-- 4) Armazenamento das fotos (bucket privado) ---------------------------

insert into storage.buckets (id, name, public)
values ('fotos', 'fotos', false)
on conflict (id) do nothing;

drop policy if exists "fotos: enviar na propria pasta" on storage.objects;
create policy "fotos: enviar na propria pasta" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "fotos: ver as proprias ou admin" on storage.objects;
create policy "fotos: ver as proprias ou admin" on storage.objects
  for select to authenticated
  using (bucket_id = 'fotos' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

drop policy if exists "fotos: excluir" on storage.objects;
create policy "fotos: excluir" on storage.objects
  for delete to authenticated
  using (bucket_id = 'fotos' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- 5) Cadastro de áreas (escopo CSN) -----------------------------------
-- 72 linhas férreas (LF-1 a LF-72) e 11 subestações (SE-1 a SE-11).
-- O colaborador escolhe a área numa lista; nomes podem ser corrigidos
-- pelo administrador na aba "Áreas". Rodar o script de novo NÃO
-- sobrescreve nomes já corrigidos.

insert into public.areas (tipo, numero, nome) values
  ('LF', '1', 'Pátio de carvão vagão carregado'),
  ('LF', '2', 'Pátio de carvão vagão vazio'),
  ('LF', '3', 'Oficina'),
  ('LF', '4', 'Beira Rio'),
  ('LF', '5', 'PPS'),
  ('LF', '6', 'RA- Pátio de formação de tabela'),
  ('LF', '7', 'Corredor Volta Grande - Santo Agostinho V. Americana'),
  ('LF', '8', 'Linha 2 nova'),
  ('LF', '9', 'Linha 9'),
  ('LF', '10', 'Fábrica de cimentos até D-3'),
  ('LF', '11', '12 longo'),
  ('LF', '12', 'Pátio do Volta Grande'),
  ('LF', '13', 'Desvio da URA'),
  ('LF', '14', '12 morto'),
  ('LF', '15', 'Pátio da gusa máquina moldar gusa'),
  ('LF', '16', 'Pátio leste GIL e BC'),
  ('LF', '17', 'Pátio de minério vagões vazios'),
  ('LF', '18', 'Pátio de minério vagões carregados'),
  ('LF', '19', 'Anexo'),
  ('LF', '20', 'EE-06'),
  ('LF', '21', 'Aços longos até o PMS'),
  ('LF', '22', 'EE-08'),
  ('LF', '23', 'Quebrador até o 3º desvio'),
  ('LF', '24', 'Linha interna - calcinação fábrica de cal'),
  ('LF', '25', 'Linha sul'),
  ('LF', '26', 'Decantação'),
  ('LF', '27', 'Pátio de placas em frente ao GSM'),
  ('LF', '28', 'Cantina'),
  ('LF', '29', 'Linha 20 viaduto leste até o Kish-Pitt'),
  ('LF', '30', 'Linha do 3° desvio CTE#2 e U-21'),
  ('LF', '31', 'Linha do Palácio de Vidro W-24'),
  ('LF', '32', 'KM'),
  ('LF', '33', 'Reta da fábrica de cal'),
  ('LF', '34', 'Pontes cavaletes pátio R4 (W-24)'),
  ('LF', '35', 'Linha 54 Pátio leste'),
  ('LF', '36', 'Linhas 53 Pátio leste'),
  ('LF', '37', 'AF#3 centro de vivência do central'),
  ('LF', '38', 'Área de armazenamento do truques (oficina)'),
  ('LF', '39', 'Centro de vivência oeste'),
  ('LF', '40', 'Reta do AF#2'),
  ('LF', '41', 'Linha 40'),
  ('LF', '42', 'Estação de gusa'),
  ('LF', '43', 'Centro de vivência leste'),
  ('LF', '44', 'Pátio da D#3'),
  ('LF', '45', 'D#3 até travessia da águas cruas'),
  ('LF', '46', 'Linha da ilha'),
  ('LF', '47', 'Linha da torre'),
  ('LF', '48', 'Pátio de manobras oeste'),
  ('LF', '49', 'PMS (pátio de vazios/carregados)'),
  ('LF', '50', 'Reta do EE-01'),
  ('LF', '51', 'Gasômetro'),
  ('LF', '52', 'Rouparia'),
  ('LF', '53', 'Transporte de coque'),
  ('LF', '54', 'Pátio 1'),
  ('LF', '55', 'Em frente a sala da maquininha'),
  ('LF', '56', 'EE-07'),
  ('LF', '57', 'EE-03'),
  ('LF', '58', 'Rua I-28 linha 10'),
  ('LF', '59', 'EE-11'),
  ('LF', '60', 'EE-10'),
  ('LF', '61', 'Traíra'),
  ('LF', '62', 'Oficina de lança'),
  ('LF', '63', 'PMP'),
  ('LF', '64', 'Tupi'),
  ('LF', '65', 'Linha da limpeza'),
  ('LF', '66', 'Depósito de combustível'),
  ('LF', '67', 'Borrifo'),
  ('LF', '68', 'Desvio da fábrica de cimentos'),
  ('LF', '69', 'Sobremetal'),
  ('LF', '70', 'PIC'),
  ('LF', '71', 'Forno de poço'),
  ('LF', '72', '1ª cobertura'),
  ('SE', '1', 'Subestação Sul'),
  ('SE', '2', 'Subestação Leste'),
  ('SE', '3', 'Subestação Sudeste'),
  ('SE', '4', 'Subestação Norte'),
  ('SE', '5', 'Subestação Moto soprador e Trafo ao lado'),
  ('SE', '6', 'Trafos 10BAT / 20BAT CTE – 2'),
  ('SE', '7', 'Trafo CBGCO - Posto de Gás'),
  ('SE', '8', 'Trafo CCL - ao lado da conversora de frequência'),
  ('SE', '9', 'Trafo ECA – 2'),
  ('SE', '10', 'Trafo ECA – 3'),
  ('SE', '11', 'Trafo ETE/LTQ 2')
on conflict (tipo, numero) do nothing;

-- 6) Tornar um usuário administrador -----------------------------------
-- Depois de criar o usuário em Authentication > Users, troque o e-mail
-- abaixo pelo e-mail do administrador, selecione SÓ as linhas abaixo
-- e clique em Run:
--
-- insert into public.admins (user_id)
-- select id from auth.users where email = 'admin@suaempresa.com.br'
-- on conflict do nothing;
