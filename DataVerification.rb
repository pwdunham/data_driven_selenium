#-----------------------------------------------------------------------------#
# DataVerification.rb
#
# Author: Tiffany Fodor
# Date: 11/09/2007
# Description:  Verify the data in the SQL DB by comparing it to the data in 
#		  the Oracle DB. 
#
# Change history:
#
# 11/09/2007 - Initial Development
# 10/01/2008 - Scrubbed to simplify as an example
#
#-----------------------------------------------------------------------------#
def dataVerification(accounts)
    @insuredName = (account["accountName"] + "_" + $accountID)
    
    accounts.each do |account| 
        if account["accountName"] != ""           
            
            #run tests for individual tables, in this case, just the AccountInfo table
            accountInfo(account)

            puts ""
            puts "Data Compare tests complete for account: " + @insuredName + "."
            puts ""
        end
    end
end       

def accountInfo(account)
    #connect to the oracle database
    ora_connect = DBI.connect("DBI:ADO:Provider=OraOLEDB.Oracle;Data Source=Test;User Id=read_only;Password=password") 
    #AccountData table values, best to limit the number of queries and get all values for a table at once due to issues with the DBI class
    oracleAccountInfoValues = getDBValue(ora_connect, "SELECT AccountId, State, Address1, Address2, City, State, ZIP FROM AccountData WHERE AccountName = ?", @insuredName)	
    ora_connect.disconnect
    
    #connect to the sql database
    sql_connect = DBI.connect("DBI:ADO:Provider=SQLOLEDB;Data Source=DevBox;Initial Catalog=TestDB;User Id=read_user;Password=password")
    #AccountInfo table values  
    sqlAccountInfoValues = (getDBValue(sql_connect, "SELECT Id, AccountState, Address1, Address2, AccountCity, AccountState, AccountZIP FROM AccountInfo WHERE AccountName = ?", @insuredName))
    sql_connect.disconnect
    
    ora_Id = oracleAccountInfoValues[0]
    sql_Id = sqlAccountInfoValues[0]
    #compare the values
    verify_equal(ora_Id, sql_Id, message="accountInfo_Id was incorrect for account " + @insuredName + ".")
    
    ora_State = oracleAccountInfoValues[1]
    sql_State = sqlAccountInfoValues[1]
    #compare the values
    verify_equal(ora_State, sql_State, message="accountInfo_State was incorrect for account " + @insuredName + ".")
       
    ora_Address1 = oracleAccountInfoValues[2]
    sql_Address1 = sqlAccountInfoValues[2]
    #compare the values
    verify_equal(ora_Address1, sql_Address1, message="accountInfo_Address1 was incorrect for account " + @insuredName + ".")
    
    ora_Address2 = oracleAccountInfoValues[3]
    sql_Address2 = sqlAccountInfoValues[3]
    #compare the values
    verify_equal(ora_Address2, sql_Address2, message="accountInfo_Address2 was incorrect for account " + @insuredName + ".")
    
    ora_City = oracleAccountInfoValues[4]
    sql_City = sqlAccountInfoValues[4]
    #compare the values
    verify_equal(ora_City, sql_City, message="accountInfo_City was incorrect for account " + @insuredName + ".")
    
    ora_State = oracleAccountInfoValues[5]
    sql_State = sqlAccountInfoValues[5]
    #compare the values
    verify_equal(ora_State, sql_State, message="accountInfo_State was incorrect for account " + @insuredName + ".")
    
    ora_ZIP = oracleAccountInfoValues[6]
    sql_ZIP = sqlAccountInfoValues[6]
    #compare the values
    verify_equal(ora_ZIP, sql_ZIP, message="accountInfo_ZIP was incorrect for account " + @insuredName + ".")
        
end

#method for returning data in single rows
def getDBValue(connection, query, id1, *id2)
    dbi_query = connection.prepare(query)
    dbi_query.execute(id1, *id2)
    #fetch the result
    return dbi_query.fetch
end

#method for returning data in multiple rows at once, if necessary
def getDBArray(connection, query, id1, *id2)
    dbi_query = connection.prepare(query)
    dbi_query.execute(id1, *id2)
    #fetch the result
    return dbi_query.fetch_all
end