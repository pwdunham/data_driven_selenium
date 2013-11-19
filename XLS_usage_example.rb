require 'xls'
require 'watir'

xlFile = XLS.new(Dir.pwd + '/test_XLS_data.xls') #grab the data file in the same dirrectory
myData = xlFile.getRowRecords('Google Search Data','Example')  #pull data records  from excel
xlFile.close
myData.each do |record|
  ie = Watir::IE.start('google.com')
  ie.text_field(:name,'q').set(record['SearchString'])
  ie.button(:value,/Search/i).click
  if ie.contains_text(record['ContainsText'])
    puts "Results of search: '#{record['SearchString']}' contains '#{record['ContainsText']}'"
  else
    puts "Error: could not find text: '#{record['ContainsText']}' in results of search: '#{record['SearchString']}'"
  end
  sleep 3
  ie.close
end

