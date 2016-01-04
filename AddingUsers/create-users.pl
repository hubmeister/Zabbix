#!/usr/bin/perl
###############################################################
# Script to automate adding users to Zabbix
# Usage: create-users.pl user.list
# Notes:
# Where user.list is a list of users in a file and the last
# and first name are separated by a space with the last
# name being first on the line.
# Use the script create-users.pl to add users into Zabbix
###############################################################
# check for correct number of arguments and exit if not
bag("Usage: $0 user.list") unless @ARGV == 1;

open(USERS_FILE,"$ARGV[0]") || die "Sorry... Can't open $ARGV[0]:$!\n";

use 5.010;
use strict;
use warnings;
use JSON::RPC::Client;
use Data::Dumper;

# Authenticate yourself
my $client = new JSON::RPC::Client;
my $url = 'https://zabbix-server.com/zabbix/api_jsonrpc.php';

my $authID;
my $response;
my $fname;
my $lname;
my $lcfname;
my $lclname;

# add users from list in file
while (<USERS_FILE>) {
($lname,$fname) = split(/ /,$_);
chomp($fname);
chomp($lname);
# convert to lower case for the alias
$lcfname = lc $fname;
$lclname = lc $lname;
printf " Adding User: %s %s\n",$fname,$lname;

my $json = {
jsonrpc=> '2.0',
method => 'user.create',
params => 
{
alias => "$lcfname.$lclname",
name => "$fname",
surname => "$lname",
passwd => 'changeme',
type => 1,
usrgrps =>
{
usrgrpid => 14
}
},
id => 1,
auth => "847eced3a0d1436118c3e714ca7552d0"
};

$response = $client->call($url, $json);
print Dumper($response);
printf "%s\n",$response;
} #end of while

close(USERS_FILE);
sub bag {
        my $msg = shift;
        $msg .= "\n";
        warn $msg;
        exit 2;
}
