package POE::Component::IRC::Plugin::TinyURL;

use strict;
use warnings;
use POE;
use POE::Component::Client::HTTP;
use POE::Component::IRC::Plugin qw(:ALL);
use URI::Find;
use HTTP::Request;
use vars qw($VERSION);

$VERSION = '1.08';

sub new {
  my $package = shift;
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;
  return bless \%args, $package;
}

sub PCI_register {
  my ($self,$irc) = @_;
  $self->{irc} = $irc;
  $irc->plugin_register( $self, 'SERVER', qw(spoof) );
  $irc->plugin_register( $self, 'SERVER', qw(public) );
  unless ( $self->{http_alias} ) {
	$self->{http_alias} = join('-', 'ua-tiny', $irc->session_id() );
	$self->{follow_redirects} ||= 2;
	POE::Component::Client::HTTP->spawn(
	   Alias           => $self->{http_alias},
	   Timeout         => 30,
	   FollowRedirects => $self->{follow_redirects},
	);
  }
  $self->{session_id} = POE::Session->create(
	object_states => [ 
	   $self => [ qw(_shutdown _start _uri_find _uri_found _get_headline _response) ],
	],
  )->ID();
  return 1;
}

sub PCI_unregister {
  my ($self,$irc) = splice @_, 0, 2;
  $poe_kernel->call( $self->{session_id} => '_shutdown' );
  delete $self->{irc};
  return 1;
}

sub S_public {
  my ($self,$irc) = splice @_, 0, 2;
  my $who = ${ $_[0] };
  my $channel = ${ $_[1] }->[0];
  my $what = ${ $_[2] };
  $poe_kernel->call( $self->{session_id}, '_uri_find', $irc, $who, $channel, $what );
  return PCI_EAT_NONE;
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  $kernel->refcount_increment( $self->{session_id}, __PACKAGE__ );
  undef;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alarm_remove_all();
  $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ );
  $kernel->call( $self->{http_alias} => 'shutdown' );
  undef;
}

sub _uri_find {
  my ($kernel,$session,$self,$irc,$who,$channel,$what) = @_[KERNEL,SESSION,OBJECT,ARG0..ARG3];
  my $finder = URI::Find->new( $session->callback( '_uri_found', $irc, $who, $channel, $what ) );
  $finder->find( \$what );
  undef;
}
 
sub _uri_found {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my ($irc,$who,$channel,$what) = @{ $_[ARG0] };
  my ($uriurl,$url) = @{ $_[ARG1] };
# ignore short urls
  return unless length $url > 60;
  $kernel->call( $self->{session_id}, '_get_headline', { url => $url, _channel => $channel });

  undef;
}

sub _get_headline {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my %args;
  if ( ref $_[ARG0] eq 'HASH' ) {
     %args = %{ $_[ARG0] };
  } else {
     %args = @_[ARG0..$#_];
  }
  $args{lc $_} = delete $args{$_} for grep { !/^_/ } keys %args;
  return unless $args{url};
  $args{irc_session} = $self->{irc}->session_id();
  $kernel->post( $self->{http_alias}, 'request', '_response', HTTP::Request->new( GET => 'http://www.tinyurl.com/api-create.php?url=' . $args{url} ), \%args );
  undef;
}

sub _response {
  my ($kernel,$self,$request,$response) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $args = $request->[1];
  my @params;
  push @params, delete $args->{irc_session}, '__send_event';
  my $result = $response->[0];
  if ( $result->is_success ) {
      my $tinyurl = $result->content;
      push @params, 'irc_url_tiny', $args, $tinyurl;
  } else {
        push @params, 'irc_url_tiny_error', $args, $result->status_line;
  }
      $kernel->post( @params );
}

1;
__END__
