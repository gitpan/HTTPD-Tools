#!/usr/local/bin/perl5 -w

use lib qw(blib ../blib ../../blib ./t);

require 'clean';
clean_files();

use HTTPD::UserAdmin ();
use HTTPD::GroupAdmin ();

$Debug = 0;
sub test {
    my($num,$true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

@DBTypes = qw(DBM Text);
eval "use DBI";
if($@) {
    print STDERR "couldn't load DBI, skipping SQL support test\n";
}
else {
    @drivers = DBI->available_drivers();
    if($driver = $driver = $drivers[0]) {
	$SQL = "SQL";
	push(@DBTypes, $SQL);
    }
    else {
	print STDERR "couldn't find a driver for DBI, skipping SQL support test\n";	
    }
}

my %UserSupport = (apache =>   [@DBTypes],
		   ncsa   =>   [qw(DBM Text)],
		   netscape => [qw(DBM)],
		   cern =>     [qw(Text)],
		   );

my %GroupSupport = (apache =>   [qw(DBM Text)],
		    ncsa   =>   [qw(DBM Text)],
		    cern =>     [qw(Text)],
		    );

if(@ARGV) {
    my $server = shift;
    if($server eq 'matrix') {
	&print_matrix();
    }
    else {
	%GroupSupport = %UserSupport = ();
	$GroupSupport{$server} = $UserSupport{$server} = {@ARGV};
    }
}

my $tests = 0;
foreach (keys %UserSupport) {
    $tests += @{$UserSupport{$_}};
}
foreach (keys %GroupSupport) {
    $tests += @{$GroupSupport{$_}};
}

print "1..$tests\n";

foreach $srv (keys %UserSupport) {
    foreach $db (@{$UserSupport{$srv}}) {
	@Attr = (DBType => $db, Server => $srv, Debug => 0);
	test ++$i, ($class = new HTTPD::UserAdmin(@Attr)->class);
	print STDERR "class: $class\n" if $Debug;
    }
}

foreach $srv (keys %GroupSupport) {
    foreach $db (@{$GroupSupport{$srv}}) {
	@Attr = (DBType => $db, Server => $srv);
	test ++$i, ($class = new HTTPD::GroupAdmin(@Attr)->class);
	print STDERR "class: $class\n" if $Debug;
    }
}

clean_files();

sub print_matrix {
    local($^W) = 0;
    my($srv,%support);
    print "User Databases:\n";
    printf "%-15s%s  %s   %s\n", "Server", @DBTypes;
    foreach $srv (keys %UserSupport) {
	%support = map { $_,"x" } @{$UserSupport{$srv}};
	printf "%-15s %s    %s      %s\n", $srv, map { $_ || " " } @support{@DBTypes};
	
    }
    print "\nGroup Databases:\n";
    foreach $srv (keys %GroupSupport) {
	%support = map { $_,"x" } @{$GroupSupport{$srv}};
	printf "%-15s %s    %s      %s\n", $srv, map { $_ || " " } @support{@DBTypes};
	
    }
    exit;
}


__END__
