package MKDoc::Forum::Plugin::View;
use warnings;
use strict;

use base qw /MKDoc::Forum::Plugin::List/;


sub activate
{
    my $self = shift;

    my $uid  = $self->uid()    || return;
    my $mbox = $self->mbox()   || return;

    $::MKD_IMAP && $::MKD_IMAP->connect() or return;
    $::MKD_IMAP->set_mbox ($mbox);
    $::MKD_IMAP->mbox_exists() || return;

    MKDoc::Core::Plugin::activate ($self, @_) || return;

    $self->_prefetch();
    $self->message() || return;
    return 1;
}


sub current_slice
{
    my $self = shift;
    my $uid  = $self->uid() || return; 
    
    my $count;
    for my $slice (@{$self->{slices}})
    {
	for (@{$slice->{uids}})
	{
	    return $slice if ($uid == $_);
	}
    }
   
    return $self->SUPER::current_slice(); 
}


sub message
{
    my $self   = shift;
    my $uid    = $self->uid();
    my $thread = $self->top_thread;
    return $thread->get ($uid);
}


sub mbox
{
    my $self   = shift;
    my $req    = $self->request();
    my $path   = $req->path_info();
    my $hint   = $self->uri_hint();
    my ($mbox) = $path =~ /^\/.$hint\/(.*)\/\d+.html$/;
    return $mbox;
}


sub uid
{
    my $self   = shift;
    my $req    = $self->request();
    my $path   = $req->path_info();

    my $hint   = $self->uri_hint();
    my ($uid)  = $path =~ /^\/.$hint\/.*\/(\d+).html$/;
    return $uid;
}


sub uri
{
    my $self = shift;
    my %args = @_;
    my $mbox = delete $args{'mbox'} || $self->mbox();
    my $uid  = delete $args{'uid'}  || $self->uid();

    my $hint = $self->uri_hint();
    local *location;
    *location = sub { "/.$hint/$mbox/$uid.html" };

    return $self->SUPER::uri (%args);
}


1;


__END__
