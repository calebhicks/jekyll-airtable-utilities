require 'net/http'
require 'net/https'
require 'json'
require 'active_support/all'
require 'fileutils'
require 'uri'

# Airtable Fetch Hook

Jekyll::Hooks.register :site, :after_init do |site|
		
	site.read

	@airtable_config = Jekyll.configuration({})['airtable']
	@api_key = @airtable_config['api_key']

	def get_table(table_id, sheet, view, offset=nil)
	  uri = URI("https://api.airtable.com/v0/#{table_id}/#{sheet}?view=#{view}") # Pulls from specified view, should match sorting of that view.

	  if offset
	  	uri = URI("#{uri.to_s}&offset=#{offset}")
	  end

	  # Create client
	  http = Net::HTTP.new(uri.host, uri.port)
	  http.use_ssl = true
	  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

	  # Create Request
	  req =  Net::HTTP::Get.new(uri)
	  # Add headers
	  req.add_field "Authorization", "Bearer #{@api_key}"

	  # Fetch Request
	  res = http.request(req)

	  response_body_json = JSON.parse(res.body)

	  if response_body_json["offset"] # There are more than 100 records in the response, fetch next page and merge into the response body
	  	puts "Fetching additional records with offset: #{response_body_json["offset"]}"
	  	paged_response_body = get_table(table_id, sheet, view, response_body_json["offset"])
	  	paged_response_body_json = JSON.parse(paged_response_body)
	  	merged = response_body_json.merge(paged_response_body_json){|key,oldval,newval| [*oldval].to_a + [*newval].to_a }
	  	res.body = merged.to_json
	  end

	  return res.body
	rescue StandardError => e
	  puts "HTTP Request failed (#{e.message})"
	end

	@airtable_config['tables'].each do |table|

		puts "Fetching data in #{table['name']}"

		data = {}

		table['sheets'].each do |sheet|

			puts "... fetching #{sheet['name']}: #{sheet['view']}"
			response = get_table(table['app_id'], URI.escape(sheet['name']), URI.escape(sheet['view']))
			records = JSON.parse(response)

			for record in records["records"]
				# perform any record transformation here
					# TODO: someday, downcase all of the records
				record['fields']['type'] = sheet['name'].chop
				record['fields']['id'] = record['id']
				record['fields']['base'] = table['name'].parameterize
				data[record['id']] = record['fields']
			end
		end

		dirname = File.dirname("_data/#{table['name']}")
		unless File.directory?(dirname)
			FileUtils.mkdir_p(dirname)
		end

		File.open(dirname + "/" + table['name'].parameterize + ".json", "w") do |file|
			file.write(data.to_json)
		end
	end
end