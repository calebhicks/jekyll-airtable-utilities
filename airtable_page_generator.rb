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

        formatted_dir = dir.gsub("{#{token}}", data[token])
        puts "    identified token #{token} in subdirectory, reformatted to #{formatted_dir}"
        return formatted_dir
      end
      return dir
    end

    # strip characters and whitespace to create valid filenames, also lowercase
    def sanitize_filename(name)
      if(name.is_a? Integer)
        return name.to_s
      end
      return name.to_s.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    end
  end

  class AirtableDataPagesGenerator < Generator
    safe true

    def generate(site)
      page_gen_data = site.config['airtable_pages']

      if page_gen_data
        page_gen_data.each do |data_spec|

          puts "Building pages for #{data_spec['type']} records"

          # todo: check input data correctness
          name = data_spec['name']
          type = data_spec['type']
          template = data_spec['template'] || data_spec['table']
          subdirectory = data_spec['subdirectory']
          extension = data_spec['extension'] || "html"
          
          if site.layouts.key? template
          	puts "pulling #{type} records"

            puts data_spec['table']

      			records = site.data[data_spec['table'].parameterize].select{|key, value| value['type'] == type}.values # kind should be singular, this allows search to be plural or singular
      			puts "#{records.length} records pulled"
            records.each do |record|
              site.pages << AirtableDataPage.new(site, site.source, subdirectory, record, name, template, extension)
              puts "... built for #{record[name]}"
            end
          else
            # puts "error. could not find data for #{type}" if not File.exists?(data_file)
            puts "error. could not find template #{template}" if not site.layouts.key? template
          end
        end
      end
    end
  end
end