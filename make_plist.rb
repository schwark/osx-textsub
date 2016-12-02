#!/usr/bin/ruby

# Adapted from https://github.com/noahmanger/emoji-text-replacement/

require 'erb'
require 'rubygems'
require 'json'

def get_template()
  %{
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <array>
        <% for @item in @items %>
        <dict>
            <key>on</key>
            <integer>1</integer>
            <key>replace</key>
            <string><%= @item['code'] %></string>
            <key>with</key>
            <string><%=h @item['unicode'] %></string>
          </dict>
        <% end %>
      </array>
    </plist>
  }
end

def get_yosemite_template()
  %{
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <array>
        <% for @item in @items %>
        <dict>
          <key>phrase</key>
          <string><%= @item['unicode'] %></string>
          <key>shortcut</key>
          <string><%=h @item['code'] %></string>
        </dict>
      <% end %>
      </array>
    </plist>
  }
end

def get_items(filename)
  replace_pairs = []

  file = File.read(filename)
  replacements = JSON.parse(file)

  replacements.each do |code, value|
    unicode = value['replacement']
    replace_pairs << {'code' => code, 'unicode' => unicode}
  end

  return replace_pairs
end

class TextReplaceList
  include ERB::Util
  attr_accessor :items, :template

  def initialize(items, template)
    @items = items
    @template = template
  end

  def render()
    ERB.new(@template, 0, '>').result(binding)
  end

  def save(file)
    File.open(file, "w+") do |f|
      f.write(render)
    end
  end

end

Dir.entries(".").each do |filename|
  next if not filename.end_with?(".json")
  list = TextReplaceList.new(get_items(filename), get_template)
  list.save(File.join(File.dirname(__FILE__), filename+'_NSUserReplacementItems.plist'))

  yosemite_list = TextReplaceList.new(get_items(filename), get_yosemite_template)
  yosemite_list.save(File.join(File.dirname(__FILE__), filename+'_TextReplaceList.plist'))
end