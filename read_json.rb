require 'rubygems'
require 'json'
require 'pp'

json_contents = File.read('company_input.json')
#company="cbre"
company = ARGV[0]
parsed_data = JSON.parse(json_contents)


parsed_data['clients'].each do |company|
#  puts company
end
  puts parsed_data['clients'][company]['env']
  puts parsed_data['clients'][company]['version']
