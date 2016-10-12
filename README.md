This is a repository for all my zabbix related stuff.
This index helps determine which files may be useful to you.

ZABBIX-2.2-ERD.svg is a SVG file that is an Entity Relationship Diagram for Zabbix 2.2.
zabbix-items-report.pl is a perl script that generates an item report
zabbix-trigger-report.pl is a perl script that generates a trigger report

Some API examples will be added shortly

To get the scripts to work yo need to install the perl module JSON::RPC::Client
this can be done through CPAN like:
cpan[1]> install JSON::RPC::Client


Adding Zabbix Users using the API:

In the AddingUsers directory the script auth-zabbix.pl is used to get an authentication 
code to authenticate to the API.

Edit the script to fill in you relavant data (i.e. Zabbix URL, username, password)
and run the script and you should see something like:

./auth-zabbix.pl
Authentication successful. Auth ID: 847eced3a0d1436118c3e714ca7552d0


Next the assumption is you would like to add the users to a specif group so the
script list-users-groups.pl will list out all the groups on the Zabbix server.
(Note: make sure you replace the auth code 847eced3a0d1436118c3e714ca7552d0
 in the script with the one generated for your server)
Running the script should produce output something like:
    
    root@lt-dcopeland:/home/dirck/API# ./list-users-groups.pl 
    List of Groups
    -----------------------------
    Group ID: 1 Name: UNIX administrators
    Group ID: 2 Name: Database administrators
    Group ID: 3 Name: Network administrators
    Group ID: 4 Name: Security specialists
    Group ID: 5 Name: WEB administrators
    Group ID: 6 Name: Head of IT department
    Group ID: 9 Name: Disabled
    Group ID: 8 Name: Guests
    Group ID: 10 Name: API access
    Group ID: 12 Name: Backend
    Group ID: 7 Name: Zabbix administrators
    Group ID: 11 Name: Programmers
    Group ID: 14 Name: Company Support
    Group ID: 13 Name: Company


Next the actual script to create the users. Here is the specifics:

the create-users.pl script contains the folling code:


Next, you should have a list of users to add in a file - call it user.list-2-23-2015 (or whatever date is current) and the list will be in the form Last-Name First-Name:

    Doe John
    Doe Jane

Next run the command:

 ./create-users.pl user.list-2-23-2015 
and you should see something like:

    ./create-users.pl user.list-2-23-2015
    
     Adding User: John Doe
    $VAR1 = bless( {
                     'version' => 0,
                     'is_success' => 1,
                     'content' => {
                                    'jsonrpc' => '2.0',
                                    'id' => 1,
                                    'result' => {
                                                  'userids' => [
                                                                 '88'
                                                               ]
                                                }
                                  },
                     'jsontext' => '{"jsonrpc":"2.0","result":{"userids":["88"]},"id":1}'
                   }, 'JSON::RPC::ReturnObject' );
    JSON::RPC::ReturnObject=HASH(0x24df950)
     Adding User: Jane Doe
    $VAR1 = bless( {
                         'is_success' => 1,
                         'content' => {
                                        'result' => {
                                                  'userids' => [
                                                                 '89'
                                                               ]
                                                },
                                    'id' => 1,
                                    'jsonrpc' => '2.0'
                                  },
                     'jsontext' => '{"jsonrpc":"2.0","result":{"userids":["89"]},"id":1}',
                     'version' => 0
                   }, 'JSON::RPC::ReturnObject' );
    JSON::RPC::ReturnObject=HASH(0x26da5b8)
