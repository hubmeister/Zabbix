#!/usr/bin/perl

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

my $json = {
jsonrpc=> '2.0',
method => 'usergroup.get',
params =>
{
output => 'extend'
},
id => 2,
auth => "847eced3a0d1436118c3e714ca7552d0",
};
$response = $client->call($url, $json);

# Check if response was successful
die "usergroup.get failed\n" unless $response->content->{result};

print "List of Groups\n-----------------------------\n";
foreach my $usergroup (@{$response->content->{result}}) {
print "Group ID: ".$usergroup->{usrgrpid}." Name: ".$usergroup->{name}."\n";
