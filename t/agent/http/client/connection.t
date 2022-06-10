#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use HTTP::Request;
use Test::More;
use Test::Exception;

use GLPI::Agent::Logger;
use GLPI::Agent::HTTP::Client;
use GLPI::Test::Proxy;
use GLPI::Test::Server;
use GLPI::Test::Utils;

unsetProxyEnvVar();

# find an available port
my $port = GLPI::Agent::Tools::first { test_port($_) } 8080 .. 8180;

if (!$port) {
    plan skip_all => 'no port available';
} else {
    plan tests => 36;
}

my $ok = sub {
    print "HTTP/1.0 200 OK\r\n";
    print "\r\n";
    print "OK";
};

my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Test' ]
);

unless (-e "resources/ssl/crt/ca.pem") {
    print STDERR "Generating SSL certificates...\n";
    qx(cd resources/ssl ; ./generate.sh );
}

my $client = GLPI::Agent::HTTP::Client->new(
    logger => $logger
);


subtest "no response" => sub {
    check_response_nok(
        $client,
        "http://127.0.0.1:$port/public",
        $logger,
        qr/Can't connect to 127.0.0.1:$port/
    );
};

# http connection tests
my ($server, $response);

# ensure the server get stopped even if an exception is thrown
$SIG{__DIE__}  = sub { $server->stop(); };

$server = GLPI::Test::Server->new(
    port     => $port,
    user     => 'test',
    realm    => 'test',
    password => 'test',
);
$server->set_dispatch({
    '/public'  => $ok,
    '/private' => sub { return $ok->(@_) if $server->authenticate(); }
});
eval {
    $server->background();
};
BAIL_OUT("can't launch the server: $EVAL_ERROR") if $EVAL_ERROR;

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "http://127.0.0.1:$port/public"
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger => $logger
    );
} 'instanciation: http, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        $client,
        "http://127.0.0.1:$port/private",
        $logger,
        "[http client] authentication required, no credentials available",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        config   => {
            user     => 'test',
            password => 'test',
        },
        logger   => $logger,
    );
} 'instanciation:  http, auth, with credentials';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "http://127.0.0.1:$port/private"
    );
};

$server->stop();

SKIP: {
skip 'non working test under MacOS', 12 if $OSNAME eq 'darwin';
skip 'non working test under Windows', 12 if $OSNAME eq 'MSWin32';
# https connection tests

$server = GLPI::Test::Server->new(
    port     => $port,
    user     => 'test',
    realm    => 'test',
    password => 'test',
    ssl      => 1,
    crt      => 'resources/ssl/crt/good.pem',
    key      => 'resources/ssl/key/good.pem',
);
$server->set_dispatch({
    '/public'  => $ok,
    '/private' => sub { return $ok->(@_) if $server->authenticate(); }
});
eval {
    $server->background();
};
BAIL_OUT("can't launch the server: $EVAL_ERROR") if $EVAL_ERROR;

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            'no-ssl-check'  => 1,
        },
    );
} 'instanciation: https, check disabled';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "https://127.0.0.1:$port/public"
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            'no-ssl-check'  => 1,
        },
    );
} 'instanciation: https, check disabled, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        $client,
        "https://127.0.0.1:$port/private",
        $logger,
        "[http client] authentication required, no credentials available",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            user            => 'test',
            password        => 'test',
            'no-ssl-check'  => 1,
        },
    );
} 'instanciation: https, check disabled, auth, credentials';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "https://127.0.0.1:$port/private",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            'ca-cert-file'  => 'resources/ssl/crt/ca.pem',
        },
    );
} 'instanciation: https';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "https://127.0.0.1:$port/public",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger       => $logger,
        config  => {
            'ca-cert-file'  => 'resources/ssl/crt/ca.pem',
        },
    );
} 'instanciation: https, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        $client,
        "https://127.0.0.1:$port/private",
        $logger,
        "[http client] authentication required, no credentials available",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            user            => 'test',
            password        => 'test',
            'ca-cert-file'  => 'resources/ssl/crt/ca.pem',
        },
    );
} 'instanciation: https, auth, credentials';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "https://127.0.0.1:$port/private",
    );
};

$server->stop();
}

SKIP: {
skip 'non working test under Windows', 18 if $OSNAME eq 'MSWin32';
# http connection through proxy tests

$server = GLPI::Test::Server->new(
    port     => $port,
    user     => 'test',
    realm    => 'test',
    password => 'test',
);
$server->set_dispatch({
    '/public'  => sub { return $ok->(@_) if $ENV{HTTP_X_FORWARDED_FOR}; },
    '/private' => sub { return $ok->(@_) if $ENV{HTTP_X_FORWARDED_FOR} && $server->authenticate(); }
});
eval {
    $server->background();
};
BAIL_OUT("can't launch the server: $EVAL_ERROR") if $EVAL_ERROR;

my $proxy = GLPI::Test::Proxy->new();
$proxy->background();

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            proxy   => $proxy->url(),
        },
    );
} 'instanciation: http, proxy';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "http://127.0.0.1:$port/public",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            proxy   => $proxy->url(),
        },
    );
} 'instanciation: http, proxy, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        $client,
        "http://127.0.0.1:$port/private",
        $logger,
        "[http client] authentication required, no credentials available",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            user        => 'test',
            password    => 'test',
            proxy       => $proxy->url(),
        },
    );
} 'instanciation: http, proxy, auth, credentials';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "http://127.0.0.1:$port/private",
    );
};

$server->stop();

SKIP: {
skip 'non working test under MacOS', 12 if $OSNAME eq 'darwin';
# https connection through proxy tests

$server = GLPI::Test::Server->new(
    port     => $port,
    user     => 'test',
    realm    => 'test',
    password => 'test',
    ssl      => 1,
    crt      => 'resources/ssl/crt/good.pem',
    key      => 'resources/ssl/key/good.pem',
);
$server->set_dispatch({
    '/public'  => sub {
        if ($ENV{HTTP_X_FORWARDED_FOR}) {
            diag("We are are supposed to do HTTPS over a proxy and ".
               "HTTP_X_FORWARDED_FOR environment variables is defined. ".
               "This should not happen since the proxy cannot access the ".
               "encrypted data. ".
               "This means the local LWP library doesn't provide real ".
               "SSL proxy support and try to contact the server using ".
               "plaintext HTTP. HTTPS over proxy will not work properly. ".
               "Please see: https://github.com/libwww-perl/libwww-perl/pull/52")
        }
        return $ok->(@_);
    },
    '/private' => sub {
        return $ok->(@_) if $server->authenticate();
    }
});
eval {
    $server->background();
};
BAIL_OUT("can't launch the server: $EVAL_ERROR") if $EVAL_ERROR;

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            'no-ssl-check'  => 1,
            proxy           => $proxy->url(),
            #~ timeout         => 5,
        },
    );
} 'instanciation: https, proxy, check disabled';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "https://127.0.0.1:$port/public",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            'no-ssl-check'  => 1,
            proxy           => $proxy->url(),
        },
    );
} 'instanciation: https, check disabled, proxy, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        $client,
        "https://127.0.0.1:$port/private",
        $logger,
        "[http client] authentication required, no credentials available",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            user            => 'test',
            password        => 'test',
            'no-ssl-check'  => 1,
            proxy           => $proxy->url(),
        },
    );
} 'instanciation: https, check disabled, proxy, auth, credentials';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "https://127.0.0.1:$port/private",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            'ca-cert-file'  => 'resources/ssl/crt/ca.pem',
            proxy           => $proxy->url(),
        },
    );
} 'instanciation: https, proxy';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "https://127.0.0.1:$port/public",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            'ca-cert-file'  => 'resources/ssl/crt/ca.pem',
            proxy           => $proxy->url(),
        },
    );
} 'instanciation: https, proxy, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        $client,
        "https://127.0.0.1:$port/private",
        $logger,
        "[http client] authentication required, no credentials available",
    );
};

lives_ok {
    $client = GLPI::Agent::HTTP::Client->new(
        logger  => $logger,
        config  => {
            user            => 'test',
            password        => 'test',
            'ca-cert-file'  => 'resources/ssl/crt/ca.pem',
            proxy           => $proxy->url(),
        },
    );
} 'instanciation: https, proxy, auth, credentials';

subtest "correct response" => sub {
    check_response_ok(
        $client,
        "https://127.0.0.1:$port/private",
    );
};

$server->stop();
}

$proxy->stop();
}

sub check_response_ok {
    my ($client, $url) = @_;

    plan tests => 1;
    my $response = $client->request(HTTP::Request->new(GET => $url));

    ok($response->is_success(), "response is a success");
}

sub check_response_nok {
    my ($client, $url, $logger, $message) = @_;

    plan tests => 3;
    my $response = $client->request(HTTP::Request->new(GET => $url));

    ok(!$response->is_success(), "response is an error");
    is(
        $logger->{backends}->[0]->{level},
        'error',
        "error message level"
    );
    if (ref $message eq 'Regexp') {
        like(
            $logger->{backends}->[0]->{message},
            $message,
            "error message content"
        );
    } else {
        is(
            $logger->{backends}->[0]->{message},
            $message,
            "error message content"
        );
    }
}
