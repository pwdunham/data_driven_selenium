#-----------------------------------------------------------------------------#
# LogInOut.rb
#
# Author: Tiffany Fodor
# Date: 10/17/2007
# Description:  Login and logout methods
#
# Change history:
#
# 10/17/2007 - Initial Development
# 02/15/2008 - Scrubbed to simplify as an example
#
#-----------------------------------------------------------------------------#

  
# login method
def login(name, password)
        $ie.text_field(:name, "username").set(name)
        $ie.text_field(:name, "password").set(password)
        $ie.link(:text, "Login").click
      
        verify($ie.text.include?("Homepage"), message="The login was unsuccessful, the user was not taken to the Homepage.")
end
 
def logout 
    $ie.link(:text, "Logout").click
              
end