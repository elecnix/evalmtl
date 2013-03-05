require 'pg'

class ScrapeCache
  def initialize
    @conn = PG.connect( dbname: 'evalmtl' )
  end
  def table(namespace)
    "cache_#{namespace}"
  end
  def lazy_create(namespace)
    create_table(namespace) unless table_exists?(namespace)
  end
  def table_exists?(namespace)
    @conn.query("SELECT count(*) FROM information_schema.tables WHERE table_name = $1", [table(namespace)]) do |result|
      result[0]['count'].to_i == 1
    end
  end
  def create_table(namespace)
    @conn.exec("CREATE TABLE #{table(namespace)} (key varchar(50) PRIMARY KEY, value text)")
  end
  def put(namespace, key, value)
    if (value.nil?)
      puts "NULL PUT: #{key}"
      return
    end
    if (value.include?("Votre session n'est pas valide"))
      puts "INVALID PUT: #{key}"
      return
    end
    lazy_create(namespace)
    value = value.encode('utf-8')
    @conn.query("UPDATE #{table(namespace)} SET value=$2 WHERE key=$1", [key, value])
    @conn.query("INSERT INTO #{table(namespace)} (key, value) SELECT $1::varchar, $2::varchar WHERE NOT EXISTS (SELECT 1 FROM #{table(namespace)} WHERE key=$1)", [key, value])
  end

  def get(namespace, key)
    lazy_create(namespace)
    value = @conn.exec("SELECT value FROM #{table(namespace)} WHERE key=$1", [key]) do |result|
      result[0]['value'] unless result.ntuples == 0
    end
    if (!value.nil? && value.include?("Votre session n'est pas valide"))
      puts "INVALID CACHE: #{key}"
      nil
    else
      value
    end
  end
end

