=head1 NAME

MKDoc::Forum::Message - A forum message object.

=cut
package MKDoc::Forum::Message;
use MKDoc::Forum::IMAP::Query;
use MKDoc::Text::Structured;
use MKDoc::XML::Tagger;
use Date::Manip;
use Encode;
use warnings;
use strict;


=head1 API

=head2 $class->new ( uid => $uid );

Creates a new flo::plugin::Discussion::Message object.
Registers the object in $::MKD_MESSAGES hashref

=cut
sub new
{
    my $class = shift;
    $class = ref $class || $class;
    
    if (@_ == 1) { unshift (@_, 'uid') }
    my $self = bless { @_ }, $class;

    $::MKD_MESSAGES ||= {};    
    $::MKD_MESSAGES->{$self} = $self;
    $self->_fetch_header;
    return $self;
}


=head2 $self->get ($uid);

Returns the message matching $uid if it is somewhere in the tree, undef
otherwise.

=cut
sub get
{
    my $self = shift;
    my $uid = shift;
    return $self if (defined $self->{uid} and $self->{uid} == $uid);
    if (defined $self->{children})
    {
	foreach (@{$self->{children}})
	{
	    my $res = $_->get ($uid);
	    return $res if (defined $res);
	}
    }
    return;
}


=head2 $self->uid();

Returns the UID for this message.

=cut
sub uid
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});
    return $self->{uid};
}


=head2 $self->message_id();

Returns the Message-ID field of the specified message.

=cut
sub message_id
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});
    $self->_fetch_header;
    foreach my $header_key (keys %{$self->{headers}})
    {
	next unless ($header_key =~ /^message-id$/i);
	my $res = $self->{headers}->{$header_key}->[0];
	# Encode::_utf8_on ($res);
	return $res;
    }
    return;
}


=head2 $self->references();

Returns the 'references' field of this message.

=cut
sub references
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});
    $self->_fetch_header;
    foreach my $header_key (keys %{$self->{headers}})
    {
	next unless ($header_key =~ /^references$/i);
	my $res = $self->{headers}->{$header_key}->[0];
	# Encode::_utf8_on ($res);
	return $res;
    }
    return;
}


=head2 $self->date();

Returns the date field of the specified message.

=cut
sub date
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});
    $self->_fetch_header;
    foreach my $header_key (keys %{$self->{headers}})
    {
	next unless ($header_key =~ /^date$/i);
	my $res = $self->{headers}->{$header_key}->[0];
	# Encode::_utf8_on ($res);
	return $res;
    }
    return;
}


=head2 $self->date_w3c();

Returns the date field of the specified message in W3C DTF.

=cut
sub date_w3c
{
    my $self = shift;
    my $res  = '';
    eval {
        # from Date::Manip
	my $date = &ParseDate ($self->date);
	my @date = &UnixDate ($date, qw /%Y %m %d %H %M %S/);
	$res = "$date[0]-$date[1]-$date[2]" . 'T' . "$date[3]:$date[4]:$date[5]Z";
    };
    if ($@ and $@)
    {
	warn $@;
	return '';
    }
    else
    {
	return $res;
    }
}


=head2 $self->subject();

Returns the 'Subject' field of the specified message.

=cut
sub subject
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});
    $self->_fetch_header;
    foreach my $header_key (keys %{$self->{headers}})
    {
	next unless ($header_key =~ /^subject$/i);
	my $res = $self->{headers}->{$header_key}->[0];
	$res = Encode::decode ('MIME-Header', $res);
	# Encode::_utf8_on ($res);
	return $res;
    }
    return;
}


=head2 $self->to();

Returns the 'To' field of this message.

=cut
sub to
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});
    $self->_fetch_header;
    foreach my $header_key (keys %{$self->{headers}})
    {
	next unless ($header_key =~ /^to$/i);
	my $res = $self->{headers}->{$header_key}->[0];
	$res = Encode::decode ('MIME-Header', $res);
	# Encode::_utf8_on ($res);
	return $res;
    }
    return;
}


=head2 $self->from();

Return the 'From' field of the specified message.

=cut
sub from
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});
    $self->_fetch_header;
    foreach my $header_key (keys %{$self->{headers}})
    {
	next unless ($header_key =~ /^from$/i);
	my $res = $self->{headers}->{$header_key}->[0];
	$res = Encode::decode ('MIME-Header', $res);
	return $res;
    }
    return;
}


=head2 $self->language();

Return the 'Content-Language' field of this message.

=cut
sub language
{
    my $self = shift;
    return $self->lang (@_);
}


##
# $self->lang;
# ------------
#   Returns the lang field of the specified message
##
sub lang
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});
    $self->_fetch_header;
    foreach my $header_key (keys %{$self->{headers}})
    {
	next unless ($header_key =~ /^content-language$/i);
	my $res = $self->{headers}->{$header_key}->[0];
        return MKDoc::Core::Language->new ($res);
    }
    
    return MKDoc::Core::Language->new ('en');
}


=head2 $self->name();

Returns the 'name' attribute of the specified message

=cut
sub name
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});
    $self->_fetch_header;

    my $from = $self->from;
    $from =~ s/\<.*//;
    $from =~ s/^\s+//;
    $from =~ s/\s+$//;
    $from =~ s/\"//g;
    $from =~ s/=\?.*?\?=//;
    # Encode::_utf8_on ($from);
    return $from;
}


=head2 $self->body();

Returns the 'body' attribute of the specified message

=cut
sub body
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});

    $self->_fetch_body;
    return $self->{body};
}


=head2 $self->body_hyperlinked();

Returns the body as XHTML, with the addresses being hyperlinked.

=cut
sub body_as_xhtml
{
    my $self  = shift;
    my $text  = $self->body();
    my @links = $text =~ /([a-z]+\:\/\/\S+)/g;
    @links = map { {
        _expr => $_,
        _tag  => 'a',
        href => $_,
    } } @links;

    my $html  = MKDoc::Text::Structured::process ($text);
    return MKDoc::XML::Tagger->process_data ($html, @links);
}


=head2 $self->body_as_quoted_text();

Returns the body as quoted text, useful for replies.

=cut
sub body_as_quoted_text
{
    my $self = shift;
    my $text = $self->body();
    my @lines = split /(?:\n|\r)+/sm, $text;
    return join "\n", map { "> $_" } @lines;
}


=head2 $self->subject_re();

Returns the subject of this mail prefixed with 'Re: ' unless
it's already there. Useful for replies.

=cut
sub subject_re
{
    my $self = shift;
    my $subj = $self->subject();

    $subj =~ /^re:\s/i and return $subj;
    return "Re: $subj";
}


=head2 $self->parent();

Returns the parent message of the current message, or undef if none

=cut
sub parent
{
    my $self = shift;
    $::MKD_MESSAGES ||= {};
    my $parent = $::MKD_MESSAGES->{$self->{parent}};
    return $parent;
}


=head2 $self->children();

Returns the children messages of the current message, or an empty list if none

=cut
sub children
{
    my $self = shift;
    return (wantarray) ? @{$self->{children}} : $self->{children};
}


=head2 $self->prev();

Returns the previous sibling of the current message, or undef if none

=cut
sub prev
{
    my $self = shift;
    my $parent = $self->parent;
    my @children = $parent->children;
    for (my $i=0; $i < @children; $i++)
    {
	next if ($i == 0);
	next unless ($children[$i]->uid);
	return $children[--$i] if ($children[$i]->uid eq $self->uid);
    }
    return;
}


=head2 $self->next();

Returns the next sibling of the current message, or undef
if none

=cut
sub next
{
    my $self = shift;
    my $parent = $self->parent;
    my @children = $parent->children;
    
    for (my $i=0; $i < @children; $i++)
    {
	last if ($i == $#children);
	next unless (defined $children[$i]->uid);
	return $children[++$i] if ($children[$i]->uid eq $self->uid);
    }
    return;
}


##
# $self->_fetch_body;
# -------------------
#   Fetches the current message's body if necessary
##
sub _fetch_body
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});

    $self->{body} ||= $::MKD_IMAP->message_body ( $self->{uid} );
}


##
# $self->_fetch_header;
# ---------------------
#   Fetches the current message's headers, if necessary
##
sub _fetch_header
{
    my $self = shift;
    return unless (defined $self->{uid} and $self->{uid});

    my $uid  = $self->{uid};
    $self->{headers} ||= do {
        $::MKD_MESSAGES_HEADERS_TEMP ||= {};
        $::MKD_MESSAGES_HEADERS_TEMP->{$uid} ||= MKDoc::Forum::IMAP::Query::message_header ($uid);
        $::MKD_MESSAGES_HEADERS_TEMP->{$uid};
    };
}


1;


__END__
