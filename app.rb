require 'sinatra'
require 'rss'
require 'net/http'

# URLs dos feeds RSS que você quer agregar
FEEDS = {
  'G1' => 'https://g1.globo.com/rss/g1/tecnologia/',
  'NoticiasAoMinuto' => 'https://www.noticiasaominuto.com.br/rss/tech',
  'Camara' => 'https://www.camara.leg.br/noticias/rss/dinamico/CIENCIA-E-TECNOLOGIA'
}.freeze

# Helpers
helpers do
  def options_for_select(collection, selected = nil)
    collection.map do |item|
      "<option value='#{item}' #{'selected' if item == selected}>#{item}</option>"
    end.join
  end
end

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