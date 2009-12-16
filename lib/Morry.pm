package Morry;
use Moses;
use POE::Component::IRC::Plugin::TinyURL;

use Module::Pluggable (
    search_path => ['Morry::Plugin'],
    except => ['Morry::Plugin::AdminList'],
    sub_name    => 'plugin_classes',
);

owner    'go|dfish!goldfish@Redbrick.dcu.ie';
nickname 'morry';
server   'irc.redbrick.dcu.ie';
channels '#moses';

#has admins => (
#    isa     => 'HashRef',
#    is      => 'ro',
#    traits  => [qw(Hash)],
#    default => sub { {} },
#    handles => {
#        get_admin     => 'get',
#        set_admin     => 'set',
#        is_admin      => 'exists',
#        has_no_admins => 'is_empty',
#        del_admin     => 'delete',
#        _dump_admins  => 'keys',
#    }
#);

sub dump_admins {
    my ($self) = @_;
    $self->has_no_admins ? 'no admins.' : join ' ', $self->_dump_admins
}

sub custom_plugins {
    return { 
        'tinyurl' => POE::Component::IRC::Plugin::TinyURL->new(), 
        map { $_ => $_ } $_[0]->plugin_classes 
    }
}

no Moses;
1;
__END__
