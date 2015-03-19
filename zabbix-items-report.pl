#!/usr/bin/perl
#
# Script to parse the Zabbix xml file and list the templates/items/triggers
#
# Name: zabbix-items-report.pl
# Author: Dirck Copeland
# Creation Date: 2/24/2014
# Update Date: 3/18/2015
# Version:0.8
#
# The zbx_export_templates.xml file is exported from the Zabbix
# GUI as described below.
#
# Usage: ./zabbix-items-report.pl zbx_export_templates.xml > zbx_items_report_server-04-14-2014.csv
#
# Purpose and Description:
# This script reads the XML file saved from Zabbix using the syntax above and 
# generates a csv file (actually it's tab seperated because there are commas in 
# the data). 
# The file contains the item template, item, trigger.
#
# 1) Download the templates XML file from Zabbix by going to Configuration | Templates 
#    page.
# 2) Select the Templates box in the upper left hand corner. This will select 
#    the available templates.
#    Note: make sure you deselect temnplates that do not have hosts assigned to them
#          otherwise you will get errors when running this script.
# 3) Make sure the "Export selected" shows in the pull down menu in the
#    lower left corner of the screen. Select the Go button in the lower left 
#    and this will bring up an save file dialog. 
# 4) Select Save and this will put the file in the Downloads folder in a 
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
bag("Usage: $0 zbx_export_templates.xml") unless @ARGV == 1;

#*
#* Open xml file
#*
my ($file1) = @ARGV[0];

# check to make sure files are text
-T $file1 or bag("$file1: binary");

open (F1, $file1) or bag("Couldn't open $file1: $!");

$template_flag=0;
$item_flag=0;
$trigger_flag="FALSE";

#
# subroutine to print header
#
print_header();
#
# Loop to search and parse the xml file
#
read_template_xml();
#
# Print the Header to STDOUT
#
sub print_header {
        printf "TEMPLATE\tITEM\tKEY\tTRIGGERS\tSTATUS\tPRIORITY\tDESCRIPTION\tINTERVAL\tHISTORY\tTRENDS\tKB-ARTICLE\tNOTIFY\n";
}

#
# Loop to search and parse the input XML file
#

sub read_template_xml {
while (<F1>) {
        # Locate the lines with a <template> indicating that it's the beginning of a template entry
        if ( /^            <template>/ ) {
		# set template flag - 1 is start of template - 0 is end of template
		$template_flag=1;
		$item_flag=0;
               	$template_start = $_;
               	$template = $_;
               	$template =~ s/            <template>//;
               	$template =~ s/<\/template>//;
               	chomp($template);
               	printf "%s",$template;
	} # end of template

        if ( /^                <item>/ ) {
		$item_flag=1;
		my $item_name = <F1>;
		$item_name =~ s/                    <name>//;
		$item_name =~ s/<\/name>//;
		chomp($item_name);
        	printf "\t%s\t",$item_name;
		if ($template_flag == 1) {
			$template_flag=0;
		}else{
			$template_flag=0;
		}
		# loop through each item and print the key, trigger, delay, host, and trends
		LINE: while (<F1> ) {
			if ( /<key>/ ) {
				$key_name=$_;
				$key_name=~s/                    <key>//;
				$key_name=~s/<\/key>//;
				chomp($key_name);
        			printf "%s\t",$key_name;
				# need to add an extra [ if the key contains is because of the way the 
				# wiki page parses and displays the [] combination.
				# construct the trigger name so you can search the XML to find 
				# a trigger name associated with the key name. There may potentially
				# be two or more triggers associated with a single trigger.
				$trigger=$template.":".$key_name;
				# need to escape the backslash otherwise the trigger name does not
				# match correctly 

				# currently there is an issue with the OS Windows template
				# It's best to not include it in the export for now.
				if ( $trigger ne "Template OS Windows" ) {
					$trigger=~s/\[/\\[/;
					$trigger=~s/\]/\\]/;
				}
				# get the current position of the file pointer and
				# store it in $curpos so you can come back to it 
				# after you search for the trigger and get related 
				# information near the end of the XML file.
				$curpos = tell(F1);
				$trigger_count=0;
				while (<F1>) {
					#$_=~s/\\/BS_/;
					if ( /$trigger/ ) {
						# OK, you've found a trigger, now print it
						$trig_expression=$_;
						$trig_expression=~s/            <expression>//;
						$trig_expression=~s/<\/expression>//;
						chomp($trig_expression);
						########## get name of trigger #################
						my $template_name = <F1>;
                        			chomp($template_name);
						########## get url of trigger #################
						my $template_url = <F1>;
                        			chomp($template_url);
						########## get status of trigger #################
						my $template_status = <F1>;
                        			chomp($template_status);
						$template_status=~s/            <status>//;
						$template_status=~s/<\/status>//;
						if ( $template_status eq "0" ) {
							$trig_stat="Enabled";
						} else {
							$trig_stat="Disabled";
						}
						########## get priority of trigger ################
						my $template_priority = <F1>;
                        			chomp($template_priority);
						$template_priority=~s/            <priority>//;
						$template_priority=~s/<\/priority>//;
						if ( $template_priority eq "0" ) {
							$trig_prio="Not Classified";
						} 
						if ( $template_priority eq "1" ) {
							$trig_prio="Information";
						} 
						if ( $template_priority eq "2" ) {
							$trig_prio="Warning";
						} 
						if ( $template_priority eq "3" ) {
							$trig_prio="Average";
						} 
						if ( $template_priority eq "4" ) {
							$trig_prio="High";
						} 
						if ( $template_priority eq "5" ) {
							$trig_prio="Disaster";
						} 
						########## get description of trigger #################
						my $template_desc = <F1>;
                        			chomp($template_desc);
						$template_desc=~s/            <description>//;
						$template_desc=~s/<\/description>//;
						$template_desc=~s/<description\/>//;
						### if this is the first trigger for the item, print it ###
						if ( $trigger_count == 0 ) {
							printf "%s\t",$trig_expression;
							printf "%s\t",$trig_stat;
							printf "%s\t",$trig_prio;
							printf "%s\t",$template_desc;
							$trigger_flag="TRUE";
							$trigger_count++;
						# otherwise print the second or more triggers for this item
						# and inset the correct number of tabs to keep the formatting 
						# correct
						} else {
							# need to add tab(s) here if adding columnss after
							# the trigger expression - $trig_expression.
							# This only applies to columns containing data from
							# the XML file. Not columns simple being added to the
							# header.
							printf "\t\t\t\n\t\t\t"; 
							printf "%s\t",$trig_expression;
							printf "%s\t",$trig_stat;
							printf "%s\t",$trig_prio;
							printf "%s\t",$template_desc;
						}
					} # end of trigger
				}
				# if adding columns after the trigger expression column, add tab(s) here
				# after the Status N/A
				if ( $trigger_flag ne 'TRUE') {
					printf "NO TRIGGER\tStatus N/A\t\t\t";
				}
				# return to the position you were prior to the search
				seek(F1, $curpos, 0);
			}
			if ( /<delay>/ ) {
				$delay_name=$_;
				$delay_name=~s/                    <delay>//;
				$delay_name=~s/<\/delay>//;
				chomp($delay_name);
        			printf "%s\t",$delay_name;
			}
			if ( /<history>/ ) {
				$history_name=$_;
				$history_name=~s/                    <history>//;
				$history_name=~s/<\/history>//;
				chomp($history_name);
        			printf "%s\t",$history_name;
			}
			if ( /<trends>/ ) {
				$trends_name=$_;
				$trends_name=~s/                    <trends>//;
				$trends_name=~s/<\/trends>//;
				chomp($trends_name);
        			printf "%s\n",$trends_name;
			}
			last LINE if ( /                <\/item>/ );	
        			#printf "KEY:%s\n",$_;
		$trigger_flag="FALSE";
		} # end of ITEM while
	}# end of item_name
} # end of while <F1>
} # end of sub to read read_template_xml
sub bag {
        my $msg = shift;
        $msg .= "\n";
        warn $msg;
        exit 2;
}
close(F1);
