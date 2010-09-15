package Plack::Middleware::StaticShared;

use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Request;
use LWP::Simple qw($ua);
use Digest::SHA1 qw(sha1_hex);
use DateTime::Format::HTTP;
use DateTime;
use Path::Class;

__PACKAGE__->mk_accessors(qw(cache base binds));

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
}

sub call {
	my ($self, $env) = @_;
	for my $static (@{ $self->binds }) {
		my $prefix = $static->{prefix};
		# Some browsers (eg. Firefox) always access if the url has query string,
		# so use `:' for parameters
		my ($version, $files) = ($env->{PATH_INFO} =~ /^$prefix:([^:]+):(.+)$/) or next;
		my $req = Plack::Request->new($env);
		my $res = $req->new_response;

		my $key = join(':', $version, $files);
		my $etag = sha1_hex($key);

		if ($req->header('If-None-Match') || '' eq $etag) {
			# Browser cache is avaialable but force reloaded by user.
			$res->code(304);
		} else {
			my $content = eval {
				my $ret = $self->cache->get($key);
				if (not defined $ret) {
					$ret = $self->concat(split /,/, $files);
					$ret = $static->{filter}->(local $_ = $ret) if $static->{filter};
					$self->cache->set($key => $ret);
				}
				$ret;
			};

			if ($@) {
				$res->code(503);
				$res->header('Retry-After' => 10);
				$res->content($@);
			} else {
				# Cache control:
				# IE requires both Last-Modified and Etag to ignore checking updates.
				$res->code(200);
				$res->header("Cache-Control" => "public; max-age=315360000; s-maxage=315360000");
				$res->header("Expires" => DateTime::Format::HTTP->format_datetime(DateTime->now->add(years => 10)));
				$res->header("Last-Modified" => DateTime::Format::HTTP->format_datetime(DateTime->from_epoch(epoch => 0)));
				$res->header("ETag" => $etag);
				$res->content_type($static->{content_type});
				$res->content($content);
			}
		}

		return $res->finalize;
	}

	$self->app->($env);
}

sub concat {
	my ($self, @files) = @_;
	my $base = dir($self->base);
	join("\n",
		map {
			$base->file($_)->slurp;
		}
		@files
	);
}

1;
__END__

1;
__END__

=head1 NAME

Plack::Middleware::StaticShared - concat some static files to one resource

=head1 SYNOPSIS

  use Plack::Builder;
  use JavaScript::Squish;

  builder {
      enable "StaticShared",
          cache => Cache::Memcached::Fast->new(servers => [qw/192.168.0.11:11211/]),
          base  => './static/',
          binds => [
              {
                  prefix       => '/.shared.js',
                  content_type => 'text/javascript; charset=utf8',
                  filter       => sub {
                      JavaScript::Squish->squish->squish($_);
                  }
              },
              {
                  prefix       => '/.shared.css',
                  content_type => 'text/css; charset=utf8',
              }
          ];

      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::StaticShared provides resource end point which concat some static files to one resource for reducing http requests.

=head1 AUTHOR

cho45

=head1 SEE ALSO

L<Plack::Middleware> L<Plack::Builder>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

