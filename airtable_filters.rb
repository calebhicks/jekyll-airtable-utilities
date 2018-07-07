# Airtable Filters

module Jekyll
	module AirtableFilters
		
		# Pulls a record from a base
		def record(id, base)
			unless id.nil?
				site = @context.present? ? @context.registers[:site] : @site
				data = site.data[base]
				resource = data[id]
			end
		end

		# Pulls all records of a specific type
		def pull_type(base, type)

			unless base.nil? || type.nil?
				site = @context.registers[:site]
				data = site.data[base]
				records = data.select{|key, value| value['type'] == type or value['type'] == type.chop}.values # type should be singular, this allows search to be plural or singular
			end
		end

		# Maps an array of record IDs into records
		def map_ids(ids, base)
			unless ids.nil?
				
				site = @context.registers[:site]
				data = site.data[base]
				records = ids.compact.map {|id| record(id,base)}
			end
		end
	end
end

Liquid::Template.register_filter(Jekyll::AirtableFilters)