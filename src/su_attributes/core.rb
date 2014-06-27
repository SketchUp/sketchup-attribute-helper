require "sketchup.rb"
require "stringio"

module Sketchup
 module Extensions
  module AttributeHelper

  PLUGIN = self


  def self.visualize_selected
    content = self.traverse_selected
    html = self.wrap_content(content)

    options = {
      :dialog_title => "Attribute Visualizer",
      :preferences_key => 'AttributeVisualizer',
      :scrollable => true,
      :resizable => true,
      :height => 300,
      :width => 400,
      :left => 200,
      :top => 200
    }
    @window ||= UI::WebDialog.new(options)
    @window.set_html(html)
    @window.set_on_close {
      @window = nil
      Sketchup.active_model.selection.remove_observer(@selection_observer)
    }
    @window.show

    @selection_observer ||= AttributeSelectionObserver.new
    model = Sketchup.active_model
    model.selection.remove_observer(@selection_observer)
    model.selection.add_observer(@selection_observer)
  end


  def self.traverse_selected
    html = StringIO.new

    model = Sketchup.active_model
    selection = model.selection
    return "Invalid selection size" unless selection.size == 1
    return "Invalid entity type" unless selection[0].is_a?(Sketchup::Group) ||
      selection[0].is_a?(Sketchup::ComponentInstance)

    instance = selection[0]
    if instance.respond_to?(:definition)
      definition = instance.definition
    else
      definition = instance.entities.parent
    end

    dictionaries = definition.attribute_dictionaries
    return "No dictionaries" if dictionaries.nil?

    dictionaries.each { |dictionary|
      html.puts self.format_dictionary(dictionary)
    }

    html.string
  end


  def self.format_dictionary(dictionary, path = "")
    html_name = self.escape_html(dictionary.name)
    path = "#{path}:#{html_name}"
    html = StringIO.new
    html.puts "<table>"
    html.puts "<caption title='#{path}'>#{html_name}</caption>"
    html.puts "<tbody>"
    dictionary.each { |key, value|
      html_key = self.escape_html(key)
      html_value = self.escape_html(value)
      node_path = "#{path}:#{html_key}"
      html.puts "<tr title='#{node_path}'><td>#{html_key}</td><td>#{html_value}</td></tr>"
    }
    if dictionary.attribute_dictionaries
      dictionary.attribute_dictionaries.each { |sub_dic|
        html.puts "<tr><td colspan='2' class='dictionary'>"
        html.puts self.format_dictionary(sub_dic, path)
        html.puts "</td></tr>"
      }
    end
    html.puts "</tbody>"
    html.puts "</table>"
    html.string
  end


  def self.escape_html(data)
    data.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end


  def self.wrap_content(content)
    html = <<-EOT
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge"/>
<meta charset="UTF-8">
<style>
  html {
    font-family: "Calibri", sans-serif;
    font-size: 10pt;
  }
  table {
    width: 100%;
    /*padding: 0.5em;*/
    border: 1px solid #666;
  }
  caption {
    font-weight: bold;
    text-align: left;
    /*border-bottom: 1px solid silver;*/
    padding: 0.2em;
  }
  td {
    background: #f3f3f3;
    padding: 0.2em;
  }
  td.dictionary {
    background: none;
    padding-left: 1em;
  }
  tr:hover td {
    background: rgba(255,210,180,0.2);
  }
</style>
<head>
<body>
#{content}
</body>
</html>
    EOT
  end


  class AttributeSelectionObserver < Sketchup::SelectionObserver
    def onSelectionAdded(selection, element)
      selection_changed()
    end
    def onSelectionBulkChange(selection)
      selection_changed()
    end
    def onSelectionCleared(selection)
      selection_changed()
    end
    def onSelectionRemoved(selection, element)
      selection_changed()
    end

    private

    def selection_changed
      PLUGIN.visualize_selected
    end
  end


  unless file_loaded?(__FILE__)
    plugins_menu = UI.menu("Plugins")
    menu = plugins_menu.add_submenu("Attribute Helper")
    menu.add_item("Visualize Selected") {
      self.visualize_selected
    }
    file_loaded(__FILE__)
  end


  end # module AttributeHelper
 end # module Extensions
end # module Sketchup
