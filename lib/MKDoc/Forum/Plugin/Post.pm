package MKDoc::Forum::Plugin::Post::FakeUser;

sub new
{
   my $class = shift;
   return bless { @_ }, $class;
}


sub full_name
{
    my $self = shift;
    return $self->{full_name};
}


sub login
{
    my $self = shift;
    return $self->{login};
}


sub email
{
    my $self = shift;
    return $self->{email};
}


package MKDoc::Forum::Plugin::Post;
use MKDoc::Forum::IMAP::Post;
use MKDoc::Forum::Message;
use strict;
use warnings;

use base qw /MKDoc::Forum::Plugin::List/;


sub user
{
    my $self = shift;
    
    $::MKD_USER and return $::MKD_USER;
    
    $ENV{REMOTE_USER} and return new MKDoc::Forum::Plugin::Post::FakeUser (
        full_name => $ENV{REMOTE_USER},
        login     => $ENV{REMOTE_USER},
        email     => '',
    ); 
    
    return new MKDoc::Forum::Plugin::Post::FakeUser ( 
        full_name => 'Anonymous User',
        login     => 'anonymous',
        email     => '',
    );
}


sub uri
{
    my $self  = shift;
    my %args  = @_;
    my $mbox  = delete $args{'mbox'} || $self->mbox();
    my $uid   = delete $args{'uid'}  || $self->uid();

    my $hint1 = $self->SUPER::uri_hint();
    my $hint2 = $self->uri_hint();

    local *location;
    *location = defined $uid ?
        sub { "/.$hint1/$mbox/$uid/$hint2.html" } :
        sub { "/.$hint1/$mbox/$hint2.html" }; 

    return $self->SUPER::uri (%args);
}


sub mbox
{
    my $self   = shift;
    my $req    = $self->request();
    my $path   = $req->path_info();

    my $hint1  = $self->SUPER::uri_hint();
    my $hint2  = $self->uri_hint();

    my ($mbox) = $path =~ /^\/.$hint1\/(.*?)\/(?:\d+\/)?$hint2\.html$/;
    return $mbox;
}


sub uid
{
    my $self   = shift;
    my $req    = $self->request();
    my $path   = $req->path_info();

    my $hint1  = $self->SUPER::uri_hint();
    my $hint2  = $self->uri_hint();

    my ($uid)  = $path =~ /^\/.$hint1\/.*?\/(\d+)\/$hint2\.html$/;
    return $uid;
}


sub uri_hint
{
    return $ENV{MKD__FORUM_POST_URI_HINT} || 'post';
}


sub message
{
    my $self = shift;
    my $uid  = $self->uid() || return;
    return MKDoc::Forum::Message->new ($uid) || {};
}


sub http_get
{
    my $self = shift;
    $self->http_get_prefill();
    return $self->SUPER::http_get (@_);
}


sub http_get_prefill
{
    my $self = shift;
    my $msg  = $self->message() || return;
    my $req  = $self->request();

    $req->param ( subject => $msg->subject_re() )          unless (defined $req->param ('subject'));
    $req->param ( message => $msg->body_as_quoted_text() ) unless (defined $req->param ('message'));
}


sub http_post
{
    my $self = shift;
    $self->http_post_validate() or return $self->http_get();
    $self->http_post_message();

    my $list_p = MKDoc::Forum::Plugin::List->new();
    my $uri    = $list_p->uri ( mbox => $self->mbox() );
    my $req = $self->request();
    print $req->redirect ($uri);
    return 'TERMINATE';
}


sub http_post_validate
{
    my $self = shift;
    my $req  = $self->request();
    my $ret  = 1;

    $req->param ('subject') || do {
        new MKDoc::Core::Error 'forum/post/subject_empty';
        $ret = 0;
    };

    $req->param ('message') || do {
        new MKDoc::Core::Error 'forum/post/message_empty';
        $ret = 0;
    };

    return $ret;
}


sub http_post_message
{
    my $self = shift;
    my $req  = $self->request();
    my $msg_obj    = $self->message();
    my $reply_id   = $msg_obj->message_id() if (defined $msg_obj);
    my $references = $msg_obj->references() if (defined $msg_obj);
    chomp ($references) if (defined $references);
    
    # post the message to the imap folder...
    my $subject  = $req->param ('subject');
    my $message  = $req->param ('message');
    my $language = $req->param ('language') || 'en';
   
    if (defined $reply_id and defined $references)
    {
	$reply_id =~ s/^\<*//sm;
	$reply_id =~ s/\>*$//sm;
	MKDoc::Forum::IMAP::Post->post ( {
	    realname    => $self->user()->full_name(),
	    email       => $self->user()->email(),
	    subject     => $subject,
	    message     => $message,
	    language    => $language,
	    in_reply_to => "<$reply_id>",
	    references  => "$references <$reply_id>",
	} );
    }
    elsif (defined $reply_id)
    {
	$reply_id =~ s/^\<*//sm;
	$reply_id =~ s/\>*$//sm;
	MKDoc::Forum::IMAP::Post->post ( {
	    realname    => $self->user()->full_name(),
	    email       => $self->user()->email(),
	    subject     => $subject,
	    message     => $message,
	    language    => $language,
	    in_reply_to => "<$reply_id>",
	    references  => "<$reply_id>",
	} );
    }
    else
    {
	MKDoc::Forum::IMAP::Post->post ( {
	    realname    => $self->user()->full_name(),
	    email       => $self->user()->email(),
	    subject     => $subject,
	    message     => $message,
	    language    => $language,
	} );
    }
}


1;


__END__
