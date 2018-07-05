# Airtable Page Generator
# Generate pages from individual curriculum records in downloaded Airtable files
require 'pry'

module Jekyll

  class AirtableDataPage < Page
    include Jekyll::AirtableFilters

    def initialize(site, base, dir, data, name, template, extension)
      @site = site
      @base = base
      @dir = format_dir(dir, data)
      @name = sanitize_filename(data[name]).to_s + "." + extension.to_s

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), template + ".html")
      self.data['context'] = data
    end

    private

    # This function is very, very fragile
    def format_dir(dir, data)
      token = dir[/{(.+)}/, 1]

      unless token.nil? || data[token.split(".").first].nil?

        key = dir[/{(.+)}/, 1].split(".").first
        nested_key = dir[/{(.+)}/, 1].split(".").last  

        # Linked Airtable records show up as Arrays
        if data[key].kind_of?(Array) && data[key].count == 1
          # binding.pry
          record = record(data[key].first, data["base"])
          formatted_dir = dir.gsub("{#{token}}", record[nested_key].parameterize)
          puts "    identified token #{token} in subdirectory, reformatted to #{formatted_dir}"
          return formatted_dir
        end

        record = record(data[key].first, data["base"])
        formatted_dir = dir.gsub("{#{token}}", record[nested_key].parameterize)
        puts "    identified token #{token} in subdirectory, reformatted to #{formatted_dir}"
        return formatted_dir
      end
      return dir
    end

    # strip characters and whitespace to create valid filenames, also lowercase
    def sanitize_filename(name)
      return name.to_s.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    end
  end

  class AirtableDataPagesGenerator < Generator

    safe true

    def generate(site)
      page_gen_data = site.config['airtable_pages']

      if page_gen_data
        page_gen_data.each do |page_spec|
          build_group(site, page_spec)
        end
      end
    end

    def build_group(site, page_spec, parent_record = nil)

      log = parent_record.nil? ? "Building pages for #{page_spec['type']} records" : "... building child pages for #{parent_record[page_spec['name']]}'s '#{page_spec['key']}' children"
      puts log

      table = page_spec['table']
      name = page_spec['name']
      type = page_spec['type']
      template = page_spec['template'] || page_spec['table']
      subdirectory = page_spec['subdirectory']
      extension = page_spec['extension'] || "html"
      
      if site.layouts.key? template
        puts "pulling #{type} records from #{page_spec['table']}"
        
        records = parent_record.nil? ? site.data[page_spec['table'].parameterize].select{|key, value| value['type'] == type}.values : parent_record[page_spec['key']].nil? ? Array.new : parent_record[page_spec['key']].map {|id| site.data[page_spec['table'].parameterize][id]}
        
        puts "#{records.length} records pulled"
        records.each do |record|
          site.pages << AirtableDataPage.new(site, site.source, subdirectory, record, name, template, extension)
          puts "... built for #{record[name]}"

          if page_spec['children']
            page_spec['children'].each do |child_spec|

              # puts "should build child pages with spec: #{child_spec}"

              child_spec['parent_spec'] = page_spec
              child_spec['table'] = page_spec['table']
              child_spec['type'] = child_spec['key'] # maybe don't include this, may fetch all of this type, or maybe that's a good thing and you take intersection of record ids
              # child_spec['subdirectory'] = parent_record.nil? ? page_spec['subdirectory'] + "/#{child_spec['subdirectory']}" : page_spec['subdirectory'] + "/#{parent_record[name].parameterize}" + "/#{child_spec['subdirectory']}"
              # child_spec['subdirectory'] = parent_record.nil? ? "#{page_spec['subdirectory']}/#{child_spec['subdirectory']}" : "#{page_spec['subdirectory']}/#{parent_record[name].parameterize}/#{child_spec['subdirectory']}"
              # child_spec['subdirectory'] = "#{page_spec['subdirectory'}/#{child_spec['subdirectory']}"

              subdirectory = parent_record.nil? ? page_spec['subdirectory'] : "#{page_spec['subdirectory']}/#{parent_record[page_spec['parent_spec']['name']]}"
              puts subdirectory

              child_spec['subdirectory'] = subdirectory

              # /{course_short_id}/{curriculum_set_short_id}/sprint/{sprint_id}/modules/{module_id}
              # /ios/ios-pre/sprint/{sprint_id}
              # /ios/ios-pre/module/{module_id}

              build_group(site, child_spec, record)
            end
          end
        end
      else
        puts "error. could not find template #{template}" if not site.layouts.key? template
      end
    end
  end
end