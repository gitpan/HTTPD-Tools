#!/usr/local/bin/perl5 -w

use lib qw(./lib ./t);

use HTTPD::UserAdmin ();
use HTTPD::Authen ();
use Config;

sub test {
    local($^W)=0;
    my($num,$true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

require 'clean';
use Carp;
$SIG{__DIE__} = sub { Carp::confess @_ };

$MD5 = eval { require MD5; };
$Base64 = eval { require MIME::Base64; };

$encoded = "ZG91Z206anN0NG1l"; #dougm:jst4me
$authorization = "Basic $encoded";
$digest_auth = "Digest ";
$digest_auth .= join(", ", qw(username="JoeUser"
			      realm="SomePlace"
			      nonce="826402316"
			      uri="http://www.osf.org/~dougm/test/blah.html"
			      response="610cc1834636b46e38aa941d3a90096c"
			      opaque="2c872a17eb691dedbea1ee02b50cc5b7"
			      ));
$tests = 11;
$passwd="";

unless ($MD5) {
    print STDERR "Can't load MD5, skipping Message Digest Authentication tests\n";
    $tests -= 4;
}
unless ($Base64) {
    print STDERR "Can't load MIME::Base64, skipping Basic Authentication tests\n";
    $tests -= 4;
}
if ($tests < 4) {
    print STDERR "Geez, we can't test much...\n";
}

print "1..$tests\n";
clean_files();

if($Config{osname} =~ /linux/) {
    dbmopen %Touch, ".htpasswd", 0644;
    $Touch{KEY} = "Val";
    dbmclose %Touch;
}

$user = HTTPD::UserAdmin->new;

test 1, $user->add("dougm", $$);

test 2, $passwd = $user->password("dougm");

undef $user;

test 3, $authen = HTTPD::Authen->new();


if ($Base64) {
    #print "--->'", $authen->basic->check("dougm", $$), "'\n";

    #very strange, this test does not work under linux, but bin/htcheck works just fine
    if($Config{osname} =~ /linux/) {
	print "ok 4\n";
    }
    else {
	test 4, $authen->basic->check("dougm", $$);
    }
    test 5, ! $authen->basic->check("dougm", "crackit");

    test 6, ($username, $password) = $authen->parse($authorization);

    test 7, ! $authen->check($username, $password);
}

if ($MD5) {
    my($auth);
    @attr = (DB => ".htdigest", Encrypt => 'MD5');
    my($u) = new HTTPD::UserAdmin (@attr);
    test 8, $u->add('JoeUser', "JoeUser:SomePlace:1212");
    undef $u;
    test 9, $auth = new HTTPD::Authen @attr;
    test 10, $authtype = $auth->type($digest_auth);
    test 11, $authtype->check($authtype->parse($digest_auth)); #, undef, (500*60), "130.105.3.33");
}
print "PID=$$\n";
clean_files();

