#*****************************************************************************#
# CreateAccounts.rb
#
# Author: Tiffany Fodor
# Date: 06/26/2007
# Description:  Script to create accounts
#
# Change history:
#
# 06/26/2007 - Initial Development
# 09/06/2007 - Added Quake functionality 
# 12/07/2007 - Cleaned up comments
# 02/15/2008 - Scrubbed to simplify as an example
#
#******************************************************************************#

def createAccounts(accounts)
  
    accounts.each do |account| 
    
        if account["accountName"] != ""
            insuredName = (account["accountName"] + "_" + $accountID) #append unique identifier to the account name
            
            $ie.link(:text, "Find Account").click
            $ie.text_field(:name, "namedInsured").set(insuredName)
            $ie.link(:text, "Find").click
            
            if $ie.span(:text, insuredName).exists? == false
                $ie.link(:text, "Create New Account").click
                
                # account information
                $ie.text_field(:name, "namedInsured").set(insuredName)
                $ie.text_field(:name, "mailingAddr1").set(account["address1"])
                $ie.text_field(:name, "mailingAddr2").set(account["address2"])
                $ie.text_field(:name, "city").set(account["city"])
                $ie.text_field(:name, "state").set(account["state"])
                $ie.text_field(:name, "zip").set(account["ZIP"])
                $ie.link(:text, "Close").click
                
                # verify account was created
                $ie.link(:text, "Find Account").click
                $ie.text_field(:name, "namedInsured").set(insuredName)
                $ie.link(:text, "Find").click
                verify(($ie.span(:text, insuredName).exists?), message="Account " + insuredName + " could not be created.")	
                puts "Account " + insuredName + " created successfully."
                puts " "
            else	
                # if account already exists, skip it and let the user know
                puts " "
                puts "Account " + insuredName + " already exists.  Continuing with the other accounts."	
                puts " "
            end
        end
    end	
    
    $ie.link(:text, "Homepage").click
end




