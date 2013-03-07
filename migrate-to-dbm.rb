#!/usr/bin/ruby
require 'rubygems'
require 'zlib'
require 'archive/tar/minitar'
require 'dbm'

db = {}
['street', 'address', 'street_search'].each do |ns|
  db[ns] = DBM.open(ns)
end

def repeat_every(interval)
  Thread.new do
    loop do
      sleep(interval)
      yield
    end
  end
end

imported = 0
last_time = Time.now
last_count = 0

thread = repeat_every(5) do
  rate = (imported - last_count) / (Time.now - last_time)
  puts "Imported #{imported} (#{rate.to_i}/s)"
  last_count = imported
  last_time = Time.now
end

tgz = Zlib::GzipReader.new(File.open('evalweb-cache.tgz', 'rb'))
Archive::Tar::Minitar::Input.open(tgz) do |input|
  input.each do |entry|
    begin
      next unless entry.file?
      name = entry.full_name.split(%r{/})
      namespace = name[1]
      next if namespace == "invalid" # what's that?
      if (namespace == "street_search")
        # cache/namespace/key
        key = name[2]
      else
        # cache/namespace/hash1/hash2/key
        key = name[4..-1].join('/') # Preserve slashes in street id
      end
      value = entry.read
      value.force_encoding('iso-8859-1')
      value = value.encode('utf-8')
      db[namespace][key] = value
      imported += 1
    rescue Exception => err
      puts "#{entry.full_name}: #{err}"
    end
  end
end
db.each do |ns,d|
  d.close
end

