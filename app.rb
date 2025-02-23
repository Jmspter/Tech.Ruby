require 'sinatra'
require 'rss'
require 'net/http'

FEEDS = {
  'G1' => 'https://g1.globo.com/rss/g1/tecnologia/',
  'NoticiasAoMinuto' => 'https://www.noticiasaominuto.com.br/rss/tech',
  'FolhaDeSãoPaulo' => 'https://feeds.folha.uol.com.br/tec/rss091.xml'
}.freeze

get '/' do
  @fonte = params['fonte']
  @categoria = params['categoria']

  @noticias = []

  FEEDS.each do |fonte, feed_url|
    next if @fonte && fonte.downcase != @fonte.downcase

    uri = URI.parse(feed_url)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      rss = RSS::Parser.parse(response.body, false)
      rss.items.each do |item|
        next if @categoria && !item.categories.any? { |cat| cat.content.downcase.include?(@categoria.downcase) }

        @noticias << {
          fonte: fonte,
          titulo: item.title,
          link: item.link,
          descricao: item.description,
          data: item.pubDate,
          categorias: item.categories.map(&:content)
        }
      end
    end
  end

  @noticias.sort_by! { |noticia| noticia[:data] }.reverse!

  erb :index
end