use inc::Module::Install;
name 'Plack-Middleware-StaticShared';
all_from 'lib/Plack/Middleware/StaticShared.pm';

requires 'parent';
requires 'Plack';

build_requires 'Test::Most';
build_requires 'Cache::MemoryCache';
use_test_base;
auto_include;
WriteAll;
