=head1 NAME

MKDoc::Forum - IMAP based discussion boards.

=cut
package MKDoc::Forum;
use warnings;
use strict;

our $VERSION = '0.1';


1;


__END__


=head1 SUMMARY

This module suite provides web forums using the mod_perl L<MKDoc::Core>
framework.  Instead of using an SQL database as a backend, it is designed to
work with courier IMAP. It provides the following features:

=over 4

=item Proper, Efficient message threading

=item Easy administration using any mail client

=item Multiple forums - one per IMAP folder

=item Intuitive, email-like text to HTML markup using L<MKDoc::Text::Structured>

=item Entirely template-driven using L<Petal>

=back


=head1 INSTALLATION

First install the module on your system. If you are using CPAN, this is done
easily:

  perl -MCPAN -e 'install MKDoc::Forum'

Then, you need to go through the following steps:

Have you got an account on a courrier IMAP server? L<MKDoc::Forum> has been
designed to work using a Courier-IMAP backend.

Have you created some folders on your courrier IMAP backend? L<MKDoc::Forum>
uses one folder per forum.

Have you deployed the L<MKDoc::Core> master directory on your system? If not,
see L<MKDoc::Setup::Core> for details.

Have you deployed at least one L<MKDoc::Core> site? If not, see
L<MKDoc::Setup::Site> for details.

Now let's assume that you have installed an L<MKDoc::Core> site in
/var/www/example.com. In order to deploy forums on this site, you need to do
the following:

  source /var/www/example.com/mksetenv.sh
  perl -MMKDoc::Setup -e install_forum

This will take you through the installation procedure. Once this installation
procedure is complete, you need to restart apache.

Then you can point your fave browser to http://www.example.com/.forums.html and
start using the forums.


=head1 AUTHENTICATION

If you have no authentication system, you can use L<MKDoc::Auth> which is fully
compatible with L<MKDoc::Forum>.

However L<MKDoc::Forum> tries to be as authentication independant as possible.
By default, anyonymous postings are enabled and appear as 'Anonymous User'.

If you wish do disable anonymous postings, you can do this at the apache level
by password protecting the URIs which are used for posting new messages. In
order to do so you can edit your site apache configuration:

In /var/www/example.com/httpd/httpd-authenticate.conf, insert:

  # no anonymous posts
  <Location /.forum/*/post.html>
    PerlAuthenHandler Your::Auth::Handler
    AuthName "Please enter your user credentials"
    AuthType Basic
    require valid-user
  </Location>

Alternatively, if you wanted to make it mandatory to be logged in in order to
view or post:

  # no anonymous read or post 
  <Location /.forum/*>
    PerlAuthenHandler Your::Auth::Handler
    AuthName "Please enter your user credentials"
    AuthType Basic
    require valid-user
  </Location>

If the user is somehow authenticated, then $ENV{REMOTE_USER} should be set and
L<MKDoc::Forum> uses this information.

If you also want the user full name and email address to appear, you need to
set a $::MKD_USER object. See L<MKDoc::Auth> for details.


=head1 CUSTOMIZATION

If you don't like the default templates, you can change the look and feel of
your forums by customizing them as appropriate.

In order to do so, you need to copy the default templates in your site
directory as follows:

  mkdir -p /var/www/example.com/resources/templates
  tar zxvf MKDoc-Forum-xx.tgz
  cp -a MKDoc-Forum-xx/lib/MKDoc/templates/* /var/www/example.com/resources/templates

The templates which now live in /var/www/example.com/resources/templates/forum
will be used for the site example.com forums instead of the default ones.

You might also want to customize the templates for all L<MKDoc::Core> sites
rather than one specific site. In this case, simply replace your site directory
by your L<MKDoc::Core> master directory. Those templates will be used for all
the sites instead of the default ones.


=head1 AUTHOR

Copyright 2004 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver <jhiver@mkdoc.com>

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

Related Application / Modules:

  Courier IMAP: http://www.courier-mta.org/
  Mail-IMAPClient: L<Mail::IMAPClient>

  MKDoc-Core: L<MKDoc::Core>
  MKDoc-Auth: L<MKDoc::Auth>
  MKDoc-Text-Structured: L<MKDoc::Text::Structured>
  Petal: L<Petal>


L<MKDoc::Forum> - plugins:

L<MKDoc::Forum::Plugin::MBoxes>, L<MKDoc::Forum::Plugin::List>,
L<MKDoc::Forum::Plugin::View>, L<MKDoc::Forum::Plugin::Post>.


L<MKDoc::Forum> - other modules:

L<MKDoc::Forum::Message>, L<MKDoc::Forum::IMAP::Connection>,
L<MKDoc::Forum::IMAP::Init>, L<MKDoc::Forum::IMAP::Query>,
L<MKDoc::Forum::IMAP::Post>.


What's this all about?

http://www.mkdoc.com/


__END__
