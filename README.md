# Relatório de Serviços | Prime Soluções Ambientais

Ferramenta web para montar o relatório mensal de serviços do cliente:

- **Colaborador (no celular):** tira a foto, informa data e número da OS e escolhe a área numa lista com as 72 linhas férreas (**LF**) e as 11 subestações (**SE**).
- **Administrador (no computador):** no fim do mês, confere os registros, corrige o que for preciso e gera o relatório em PDF no modelo aprovado (capa, introdução, páginas de execução com 2 áreas cada e página de contatos).

A página fica hospedada no **GitHub Pages**. Os registros e as fotos ficam no **Supabase**, um banco de dados online com plano gratuito. O banco é necessário porque o celular de cada colaborador e o computador do administrador precisam enxergar os mesmos dados.

## Estrutura do repositório

```
index.html          a ferramenta
config.js           endereço e chave do banco (você preenche)
assets/             logos e páginas fixas do relatório
supabase/setup.sql  script que cria o banco, as regras de acesso e o cadastro de áreas
README.md           este guia
```

## Antes de configurar: teste a demonstração

Publique no GitHub (parte 2) e abra o endereço. Enquanto o `config.js` não estiver preenchido, a página oferece o botão **Ver a demonstração**, que simula o colaborador e o administrador sem salvar nada.

---

## Parte 1: criar o banco de dados (Supabase)

1. Acesse **supabase.com**, clique em **Start your project** e crie uma conta.
2. Clique em **New project**. Dê um nome (ex.: `relatorio-csn`), crie uma senha para o banco (guarde-a) e escolha a região **South America (São Paulo)**. Clique em **Create new project** e aguarde de 1 a 2 minutos.
3. No menu lateral, abra **SQL Editor**, clique em **New query**, cole **todo** o conteúdo do arquivo `supabase/setup.sql` e clique em **Run**. A mensagem deve ser *Success. No rows returned*.
4. **Crie os usuários.** No menu lateral, vá em **Authentication > Users > Add user > Create new user**. Informe e-mail e senha, marque **Auto Confirm User** e clique em **Create user**. Repita para cada colaborador e para o administrador.
5. **Defina quem é administrador.** Volte ao **SQL Editor**, cole o comando abaixo trocando o e-mail pelo do administrador e clique em **Run**:

   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'admin@suaempresa.com.br'
   on conflict do nothing;
   ```

   Repita o comando se houver mais de um administrador.
6. **Bloqueie cadastros abertos.** Em **Authentication > Sign In / Providers** (em algumas versões, **Authentication > Settings**), desligue **Allow new users to sign up**. Assim, só entra quem você cadastrou.
7. **Copie os dados de conexão.** Vá em **Project Settings > API** (ou **Data API**) e copie a **Project URL** e a chave **anon public** (em projetos novos pode aparecer como **publishable key**).
8. Abra o arquivo `config.js`, cole os dois valores entre as aspas e salve:

   ```js
   SUPABASE_URL: "https://xxxxxxxx.supabase.co",
   SUPABASE_ANON_KEY: "eyJhbGciOi...",
   ```

   A chave anon/publishable pode ficar pública no GitHub: quem protege os dados são as regras criadas pelo `setup.sql`. **Nunca** use a chave `service_role`.

## Parte 2: publicar no GitHub Pages

1. Em **github.com**, clique em **+ > New repository**, dê um nome (ex.: `relatorio-servicos`), marque **Public** e clique em **Create repository**.
2. Clique em **uploading an existing file**. Arraste **o conteúdo** da pasta (o `index.html`, o `config.js`, o `README.md` e as pastas `assets` e `supabase`), e não a pasta inteira. O `index.html` precisa aparecer direto na página principal do repositório.
3. Clique em **Commit changes**.
4. Vá em **Settings > Pages**. Em **Source**, escolha **Deploy from a branch**, branch **main**, pasta **/ (root)** e clique em **Save**.
5. Aguarde de 1 a 2 minutos. O endereço aparece no topo da página, no formato `https://seu-usuario.github.io/relatorio-servicos/`.

Para atualizar depois (por exemplo, o `config.js`), use **Add file > Upload files** e envie o arquivo novo: ele substitui o antigo.

## Uso no dia a dia

### Colaborador (celular)

1. Abra o endereço e entre com o e-mail e a senha recebidos.
2. Dica: no menu do navegador, use **Adicionar à tela inicial** para abrir como um aplicativo.
3. Toque em **Tirar foto** com o celular **deitado**. O quadro mostra exatamente o recorte que vai sair no relatório; se a foto estiver na vertical, a ferramenta avisa.
4. Informe a data e o número da OS. Toque no campo **Área**: abre a lista com todas as áreas, separada em linhas férreas e subestações, com busca por número ou nome (ex.: "LF 12", "SE 3", "Sul"). Toque na área. Em **Tipo de serviço**, escolha **Capina química** ou **Roçada mecanizada** (a escolha fica guardada para o próximo envio). Em **Status da área**, escolha o percentual concluído (de 10% a 100%). Confira seu nome e toque em **Enviar registro**.
5. Em **Meus envios do mês**, dá para excluir um envio errado enquanto ele não foi conferido.

Sem internet, o envio não é feito e os dados continuam no formulário para tentar de novo.

### Administrador (computador, de preferência no Chrome ou Edge)

1. Entre com o usuário administrador. A aba **Conferência** mostra os registros do mês.
2. Para cada registro, use **Conferir** ou **Editar** (corrigir data, OS, área, serviço, status ou trocar a foto). Os filtros separam aguardando/conferidos e LF/SE. **Marcar todos como conferidos** agiliza quando está tudo certo.
3. Clique em **Gerar relatório**. Confira as páginas, ajuste o texto do mês na capa se precisar, mantenha marcado **Só registros conferidos** e, em **Incluir** e **Serviço**, escolha se o relatório terá tudo ou só LF/SE, só capina química ou só roçada mecanizada.
4. Clique em **Salvar PDF**. Na janela de impressão, escolha **Salvar como PDF**, papel **A4**, margens **Nenhuma** e deixe marcado **Gráficos de plano de fundo**.

O administrador também pode lançar registros pela aba **Novo registro**.

## Cadastro de áreas (LF e SE)

O `setup.sql` já cadastra as 83 áreas do escopo CSN: **72 linhas férreas (LF-1 a LF-72)** e **11 subestações (SE-1 a SE-11)**, com os nomes do documento de escopo.

Para corrigir um nome ou incluir uma área nova, entre como administrador e abra a aba **Áreas**: digite o nome e saia do campo, que a gravação é automática. As mudanças aparecem na lista do colaborador no próximo acesso.

## Quem vê o quê

| | Colaborador | Administrador |
|---|---|---|
| Enviar registros e fotos | Sim | Sim |
| Ver registros | Só os próprios | Todos |
| Excluir registro | Só os próprios, antes da conferência | Todos |
| Editar, conferir e gerar o PDF | Não | Sim |

As fotos ficam em armazenamento **privado**: só aparecem para quem está logado e tem permissão. O repositório público no GitHub contém apenas a ferramenta, nunca os registros.

## Limites do plano gratuito do Supabase

Confira os valores atuais em supabase.com/pricing. Pontos importantes:

- **Armazenamento de fotos:** cada foto é reduzida no próprio celular para cerca de 300 a 500 KB antes do envio. O espaço gratuito comporta alguns milhares de fotos. Se necessário, exporte e apague fotos de meses antigos já entregues.
- **Pausa por inatividade:** projetos gratuitos podem ser pausados após um período sem uso (hoje, cerca de uma semana). Com uso diário isso não acontece; se acontecer, basta reativar o projeto no painel do Supabase.
