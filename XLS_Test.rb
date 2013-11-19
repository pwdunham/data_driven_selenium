require 'xls'
require 'test/unit'
require 'pp'

class XLS_test < Test::Unit::TestCase

  def setup
    dataFile = Dir.getwd + '/test_XLS_data.xls'
    puts "Tests executing using test data from file: '#{dataFile}'"
    @xl = XLS.new(dataFile,false)
    @data2D = [['ID',	  'First Name',	'Last Name',	'Address'],
                    ['1001',	'Fred',	          'Flinstone',	'123 Bedrock Lane'],
                    ['1002',	'Wilma',	        'Flinstone',	'123 Bedrock Lane'],
                    ['1003',	'Barney',	      'Rubble',    	'125 Bedrock Lane'],
                    ['1004',	'Betty',	        'Rubble',	    '125 Bedrock Lane']]
    @dataArrayHash = [
                                {'Last Name'=>'Flinstone', 	'ID'=>'1001', 	'Address'=>'123 Bedrock Lane', 	'First Name'=>'Fred'},
                                {'Last Name'=>'Flinstone', 	'ID'=>'1002', 	'Address'=>'123 Bedrock Lane', 	'First Name'=>'Wilma'},
                                {'Last Name'=>'Rubble', 	'ID'=>'1003', 	'Address'=>'125 Bedrock Lane', 	'First Name'=>'Barney'},
                                {'Last Name'=>'Rubble', 	'ID'=>'1004', 	'Address'=>'125 Bedrock Lane', 	'First Name'=>'Betty'}
                              ]
    @keyValueHash = {'Last Name'=>'Flinstone', 	'ID'=>'1001', 	'Address'=>'123 Bedrock Lane', 	'First Name'=>'Fred'}
    @addSheetName = "HokeyPokey"
  end

  def test_get2DArray
    puts "\n\n>>test_get2DArray"
    my2DarrayData = @xl.get2DArray('B3:E7','Sheet1')
    puts "get2DArray('B3:E7','Sheet1') --> "
    puts2DArray(my2DarrayData)
    assert(@data2D == my2DarrayData)
  end

  def test_convert2DArraytoArrayHash
    puts "\n\n>>test_convert2DArraytoArrayHash"
    myArrayHash = @xl.convert2DArrayToArrayHash(@data2D,true)
    puts "Origional 2D array:"
    puts2DArray(@data2D)

    puts "convert2DArrayToArrayHash(Origional 2D array) --> "
    putsArrayHash(myArrayHash)
    assert(myArrayHash==@dataArrayHash,"Converted Array Hash does not match Origional.")
  end

  def test_getRange
    puts "\n\n>>test_getRange"
    labelRange = '$C$10:$E$14'
    defaultRange = '$A$1:$C$5'
    testLabel = @xl.getRange('Label','Label_test').address
    testLabelRange = @xl.getRange(labelRange,'Label_test').address
    testDefaultRange = @xl.getRange(nil,'Label_test').address
    puts "getRange('Label','Label_test')--> '#{testLabel}'"
    puts "getRange('#{labelRange}','Label_test')--> '#{testLabelRange}'"
    puts "getRange(nil,'Label_test')--> '#{testDefaultRange}'"
    assert(testLabel == labelRange,"getRange('Label','Label_test') returned #{testLabel}. It should have been #{labelRange}")  #Test lookup by Label
    assert(testLabelRange == labelRange,"getRange('#{labelRange}','Label_test') returned #{testLabelRange}. It should have been #{labelRange}") #Test lookup by Range
    assert(testDefaultRange == defaultRange,"getRange(nil,'Label_test') returned #{testDefaultRange}. It should have been #{defaultRange}") #Test default lookup

    #make sure an error is thrown if a label/range could not be found:
    assert_raises(RuntimeError, "getRange('SOME UNKNOWN LABEL','Label_test')  Should have raised a RuntimeError stating that no label could be found."){@xl.getRange('SOME UNKNOWN LABEL','Label_test')}
  end

  def test_getColumnRecords
    puts "\n\n>>test_getColumnRecords"
    colRecords = @xl.getColumnRecords('People_Column_Records','Sheet1')
    puts "getColumnRecords('People_Column_Records','Sheet1') -->"
    putsArrayHash(colRecords)
    assert(colRecords==@dataArrayHash,"Records do not match Origional.")
  end
  def test_getRowRecords
    puts "\n\n>>test_getRowRecords"
    rowRecords = @xl.getRowRecords('People_Row_Records','Sheet1')
    puts "getRowRecords('People_Row_Records','Sheet1') -->"
    putsArrayHash(rowRecords)
    assert(rowRecords==@dataArrayHash,"Records do not match Origional.")
  end

  def test_getHash
    puts "\n\n>>test_getHash"
    myHash= @xl.getHash('B24:C27','Sheet1')
    puts "getHash('B24:C27','Sheet1') -->"
    pp myHash
    assert(myHash==@keyValueHash,"Records do not match Origional.")
  end

  def test_write2DArray
    puts "\n\n>>test_write2DArray"
    @xl.write2DArray(@data2D,"B36")
    data2 = @xl.get2DArray("B36:E40")
    assert(@data2D == data2)
    puts "data1:"
    pp @data2D
    puts "data2:"
    pp data2
  end

  def test_writeArrayHash
    puts "\n\n>>test_writeArrayHash"
    @xl.writeArrayHash(@dataArrayHash,"B36")
    data2 = @xl.getRowRecords("B36:E40")
    assert(@dataArrayHash == data2)
    puts "Array Hash to be written:"
    pp @dataArrayHash
    puts "Array Hash read from file after writing:"
    pp data2
  end

  def test_add_delete_Sheet
    puts "\n\n>>test_add_delete_Sheet"
    @xl.addSheet(@addSheetName)
    assert_nothing_raised("Sheet was not added") {@xl.getWorksheet(@addSheetName)}
    @xl.deleteSheet(@addSheetName)
    assert_raises(RuntimeError,"Sheet was nto deleted") {@xl.getWorksheet(@addSheetName)}
  end

  def teardown
    @xl.close
  end

  #prints a 2DArray nicely
  def puts2DArray(my2DArray)
      puts '['
      my2DArray.each do |row|
        puts "[#{row.join(", \t")}]"
      end
      puts ']'
  end
  #prints an Array of Hashes nicely
  def putsArrayHash(myArrayHash)
      puts '['
      myArrayHash.each do |aHash|
        tmp = []
        aHash.each do |key,value|
          tmp << "'#{key}'=>'#{value}'"
        end
        puts '{' + tmp.join(", \t") + '},'
      end
      puts ']'
  end
end
