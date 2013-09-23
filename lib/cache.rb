require 'dbm'

class ScrapeCache
  def initialize
    @databases = Hash.new { |dbs, namespace| dbs[namespace] = DBM.open(namespace + "_2014") }
  end
  def put(namespace, key, value)
    if value.nil?
      puts "NULL PUT: #{key}"
    elsif (value.include?("Votre session n'est pas valide"))
      puts "INVALID PUT: #{key}"
    else
      @databases[namespace][key] = value.encode('utf-8')
    end
  end
  def get(namespace, key)
    value = validate @databases[namespace][key.to_s]
  end
  def validate(value)
    if (!value.nil? && value.include?("Votre session n'est pas valide"))
      puts "INVALID CACHE: #{key}"
      nil
    elsif value.nil?
      nil
    else
      value.force_encoding('utf-8')
    end
  end
  def include?(namespace, key)
    @databases[namespace].has_key?(key)
  end
end

