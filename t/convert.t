#!/usr/local/bin/perl5 -w

use lib qw(blib ../blib ../../blib);

require HTTPD::UserAdmin;
require HTTPD::GroupAdmin;

sub test {
    my($num,$true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

@CERN =   (DB => "www-cern-users",   Server => "cern", DBType => "Text");
@Apache = (DB => "www-apache-users", Server => "apache");

$cernuser = new HTTPD::UserAdmin @CERN;

while(($name,$pass) = each %Users) {
    $cernuser->add($name, $pass);
}

$apacheuser = $cernuser->convert(@Apache);

@users = $apacheuser->list;
print "1..1\n";
test 1, @users == keys %Users;

BEGIN {
unlink <www-*>;
%Users = qw
(
 dougm	idunno
 perl	jams
 biz	baz
 foo	bar
 bud	beer
	    
);

}
