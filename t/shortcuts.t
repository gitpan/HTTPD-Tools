use lib qw(./lib ./t);
use File::Basename;
use HTTPD::UserAdmin ();

sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

$path = dirname($0);
$i = 0;
print "1..24\n";

require 'clean';
clean_files();

@users = qw(one two three four five);
@groups = qw(groupone grouptwo);

open FH, ">$path/group" or die;
for (@users) {
    print FH "groupone:$_\n";
}
close FH;

system cat => "$path/group";

for $iter (1..2) {
    my $u = HTTPD::UserAdmin->new(
               DB      => "$path/passwd",
               DBType  => "Text",
               Server  => "apache",
 	       Locking => 0) or die;

    my $g = $u->group(DB => "$path/group") or die;
    test ++$i, $g;
    for (@users) {
	test ++$i, $g->exists($groups[0], $_);
	print "EXISTS '$groups[0]:$_'-> ", $g->exists($groups[0], $_), $/;
    }
    test ++$i, !$g->exists($groups[0], $$);

    unless ($iter > 1) {
	for (@users) {
	    test ++$i, $u->add($_,$_);
	}
	for (@groups) {
	    #for $name (@users) {
		#$g->add($name, $_);
	    #}
	}
	#$g->commit;
	test ++$i, $u->commit;
    }

    for ($g->list) {
	print "$_ = ", join " ", $g->list($_), $/;
    }

    $p = $g->user(DB => "$path/passwd"); 
    test ++$i,
    ("@{[ $g->list() ]}" eq "@{[ $p->group(DB => qq'$path/group')->list() ]}");

    test ++$i,
    ("@{[ $p->list() ]}" eq "@{[ $g->user(DB => qq'$path/passwd')->list() ]}");

    
}

#for (qw(t/passwd t/group)) { unlink $_; }
clean_files();

