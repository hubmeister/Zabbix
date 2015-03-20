#!/usr/bin/perl
#
# Script to parse the Zabbix xml file and list the hosts/templates/triggers/groups/os
#
# Name: zabbix-trigger-reports.pl
# Author: Dirck Copeland
# Creation Date: 10-31-2013
#
# The zbx_export_hosts.xml and zbx_export_templates.xml files are exported from the Zabbix
# GUI as deacribed below.
#
# Usage: ./zabbix-trigger-reports.pl zbx_export_hosts.xml zbx_export_templates.xml > 
# 				zbx-trigger-report-server-12-03-2014.csv
#
# Purpose and Description:
# This script reads two XML files saved from Zabbix using the syntax above and 
# generates a csv file (actually it's tab seperated because there are commas in 
# the data). It merges data from both XML files. The first XML file contains the host, 
# name, templates and groups and the second XML file contains the triggers associated 
# with each host.
#
# 1) Download the hosts XML file from Zabbix by going to Configuration | Host 
#    page.
# 2) Clear the filter Name/DNS/IP/Port if any are set and in the Group
#    pull down menu, select all. Select the Name box in the upper left 
#    hand corner. This will select hosts on that page only. 
# 3) Move to the next page and select the name box again. This needs to 
#    be repeated for every page.
# 4) Make sure the "Export selected" shows in the pull down menu in the
#    lower left corner of the screen. Select the Go button in the lower left 
#    and this will bring up an save file dialog. 
# 5) Select Save and it will put it in the Downloads folder in a 
#    file called zbx_export_hosts.xml.
# 6) Download the templates XML file from Zabbix by going to Configuration | Templates 
#    page.
# 7) Select the Templates box in the upper left hand corner. This will select 
#    the available templates. Proceed to the next page and repeat if there are mutiple
#    pages of templates.
#    Note: make sure you deselect templates that do not have hosts assigned to them
#          otherwise you will get errors when running this script.
# 8) Make sure the "Export selected" shows in the pull down menu in the
#    lower left corner of the screen. Select the Go button in the lower left 
#    and this will bring up a save file dialog. 
# 9) Select Save and this will put the file in the Downloads folder in a 
#    file called zbx_export_templates.xml
#
#* This program is free software; you can redistribute it and/or modify
#* it under the terms of the GNU General Public License as published by
#* the Free Software Foundation; either version 2 of the License, or
#* (at your option) any later version.
#*
#* This program is distributed in the hope that it will be useful,
#* but WITHOUT ANY WARRANTY; without even the implied warranty of
#* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#* GNU General Public License for more details.
#*
#* You should have received a copy of the GNU General Public License
#* along with this program; if not, write to the Free Software
#* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# flush disk buffer and not wait until it is full.
$| = 1;

# check for correct number of arguments and exit if not
bag("Usage: $0 zbx_export_hosts.xml zbx_export_templates.xml") unless @ARGV == 2;

#*
#* Open xml files
#*
my ($file1) = $ARGV[0];
my ($file2) = $ARGV[1];

# check to make sure files are text
-T $file1 or bag("$file1: binary");
-T $file2 or bag("$file2: binary");

open (F1, $file1) or bag("Couldn't open $file1: $!");
open (F2, $file2) or bag("Couldn't open $file2: $!");

$host_flag=0;
$os_flag=0;
$start_template_flag=0;
$array_index=0;
$first_record=0;
my @trigger_array;
#
# subroutine to print header
#
print_header();
#
# Loop to search and parse the xml file
#
read_hosts_xml();
#
# Print the Header to STDOUT
#
sub print_header {
        printf "HOST\tNAME\t<PRIORITY><SEVERITY><TEMPLATE><TRIGGER><EXPRESSION>\tGROUPS\tIP\tOS\n";
}

#
# Loop through zbx_export_hosts.xml and search for each host. As it
# finds each host, it then gets each template name for that host and 
# finds the template in zbx_export_templates.xml and stores each
# trigger associated with that template/host in the @trigger_array.
# The host is then printed out listing the templates/triggers for
# the respective host.
#

sub read_hosts_xml {
while (<F1>) {
        # Locate the lines with a <host> indicating that it's the beginning of a host entry
	if ( /^            <host>/ ) {
               	$host = $_;
               	$host =~ s/            <host>//;
               	$host =~ s/<\/host>//;
               	chomp($host);
 		printf "%s\t",$host;
		# set host flag - a one time thing to eliminate the group names at the first of the file.
              	$host_flag=1;
	} # end of host
	# Get the Zabbix name that was assigned to that host
        if ( /^            <name>/ && $host_flag != 0 ) {
               	$name = $_;
               	$name =~ s/            <name>//;
               	$name =~ s/<\/name>//;
               	chomp($name);
		# At one time this if statement was needed because the beginning of the host
		# needed a tab and the rest were but with v11 fix, this is no longer needed
        	# this is only for the first NAME in the report. This was left in because
		# further development is needed with certain hosts not printing out the triggers
		# associated with the host and the $first_record flag may be needed then.
                if ($first_record == 0) {
                        # insert tab between TEMPLATES/TRIGGERS and GROUPS on the first host
                        printf "%s\t",$name;
                        $first_record=1;
                } else {
                        # otherwise insert just the host because the following tab is inserted 
			# in the get_template_names subroutine
                        printf "%s\t",$name;
                }
	}# end of name
	# Find the template name that is assigned to this host and get the list of templates
	# and store in $template. Then for each template get the list of trigger by calling
	# the sub get_template_names($template) and store in @trigger_array for later printing. 
	if ( /^            <templates>/ ) {
		$start_template_flag=1;
		while (<F1> ) {
		last if /^            <\/templates>/;
		if ( /^                    <name>/ ) {
			$template=$_;
               		$template =~ s/                    <name>//;
               		$template =~ s/<\/name>//;
               		chomp($template);
			@trigger_array=get_template_names($template);
			push (@trigger_copy,@trigger_array);
               		printf "%s - ",$template; # this is the seperator between the template names
		}
		} # end of while
		# tab between the templates and groups at the beginning of a template
        	printf "\t";
	}# end of templates
	if ( /^            <groups>/ ) {
		while (<F1> ) {
		last if /^            <\/groups>/;
		if ( /^                    <name>/ ) {
			$group=$_;
               		$group =~ s/                    <name>//;
               		$group =~ s/<\/name>//;
               		chomp($group);
               		printf "%s - ",$group;
		}
		} # end of while
		# tab between the group and the IP address
               	printf "\t";
	}# end of groups
	if ( /^            <interfaces>/ ) {
		while (<F1> ) {
		last if /^            <\/interfaces>/;
		if ( /^                    <ip>/ ) {
			$ip=$_;
               		$ip =~ s/                    <ip>//;
               		$ip =~ s/<\/ip>//;
               		chomp($ip);
               		printf "%s\t",$ip;
		}
		} # end of while
	}# end of interfaces
	if ( /^            <inventory>/ ) {
		while (<F1> ) {
		last if /^            <\/inventory>/;
		if ( /<os>/ || /<os\/>/) {
			$os=$_;
               		$os =~ s/                <os>//;
               		$os =~ s/                <os\/>//;
               		$os =~ s/<\/os>//;
               		chomp($os);
               		printf "%s\n",$os;
			$os_flag=0;
		}
		} # end of while
			#If there is no inventory this needs to be repeated in the no inventory section
			for($index = 1; $index <= $#trigger_copy; $index++) {
			# print the two tabs before  printing the Templates and Triggers array associated with each host 
				printf "\t\t%s\t\t\t\t\n",$trigger_copy[$index];
				# 7/24/2014printf "\t%s\t\t\t\t\n",$trigger_copy[$index];
			}
			# Clear out the array for next time
			@trigger_copy=();
	}# end of inventory/os
	# If a host does not have an os in the inventory, need to insert a new line to start the next host
	if ($os_flag == 0 && /<inventory\/>/){
		printf "\n";
			#If there is no inventory the array needs to be printed in this part
			for($index = 1; $index <= $#trigger_copy; $index++) {
			# print the two tabs before  printing the Templates and Triggers array associated with each host 
				printf "\t\t%s\t\t\t\t\n",$trigger_copy[$index];
			}
			# Clear out the array for next time
			@trigger_copy=();
	}
	# when <triggers> is reached, the program can terminate
	if ( /^    <triggers>/ ) {
		close(F1);
		close(F2);
		exit();
	}# end of trigger and end of parsing
} # end of while
} # end of sub to read read_hosts_xml
#
# Subroutine to get the template name from the XML file
#
sub get_template_names {
	my @template_array;
	my ($template) = @_;
	if ($os_flag == 1){
		# insert the tab between the NAME Column and the Template/Triggers Column
		printf "\t";
		$os_flag=0;
	}
	while (<F2>) {
		if ( /^            <expression>{$template/ ) {
			chomp($_);
			$trigger_expression=$_;
			$trigger_expression =~ s/            <expression>{$template://;
			$trigger_expression =~ s/<\/expression>//;
			# get the next line after matching the template name. The XML file
			# contains the trigger name immediatley following the template name.
			my $trigger_name = <F2>;
			chomp($trigger_name);
			$trigger_name =~ s/            <name>//;
			$trigger_name =~ s/<\/name>//;
			# Get the priority by moving the file pointer ahead with <F2> until you reach priority
			$url = <F2>;
			$status = <F2>;
			$priority = <F2>;
			chomp($priority);
			$priority =~ s/            <priority>//;
			$priority =~ s/<\/priority>//;
			$global_priority = eval { $priority };
			$global_priority = $priority; 
			if ( $priority == 1 ) { $priority_string="Information"; }
			elsif ( $priority == 2 ) { $priority_string="Warning"; }
			elsif ( $priority == 3 ) { $priority_string="Average"; }
			elsif ( $priority == 4 ) { $priority_string="High"; }
			else   { $priority_string="Disaster"; }
			$template_constructed = $priority . " - " . $priority_string . " - " . $template . " - " . $trigger_name . " - " . $trigger_expression;
			$array_index++;
			push @template_array,$template_constructed;
		}
	}# end of while reading the template XML
	# rewind the file pointer back to start for next time
	$array_index=0;
	seek(F2,0,0);
	return @template_array;
}
sub bag {
        my $msg = shift;
        $msg .= "\n";
        warn $msg;
        exit 2;
}
