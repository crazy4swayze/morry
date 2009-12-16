package Morry::Plugin::TinyURL;

use Moses::Plugin;

use namespace::autoclean;

sub S_url_tiny {
    my ( $self, $irc, $args, $url ) = @_;
# original url $$args->{url}
    warn 'tiny';
    $self->privmsg($$args->{_channel} => $$url);
    return PCI_EAT_PLUGIN;
}

sub S_url_tiny_error {
    my ( $self, $irc, $args, $url ) = @_;
    warn 'tiny_error';
# original url $$args->{url}
    $self->privmsg($$args->{_channel} => $$url);
    return PCI_EAT_PLUGIN;
}


1;
__END__
