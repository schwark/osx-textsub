require 'rubygems'
require 'cfpropertylist'
require 'json'

global_preferences_path = File.expand_path("~/Library/Preferences/.GlobalPreferences.plist")

plist = CFPropertyList::List.new(:file => global_preferences_path) 
replacement_items = plist.value.value["NSUserReplacementItems"].value
#replacement_items = plist.value.value["NSUserDictionaryReplacementItems"].value

items = replacement_items.inject({}) do |memo, index| 
  entry = index.value
  key = entry["replace"].value
  enabled = entry["on"] && (entry["on"].value == 1)
  replacement = entry["with"].value
  memo[key] = {"enabled" => enabled, "replacement" => replacement}
  memo
end

puts JSON.pretty_generate(items)

