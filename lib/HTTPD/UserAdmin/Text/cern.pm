package HTTPD::UserAdmin::Text::cern;
@ISA = qw(HTTPD::UserAdmin::Text);

#tweedle dee, tweedle dumb
sub new {
    my($class) = shift;
    HTTPD::UserAdmin::Text::new($class, DLM => ":", @_);
}


1;
