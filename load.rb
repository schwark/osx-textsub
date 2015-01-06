require 'rubygems'
require 'cfpropertylist'
require 'json'
require 'sqlite3'

global_preferences_path = 
  File.expand_path("~/Library/Preferences/.GlobalPreferences.plist")

plist = CFPropertyList::List.new(:file => global_preferences_path) 
replacement_items = plist.value.value["NSUserDictionaryReplacementItems"].value

items = replacement_items.inject({}) do |memo, index| 
  entry = index.value
  key = entry["replace"].value
  enabled = entry["on"] && (entry["on"].value == 1)
  replacement = entry["with"].value
  memo[key] = {"enabled" => enabled, "replacement" => replacement}
  memo
end

import_items = JSON.parse File.read("text-substitutions.json")
import_items = items.merge(import_items)

dbname = "~/Library/Dictionaries/CoreDataUbiquitySupport/#{ENV['USER']}~*/UserDictionary/local/store/UserDictionary.db"
sqls = []
sqls << "delete from ZUSERDICTIONARYENTRY"
counter = 0;
import_items.each do |key, item|
  next if item['replacement'] == "आ"
  print "replacing #{key} with #{item['replacement']}\n"
  counter += 1
  sqls << "INSERT INTO 'ZUSERDICTIONARYENTRY' VALUES(#{counter},1,1,0,0,0,0,#{Time.now.to_i},NULL,NULL,NULL,NULL,NULL,\"#{item['replacement']}\",\"#{key}\",NULL)"
end

import_items.delete_if do |key| items.has_key?(key) and items[key]['replacement'] == import_items[key]['replacement'] end
insertion_items = []
import_items.each do |key, data|
  print "#{key} with #{data['replacement']}\n"
  item = { "replace" => key, "with" => data["replacement"]}
  item["on"] = 1 if data["enabled"]
  insertion_items << item
end

sql = sqls.join("; ")+";"
File.write("text-sub.sql", sql)

# also load back into the ZUSERDICTIONARY
`/usr/bin/sqlite3 #{dbname} < text-sub.sql`

# save back into CFPropertyList
merging_array = CFPropertyList::guess(insertion_items).value
replacement_items.concat merging_array
plist.save(global_preferences_path, 1) # binary
