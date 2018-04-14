#!/usr/bin/ruby

# Adapted from https://github.com/noahmanger/emoji-text-replacement/

require 'erb'
require 'rubygems'
require 'json'

def get_template()
%{\uFEFF
<% for @item in @items %>
::<%= @item['code'] %>::<%=h @item['unicode'] %>\r
<% end %>
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

all = true
items = []
Dir.entries(".").each do |filename|
  next if not filename.end_with?(".json")
  items = items + get_items(filename)
  if not all
    list = TextReplaceList.new(items, get_template)
    list.save(File.join(File.dirname(__FILE__), filename+'.ahk'))
    items = []
  end
end
if all
  list = TextReplaceList.new(items, get_template)
  list.save(File.join(File.dirname(__FILE__), 'allitems.ahk'))
end
