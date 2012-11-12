class ScrapeCache
  # Hash the key to get get less than 256 files in a single directory (for 1/2 million keys)
  # To check if well-balanced for 'aX' bucket:
  # find cache/address/a* -type f | sed -e 's#cache/address/\(a.\)/../.*#\1#'|uniq -c|sort -n
  def self.filename(namespace, key)
    if (namespace != "street_search")
      hash = Digest::MD5.hexdigest(key).scan(/../).take(2).join("/")
      "cache/#{namespace}/#{hash}/#{key}"
    else
      "cache/#{namespace}/#{key}"
    end
  end
  def self.put(namespace, key, value)
    if (value.nil?)
      puts "NULL PUT: #{key}"
      return
    end
    if (value.include?("Votre session n'est pas valide"))
      puts "INVALID PUT: #{key}"
      return
    end
    filename = self.filename(namespace, key)
    dirname = File.dirname(filename)
    FileUtils.mkdir_p(dirname)
    File.open(filename, 'w') do |f|
      f.write(value)
    end
  end
  def self.get(namespace, key)
    filename = self.filename(namespace, key)
    dirname = File.dirname(filename)
    old_filename = "cache/#{namespace}/#{key}"
    if (File.exists?(old_filename) && namespace != "street_search")
      puts `mkdir -p #{dirname} ; mv -v #{old_filename} #{dirname}`
    end
    value = File.open(filename, 'rb') { |f| f.read } if (File.exists?(filename))
    if (!value.nil? && value.include?("Votre session n'est pas valide"))
      puts "INVALID CACHE: #{key}"
      nil
    else
      value
    end
  end
end
