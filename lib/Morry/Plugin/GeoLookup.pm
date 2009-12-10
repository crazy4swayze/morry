package Morry::Plugin::GeoLookup;

use Moses::Plugin;
use Geo::IP;
use Regexp::Common qw(net);

use namespace::autoclean;

has geoip => (
    isa => 'Geo::IP',
    is  => 'ro',
    lazy_build => 1,
);

sub _build_geoip {
    Geo::IP->open(
        '/home/associat/g/goldfish/local/share/GeoIP/GeoLiteCity.dat', 
        GEOIP_STANDARD
    )
}

# TODO: must be cleaner way to achieve this
sub lookup {
    my ($self, $ip) = @_;
    my $default = 'Not found.';
    my $record = $self->geoip->record_by_addr($ip);
    if (defined $record) {
        my $msg = do {
            my @location;
            for (qw(city region_name country_name)) {
                if (defined $record->$_ and $record->$_) {
                    push @location, $record->$_
                } else { push @location, 'Unknown' }
            }
            $ip . ' => ' . join ' - ', @location
        };
        $default = $msg if defined $msg;
     }
    return $default
}

sub S_bot_addressed {
    my ($self, $irc, $nickstring, $channels, $message) = @_;
    return PCI_EAT_NONE unless $$message =~ /^$RE{net}{IPv4}$/;

    my $channel = $$channels->[0] || '';
    my $result = $self->lookup($$message);
    $self->privmsg($channel => $result);
    return PCI_EAT_PLUGIN;
}

1;
__END__
