package HTTPD::GroupAdmin::DBM::apache;
@ISA = qw(HTTPD::GroupAdmin::DBM::_generic);
require Carp;

sub add {
    my($self,$uid,$group) = @_;
    local($HTTPD::GroupAdmin::DBM::_generic::DLM) = ",";
    $group ||= $self->{NAME};
    HTTPD::GroupAdmin::DBM::_generic::add($self,$group,$uid);
}

sub delete {
    my($self,$uid,$group) = @_;
    local($HTTPD::GroupAdmin::DBM::_generic::DLM) = ",";
    $group ||= $self->{NAME};
    HTTPD::GroupAdmin::DBM::_generic::delete($self,$group,$uid);
}

sub exists {
    my($self, $name) = @_;
    Carp::carp(sprintf "%s::exists() not implemented!\n", $self->class);
    return 0;
}
