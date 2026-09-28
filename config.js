// Configuração do Relatório de Serviços
// Preencha com os dados do seu projeto no Supabase:
// Supabase > Project Settings > API (ou "Data API")
//   Project URL          -> SUPABASE_URL
//   anon public (chave)  -> SUPABASE_ANON_KEY
// A chave "anon public" pode ficar no GitHub: quem protege os dados são as
// regras de acesso criadas pelo arquivo supabase/setup.sql.
// NUNCA coloque aqui a chave "service_role".

window.RELATORIO_CONFIG = {
  SUPABASE_URL: "https://bmbrhudnaqaxvwwqytyr.supabase.co/rest/v1/",
  SUPABASE_ANON_KEY: "sb_publishable_Q7kPOFYMsNuovU-mE7jj8A_zPR9NqEr",

  // Textos do relatório
  CLIENTE: "CSN",
  SERVICO: "Saneamento Vegetal",
  EMPRESA: "Prime Soluções Ambientais"
};
