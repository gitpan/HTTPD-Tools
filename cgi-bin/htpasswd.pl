#!/usr/local/bin/perl5 -wT

#use vars (qw($query $cgi $user));
use strict qw(refs subs);
require CGI::Form;
require HTTPD::UserAdmin;

$query = new CGI::Form;
$cgi = $query->cgi;
$CGI::CRLF = "\r\n" unless defined $CGI::CRLF;

if($cgi->var('PATH_INFO')) {
    $file = $cgi->var('PATH_TRANSLATED');
    open(FH, $file) || die "open '$file' $!";
    $fh = \*FH;
}
else { $fh = \*DATA }

%ConfigVars = map { $_,1 } qw(User);
%User = ();
read_config($fh);
$ShowList = "";
$ShowList = delete $User{List} if defined $User{List};

$user = new HTTPD::UserAdmin (%User);

print  $query->header,
       $query->start_html('HTTPD Admin'),
       $query->startform(-script => $cgi->var('SCRIPT_NAME')),
       user_admin($cgi->var('REQUEST_METHOD')),
       $query->endform, 
       $query->end_html;

sub user_admin {
    my($method) = @_;
    my($resp,@html,$user_list,$append);
    if($method eq "POST") {
	no strict;
	$resp = &{"user_" . $query->param('POSTACTION')};
    }
    unless ($ShowList =~ /^off$/i) {
	my(@users) = $user->list;
	$user_list = "Users: " . 
	    $query->scrolling_list(-name => 'USERS',
				   -values => [sort @users],
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
	 buttons(),
	 result($resp),
	 );
    join $CGI::CRLF, @html;
}		 

sub user_add {
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
    my(@retval) = "<p><hr>";
    foreach(qw(add delete update help)) {
	push(@retval, $query->submit('POSTACTION', $_));
    }
    @retval;
}

sub read_config {
    my($fh) = @_;
    my($hash,$key,$val);
    no strict 'refs';
    while(<$fh>) {
	clean(*_); next if /^$/;
	($hash,$key,$val) = split;
	unless(defined $ConfigVars{$hash}) {
	    die "Unknown configuration directive '$hash'";
	}
	$$hash{$key} = $val;
    }
}

sub clean { local(*_) = @_; chomp; s/#.*//; s/^\s+//; s/\s+$/ /; }

__END__

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



