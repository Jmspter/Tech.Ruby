require 'sqlite3'

# Conecta ao banco de dados 
db = SQLite3::Database.new('agregador_noticias.db')

# Cria a tabela de usuários
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    senha TEXT NOT NULL
  );
SQL

# Cria a tabela de notícias favoritas
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS favoritas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id INTEGER NOT NULL,
    titulo TEXT NOT NULL,
    link TEXT NOT NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
  );
SQL

puts "Banco de dados configurado com sucesso!"