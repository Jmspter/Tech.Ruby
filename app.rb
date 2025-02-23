require 'sinatra'
require 'rss'
require 'net/http' # Adicione esta linha

get '/' do
  # URLs dos feeds RSS que você quer agregar
  feeds = [
    'http://feeds.bbci.co.uk/news/rss.xml',
    'https://g1.globo.com/rss/g1/',
    'https://www.tecmundo.com.br/feed'
  ]

  @noticias = []

  feeds.each do |feed_url|
    begin
      # Faz a requisição HTTP
      uri = URI.parse(feed_url)
      response = Net::HTTP.get_response(uri)

      if response.code == "200" # Verifica se a requisição foi bem-sucedida
        rss = RSS::Parser.parse(response.body, false)
        rss.items.each do |item|
          @noticias << {
            titulo: item.title,
            link: item.link,
            descricao: item.description,
            data: item.pubDate
          }
        end
      else
        puts "Erro ao acessar o feed: #{feed_url} (Código: #{response.code})"
      end
    rescue StandardError => e
      puts "Erro ao acessar o feed: #{feed_url}"
      puts e.message
    end
  end

  # Ordena as notícias por data (mais recentes primeiro)
  @noticias.sort_by! { |noticia| noticia[:data] }.reverse!

  erb :index
end