After a session of testing the output from atc_results is a nice snapshot of your test results. However, it is
usually helpful if more detailed information can be gleaned from the specific test result data. As a quick hack at
making this process more automated you can follow the steps below to get a more detailed report.


Typical Job reporting process 

1 - add new common error types to findComErrs as necessary
2 - edit findComErrs and change dates as necessary date and run
3 - cat results from above (comErrs.data1 comErrs.date2 > erlist), optional with new combinegzreport2
4 - edit mk-tpl script in GZBIN to end on todays date ( note start time near bottom of script ) and run
5 - run combinegzreport2 using output from steps 3 & 4 above ( type combingzreport2 to see usage)
6 - edit output from 5 and fill in error reasons not already provided
6a - cd to error log directory specified
6b - look in *.log, or *.ER/OU, or stdout type files and look for errors.
7 - decide on descriptive report name and as txt file.
-


Splunk raw data report

- configure splunk to look for gazebo log input directory
- move data to splunk server
- login into splunk
- click on gazebo appropriate report (don't forget to modify timeframe)
  - GLJobSummary for similar report to atc_results
  - run GenericRawDataReport for basic job info

