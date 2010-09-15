use inc::Module::Install;
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
use_test_base;
auto_include;
WriteAll;
