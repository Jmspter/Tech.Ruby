require 'sinatra'
require 'rss'
require 'net/http'
require 'sqlite3'
require 'securerandom'
require 'digest'

# Habilita sessões
enable :sessions

# Configuração do banco de dados
configure do
  set :database, SQLite3::Database.new('agregador_noticias.db')
  settings.database.results_as_hash = true # Retorna resultados como hashes
end

# Helpers para autenticação
helpers do
  def usuario_logado?
    !session[:usuario_id].nil?
  end

  def usuario_atual
    @usuario_atual ||= settings.database.execute(
      "SELECT * FROM usuarios WHERE id = ?", session[:usuario_id]
    ).first if usuario_logado?
  end

  def options_for_select(collection, selected = nil)
    collection.map do |item|
      "<option value='#{item}' #{'selected' if item == selected}>#{item}</option>"
    end.join
  end
end

# URLs dos feeds RSS que você quer agregar
FEEDS = {
  'G1' => 'https://g1.globo.com/rss/g1/tecnologia/',
  'NoticiasAoMinuto' => 'https://www.noticiasaominuto.com.br/rss/tech',
  'Camara' => 'https://www.camara.leg.br/noticias/rss/dinamico/CIENCIA-E-TECNOLOGIA'
}.freeze

# Rotas
get '/' do
  # Parâmetros de filtro (se existirem)
  @fonte = params['fonte']

  @noticias = []

  FEEDS.each do |fonte, feed_url|
    # Aplica o filtro de fonte, se existir
    next if @fonte && fonte.downcase != @fonte.downcase

    # Faz a requisição HTTP usando net/http
    uri = URI.parse(feed_url)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      rss = RSS::Parser.parse(response.body, false)
      rss.items.each do |item|
        @noticias << {
          fonte: fonte,
          titulo: item.title,
          link: item.link,
          descricao: item.description,
          data: item.pubDate,
        }
      end
    end
  end

  # Ordena as notícias por data (mais recentes primeiro)
  @noticias.sort_by! { |noticia| noticia[:data] }.reverse!

  erb :index
end

get '/favoritas' do
  if usuario_logado?
    @favoritas = settings.database.execute(
      "SELECT * FROM favoritas WHERE usuario_id = ?", [session[:usuario_id]]
    )
    erb :favoritas
  else
    redirect '/login'
  end
end

post '/favoritar' do
  if usuario_logado?
    titulo = params[:titulo]
    link = params[:link]

    settings.database.execute(
      "INSERT INTO favoritas (usuario_id, titulo, link) VALUES (?, ?, ?)",
      [session[:usuario_id], titulo, link]
    )

    redirect '/'
  else
    redirect '/login'
  end
end

get '/registrar' do
  erb :registrar
end

post '/registrar' do
  nome = params[:nome]
  senha = params[:senha]

  # Validação básica
  if nome.empty? || senha.empty?
    @erro = "Todos os campos são obrigatórios."
    return erb :registrar
  end

  # Cria um hash da senha (usando SHA256)
  senha_hash = Digest::SHA256.hexdigest(senha)

  begin
    # Insere o usuário no banco de dados
    settings.database.execute(
      "INSERT INTO usuarios (nome, senha) VALUES (?, ?)",
      [nome, senha_hash]
    )
    redirect '/login'
  rescue SQLite3::ConstraintException
    erb :registrar
  end
end

get '/login' do
  erb :login
end

post '/login' do
  nome = params[:nome]
  senha = params[:senha]
  senha_hash = Digest::SHA256.hexdigest(senha)

  # Busca o usuário no banco de dados
  usuario = settings.database.execute(
    "SELECT * FROM usuarios WHERE nome = ? AND senha = ?", [nome, senha_hash]
  ).first

  if usuario
    session[:usuario_id] = usuario['id']
    redirect '/'
  else
    @erro = "Nome ou senha incorretos."
    erb :login
  end
end

get '/logout' do
  session.clear
  redirect '/'
end