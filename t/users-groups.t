#!/usr/local/bin/perl5 -w

use lib qw(blib ../blib ../../blib lib);
use File::Basename;
require HTTPD::UserAdmin;

sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

$path = dirname($0);
$username = shift || "dougm";
$groupname = shift || "www";

@Text = @DBM = @SQL = ();
@Text = (DBType => "Text", Path => $path, Server => "cern");

@DBM = (DBType => "DBM", Path => $path);

@SQL = (DBType => "SQL",
	Host => "",                  #server hostname
	DB => "test",                #database name
	Usertable => "auth_users",   #table with field names below
	NameField => "user",         #field for the name
	PasswordField => "password", #field for the password
	Driver => "mSQL",            #driver for DBI
	User => "",		     #login info for database server
	Auth => "",
	);

@CERN = (Server => "cern", DBType => "Text", DB => "www-cerndb", Path => $path);

$user = new HTTPD::UserAdmin @DBM, DEBUG => 0;

print "1..15\n";
#$user->debug(1);
$pfile = "";
test 1, ($pfile = $user->db());
test 2, $user->add($username, "password", '');
test 3, $user->exists($username);
test 4, $user->add($username . $$, "pas");
test 5, $user->exists($username . $$);

@users = $user->list;
#foreach (@users) {
#    print "\t$_\n";
#}
test 6, @users+0;

test 7, $user->delete($username . $$);

test 8, $user->db(".htpasswd-new");
test 9, $user->add($username, "password");


#require HTTPD::GroupAdmin;
#$group = new HTTPD::GroupAdmin (Name => $groupname, @Text);

#$group = $user->group(Name => $groupname, @DBM, SERVER => "apache", DEBUG => 1);
$group = $user->group(Name => $groupname, @Text);

test 10, $group->add($username);
#foreach ("A".."E") { $group->add($username, $_) }
@groups = $group->list();
test 11, @groups+0;
test 12, $group->list($groups[0]);
test 13, $group->delete($username);

test 14, $cern = new HTTPD::UserAdmin @CERN;
test 15, $cern->add('tbl', "password", '', "Tim Berners-Lee");

print "groups: @groups\n";
#foreach (@groups) {
#    @members = $group->list($_);
#    printf "members in group '%s':%s\n", $_, join("|", @members);;
#}

BEGIN {
@files = (<t/.htpasswd*>, <t/.htgroup*>, 't/www-cerndb');
#print "unlinking @files\n";
unlink @files;
}
