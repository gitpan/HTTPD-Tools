#!/usr/local/bin/perl5 -wT
use vars qw(%User %ConfigVars $ShowList);
use strict;
#CGI::Switch comes with mod_perl, for switching between CGI and mod_perl
#if you only wish to run under CGI, you may replace `CGI::Switch' with `CGI'
use CGI::Switch ();
use HTTPD::UserAdmin ();
use FileHandle ();

$^W=1;
my $query = new CGI::Switch;

%ConfigVars = map { $_,1 } qw(User);
%User = ();
my $fh;
if($query->path_info) {
    my $file = $query->path_translated;
    $fh = FileHandle->new($file) || die "open '$file' $!";
}
read_config($fh);
$ShowList = "";
$ShowList = delete $User{List} if defined $User{List};

my $user = new HTTPD::UserAdmin (%User);

$query->print($query->header,
       $query->start_html('HTTPD Admin'),
       $query->startform(-script => $query->script_name),
       user_admin($query,$user),
       $query->endform, 
       $query->end_html);

sub user_admin {
    my($query, $user) = @_;
    my $method = $query->request_method;
    my($resp,@html,$user_list,$append);
    if($method eq "POST") {
	no strict;
	$resp = &{"user_" . $query->param('POSTACTION')}($query,$user);
    }
    unless ($ShowList =~ /^off$/i) {
	my(@users) = $user->list;
	$user_list = "Users: " . 
	    $query->scrolling_list(-name => 'USERS',
				   '-values' => [sort @users],
				   -size => 2,
				   -multiple => 1,
				   );
    }
    if (defined $user->{ENCRYPT}) {
	$query->delete('REALM');
	if ($user->{ENCRYPT} eq 'MD5') {
	    $append .= "<BR>Realm: " . $query->textfield('REALM');
	}
    }
    #flush form state
    foreach (qw(USERNAME USERS PASSWD_1 PASSWD_2)) {
	$query->delete($_);
    }
 
    push(@html,  
	 "<H3>User Admin</H3>",
	 "Database: <b>" . $user->db . "</b><p>",
	 $user_list,
	 "<HR>",
	 "<BR>Username: " . $query->textfield('USERNAME'),
	 "<BR>Password: ", (map { $query->password_field('PASSWD_' . $_) } 1,2),
	 $append,
	 buttons($query, $user),
	 result($resp),
	 );
    join $CGI::CRLF, @html;
}		 

sub user_add {
    my($query, $user) = @_;
    my($passwd,$passwd2,$username) = map { $query->param($_) } qw(PASSWD_1 PASSWD_2 USERNAME);
    return "No user specified!"     unless $username;
    return "No password specified!" unless ($passwd && $passwd2);
    return "Passwords don't match!" unless ($passwd eq $passwd2);
    my $realm;
    if($realm = $query->param('REALM')) {
	$passwd = join(":", $username, $realm, $passwd);
    }
    my($rc,$msg) = $user->add($username,$passwd);
    return $msg || "User '$username' added";
}

sub user_delete {
    my($query, $user) = @_;
    my(@usernames) = $query->param('USERS');
    return "Select users from the list to delete!" unless @usernames;
    my($rc,$msg);
    foreach (@usernames) {
	($rc,$msg) = $user->delete($_);
	return $msg unless $rc;
    }
    return join(", ",@usernames) . " deleted";
}

sub user_update {
    my($query, $user) = @_;
    my($passwd,$passwd2,$username) = map { $query->param($_) } qw(PASSWD_1 PASSWD_2 USERNAME);
    $username ||= $query->param('USERS');
    return "No user specified!" unless $username;
    return "No password specified!" unless ($passwd && $passwd2);
    return "Passwords don't match!" unless ($passwd eq $passwd2);
    my $realm;
    if($realm = $query->param('REALM')) {
	$passwd = join(":", $username, $realm, $passwd);
    }
    my($rc,$msg) = $user->update($username,$passwd);
    return $msg || "User '$username' password updated"; 
}

sub user_help {
    "Sorry, no help available yet.";
}

sub result { "<p><b>@_</b>\n" }

sub buttons {
    my($query, $user) = @_;
    my(@retval) = "<p><hr>";
    foreach(qw(add delete update help)) {
	push(@retval, $query->submit('POSTACTION', $_));
    }
    @retval;
}

my $default = <<'EOF';
User    DB      www-users
User    DBType  DBM
User    Server  apache
#User    Encrypt MD5

#un-comment this when your browser has trouble handling all that list markup
#User   List   off

#Implement this later
#Group   DB      www-groups
#Group   DBType  DBM
#Group   Server  apache

EOF

sub read_config {
    my($fh) = @_;
    my($hash,$key,$val,@config);
    @config = ref $fh ? <$fh> : split /\n+/, $default;
    no strict 'refs';
    local $_;
    for (@config) {
	chomp; s/\#.*//; s/^\s+//; s/\s+$/ /; next if /^$/;
	($hash,$key,$val) = split;
	unless(defined $ConfigVars{$hash}) {
	    die "Unknown configuration directive '$hash'";
	}
	$$hash{$key} = $val;
    }
}


