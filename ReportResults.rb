#****************************************************************************#
# ReportResults.rb
#
# Author: Tiffany Fodor
# Date: 09/15/2008
# Description:  Script to modify results file to include the xsl stylesheetand 
#      copy it out to the network
#
# Change history:
#
# 09/15/2008 - Initial Development
#
#****************************************************************************#
require 'win32ole' # the win32 module
require 'watir'   # the watir controller
require 'watir/contrib/Xls'
require 'fileutils'
include FileUtils

begin
    $dir = File.dirname(__FILE__).gsub('/','\\')
    xlFile = XLS.new("#{$dir}\\TestData.xls")
    
    setupInfo = xlFile.getHash('A1:B8', 'Setup') 
ensure
    xlFile.close
end 

resultsDir = setupInfo['ResultsDir']
buildInfo = setupInfo['BuildInfo']

if File.exist?("#{resultsDir}\\transform-results.xsl") == false
    copy("#{$dir}\\transform-results.xsl", resultsDir)
end    

resultsFile = "#{$dir}\\test\\reports\\TEST-TestSuite.xml"

if File.exist?("#{$dir}\\test\\reports\\TEST-TestSuite.xml")
    sContent = File.readlines(resultsFile, '\n')
    sContent.each do |line|
        line.sub!(/<\?xml version=\"1.0\" encoding=\"UTF-8\"\?>/, "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \n<?xml-stylesheet type=\"text\/xsl\" href=\"transform-results.xsl\"?>")
    end
    
    xmlFile = File.new("#{$dir}\\test\\reports\\#{buildInfo}.xml", "w+")
    xmlFile.puts sContent
    xmlFile.close
end

FileUtils.copy("#{$dir}\\test\\reports\\#{buildInfo}.xml", resultsDir)

