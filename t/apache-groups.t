use lib qw(./lib ./t);
use File::Basename;
use HTTPD::GroupAdmin ();

sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

$path = dirname($0);
$i = 0;
require 'clean';
clean_files();

print "1..30\n";

for $dbtype (qw(Text DBM)) {
    my $group = HTTPD::GroupAdmin->new(
		   DBType => $dbtype,
 	           Server => "apache",
		   Path => $path);

    test ++$i, $group;
    
    @groups = qw(apples oranges);
    test ++$i, !$group->exists("nowaycouldthisbeintheresaysI");

    for (@groups) {
	test ++$i, $group->create($_);
    }

    for $user (qw(onefish twofish)) {
	for (@groups) {
	    test ++$i, $group->add($user => $_);
	}
    }
    
    for $user (qw(onefish twofish)) {
	for (@groups) {
	    ($rc,$msg) = $group->add($user => $_); 
	    test ++$i, !$rc, $msg;
	}
    }
 
    test ++$i, $group->commit;
    #system "cat", $group->db;

    $group->flags("r");

    test ++$i, $group->list == @groups;

    for ($group->list) {
	print "$_ = ", join " ", $group->list($_), $/;
    }
    
    test ++$i, !$group->commit;

}

clean_files();
