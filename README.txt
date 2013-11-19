README.txt
Example Test Harness Instructions

Author - Tiffany Fodor
Date 10/01/2008


Introduction
============
This document describes how to set up and use the associated example Watir test harness.


Prerequisites
=============
Ruby 1.8.6 or newer
Watir 1.5.6 or newer
Ruby DBI gem 1.1.1 or newer
Nick Sieger's ci_reporter (available as a gem) 
David Brown's Xls class (available as a user contribution on the Watir wiki)


Files Included
===============
- ExampleHarness.rb
This is the Ruby script that retrieves spreadsheet data, opens the application, runs the test cases and gathers test results.


- RunTests.bat
This batch file runs the ExampleHarness.rb file followed by the ReportResults.rb file.  I had to wrap the test execution and results reporting in a batch file because the test results aren't complete until the ExampleHarness.rb is finished.  Alternatively, you could just run the ExampleHarness.rb file and then the ReportResults.rb file.


- ReportResults.rb
This is a Ruby script that converts the xml results file created by ci_reporter into a more readable format and places it in the specified directory.  It first adds a line of code to xml results file to specify the xsl stylesheet that will transform the xml to an html report.  It then renames the file with the name specified in the TestData.xls spreadsheet and copies the file out to the results directory (along with the xsl stylesheet if it doesn't already exist there).  Then, the user should be able to open the xml file with a web browser to view the test results.


- transform-results.xsl
This is the xsl stylesheet that transforms the ci_reporter xml to an html report.  It needs to exist in the same directory as the xml file - if it doesn't the ReportResults.rb script will copy it there.  This stylesheet supports IE and Firefox, I haven't tried it with Safari or Opera.


- LogInOut.rb
This Ruby script contains sample test methods for logging in and out of an application.


- CreateAccounts.rb
This Ruby script contains a sample test method for creating accounts in an application.


- DataVerification.rb
This Ruby script contains sample test methods for connecting to SQL and Oracle databases and verifying the data is in the specified table is correct.  Note that for each table tested, a connection to the database is established, all of the values of interest in the table are returned in an array, and then the connection is closed rather than leaving the connection open and using separate get commands for each value.  This is a workaround for issues with the Ruby DBI class.



Customizing and Running
=====================
Unzip all files to the directory from where you would like to run them.

Create test cases for your application and require them in the harness file.  Update the spreadsheet ranges used by the Xls class to include any new tests or parameters added to the spreadsheet.  Add your test cases (named alphabetically in the order you want them to run) to the TestSuite class.  Run the test harness by executing the RunTest.bat file from a command prompt.  NOTE:  If you are using Windows Vista, the command prompt or the user you're logged in with will need admin privileges.

When the test harness is complete, ci_reporter will save the results to the .../test/reports directory (it will create the directory automatically).  The ReportResults.rb file will then modify the xml file to include the stylesheet specification, rename the file and save it in the designated network location.


Questions?
==========
The best way to get most Watir questions answered is through the Watir Google Group at http://groups.google.com/group/watir-general.  I try to check the group daily, but I can be contacted directly at tcfodor@gmail.com, if necessary.
