#!perl

use strict;
use warnings;

use Test::Most;
use Plack::Middleware::StaticShared;
use Cache::MemoryCache;
use Plack::Response;

my $filtered;
my $m = Plack::Middleware::StaticShared->new({
	cache => Cache::MemoryCache->new,
	base  => 't/static/',
	binds => [
		{
			prefix       => '/.shared.js',
			content_type => 'text/javascript; charset=utf8',
			filter       => sub {
				$filtered++;
				s/replace/foobar/;
				$_;
			}
		},
		{
			prefix       => '/.shared.css',
			content_type => 'text/css; charset=utf8',
		}
	]
});

$m->wrap(sub {
	[200, [ 'Content-Type' => 'text/plain' ], 'app' ]
});

subtest "js" => sub {
	my $r = Plack::Response->new(@{ $m->call({ PATH_INFO => '/.shared.js:v1:/js/a.js,/js/b.js,/js/c.js' }) });
	is $filtered, 1;
	is $r->code, 200;
	is $r->header('Content-Type'), 'text/javascript; charset=utf8';
	ok $r->header('ETag');
	is $r->content->[0], "aaajs\n\nbbbjs\n\ncccjs\n";

	$r = Plack::Response->new(@{ $m->call({ PATH_INFO => '/.shared.js:v1:/js/a.js,/js/b.js,/js/c.js' }) });
	is $filtered, 1, 'cache';
	done_testing;
};

subtest "css" => sub {
	my $r = Plack::Response->new(@{ $m->call({ PATH_INFO => '/.shared.css:v1:/css/a.css,/css/b.css,/css/c.css' }) });
	is $r->code, 200;
	is $r->header('Content-Type'), 'text/css; charset=utf8';
	ok $r->header('ETag');
	is $r->content->[0], "aaacss\n\nbbbcss\n\nccccss\n";

	$r = Plack::Response->new(@{ $m->call({ PATH_INFO => '/.shared.css:v1:/css/a.css,/css/b.css,/css/c.css' }) });
	done_testing;
};

subtest "filter" => sub {
	my $r = Plack::Response->new(@{ $m->call({ PATH_INFO => '/.shared.js:v1:/js/a.js,/js/b.js,/js/c.js,/js/replace.js' }) });
	is $r->code, 200;
	is $r->header('Content-Type'), 'text/javascript; charset=utf8';
	ok $r->header('ETag');
	is $r->content->[0], "aaajs\n\nbbbjs\n\ncccjs\n\nXXX foobar XXX\n";
	done_testing;
};

subtest "fallback" => sub {
	my $r = Plack::Response->new(@{ $m->call({ PATH_INFO => '/' }) });
	is $r->code, 200;
	is $r->content, 'app';
	done_testing;
};

done_testing;

