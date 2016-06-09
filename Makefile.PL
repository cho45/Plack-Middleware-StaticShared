BEGIN {
	use inc::Module::Install;
	my @mip = qw(
		Module::Install::AuthorTests
		Module::Install::Repository
		Module::Install::ReadmeFromPod
		Module::Install::TestBase
	);
	for (@mip) {
		eval "require $_";
		if ($@) {
			eval "require inc::$_";
			if ($@) {
				warn $@;
				printf("# Install following (perl Makefile.PL | cpanm):\n%s", join("\n", @mip));
				exit 1;
			}
		}
	}
};

name 'Plack-Middleware-StaticShared';
all_from 'lib/Plack/Middleware/StaticShared.pm';

requires 'parent';
requires 'Plack';
requires 'Plack::Request';
requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'Digest::SHA1';
requires 'Path::Class';

build_requires 'Test::Most';
build_requires 'Cache::MemoryCache';

# Module::Install::AuthorTests
author_tests('xt');

# Module::Install::Repository
auto_set_repository;

# Module::Install::TestBase
use_test_base;

# Module::Install::ReadmeFromPod
readme_from 'lib/Plack/Middleware/StaticShared.pm';

auto_include;
WriteAll;
