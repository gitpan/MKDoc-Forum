=head1 NAME

MKDoc::Forum::IMAP::Connection - Connection to the IMAP server

=cut
package MKDoc::Forum::IMAP::Connection;
use MKDoc::Forum::Message;
use warnings;
use strict;

use base qw /Mail::IMAPClient/;


=head1 API

=head2 $class->new (%args);

Creates a new L<MKDoc::Forum::IMAP::Connection> object.

L<MKDoc::Init::IMAP> will invoke this method and set it in $::MKD_IMAP,
thus if you are using the L<MKDoc::Core> framework you can access this
object through $::MKD_IMAP.

=cut
sub new
{
    my $class = shift;
    $class = ref $class || $class;
    
    my %args = @_; 
    my $self = $class->SUPER::new();
    $self->{'.connect'} = \%args; 
    return $self;
}


=head2 $self->connect();

Connects to the IMAP server if necessary.

=cut
sub connect 
{
    my $self = shift;
    $self->IsConnected() and return 1;
    $self->_connect_imap();
    $self->_configure_imap_namespace();
    return 1;
}


sub _connect_imap
{
    my $self = shift;
    $self->Server   ( $self->{'.connect'}->{'host'} )     if ( $self->{'.connect'}->{'host'}     );
    $self->User     ( $self->{'.connect'}->{'user'} )     if ( $self->{'.connect'}->{'user'}     );
    $self->Password ( $self->{'.connect'}->{'password'} ) if ( $self->{'.connect'}->{'password'} );
    $self->Port     ( $self->{'.connect'}->{'port'} )     if ( $self->{'.connect'}->{'port'}     );

    $self->SUPER::connect();
    $self->Uid (1);
    $self->IsConnected     or die ("\$imap not connected");
    $self->IsAuthenticated or die ("\$imap not authenticated");
}


sub _configure_imap_namespace
{
    my $self = shift;
    my ($has_ns_capability) = grep /^NAMESPACE$/, $self->capability;
    if ($has_ns_capability)
    {
	my $ns_command = join '', $self->tag_and_run ('NAMESPACE');
	my ($prefix, $delimiter) = $ns_command =~ /(NIL|\".*?\")/gsm;
	unless ($prefix eq 'NIL')
	{
	    $prefix =~ s/^\"//;
	    $prefix =~ s/\"$//;
	    $self->set_prefix ($prefix);
	    
	    $delimiter =~ s/^\"//;
	    $delimiter =~ s/\"$//;
	    $self->set_delimiter ($delimiter);
	    return;
	}
    }
    
    $self->set_prefix ('');
    $self->set_delimiter ('.');
}


sub prefix
{
    my $self = shift;
    return $self->{'.prefix'};
}


sub set_prefix
{
    my $self = shift;
    $self->{'.prefix'} = shift;
}


sub delimiter
{
    my $self = shift;
    return $self->{'.delimiter'};
}


sub set_delimiter
{
    my $self = shift;
    $self->{'.delimiter'} = shift;
}


=head2 $self->mbox();

Returns the mailbox currently used.

=cut
sub mbox
{
    my $self = shift;
    return $self->{'.mbox'};
}


=head2 $self->set_mbox ($mbox);

Sets and selects the mailbox currently used to $mbox.

=cut
sub set_mbox
{
    my $self = shift;
    $self->{'.mbox'} = shift;
    $self->select ($self->mbox_prefixed());
}


sub mbox_exists
{
    my $self = shift;
    my $folder = $self->Folder;
    return $self->exists ($folder);
}


sub mbox_prefixed
{
    my $self = shift;
    my $mbox = shift || $self->mbox();
    return $self->prefix() . $mbox;
}


sub mbox_unprefixed
{
    my $self = shift;
    my $mbox = shift || return $self->mbox();
    my $pref = quotemeta ($self->prefix());
    $mbox =~ s/^$pref//;
    return $mbox;
}


sub folders_unprefixed
{
    my $self = shift;
    my @folders = $self->folders();
    return map { $self->mbox_unprefixed ($_) } @folders;
}


=head2 $self->mbox_create ($mbox);

Attempts to create $mbox. Does nothing if $mbox already exists.

=cut
sub mbox_create
{
    my $self = shift;
    my $mbox = shift;
    $self->create ($self->mbox_prefixed ($mbox));
}


=head2 $self->message_body ($uid);

Returns the message body for the message with uid $uid.

=cut
sub message_body
{
    my $self = shift;
    my $uid  = shift || return;
    my $body_string = $self->body_string ($uid);
    my @lines = split /\n/sm, $body_string;

    # this is obviously a hack...
    pop (@lines) if ($lines[$#lines] =~ /^\s*\)\s*$/);

    return join "\n", @lines;
}


=head2 $self->DESTROY();

Calls $self->disconnect().

=cut
sub DESTROY
{
    my $self = shift;
    $self->disconnect();
}


1;


__END__
