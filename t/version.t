#!/usr/bin/env perl

use Test2::V0;
use Test::Alien;
use Alien::LinkGrammar;

subtest 'Link Grammar version' => sub {
	alien_ok 'Alien::LinkGrammar';

	if( $^O eq 'darwin' && Alien::LinkGrammar->install_type eq 'share' ) {
		my @install_name_tool_commands = ();
		my @libs = qw(
			lib/liblink-grammar.5.dylib
		);

		for my $lib (@libs) {
			my $prop = Alien::LinkGrammar->runtime_prop;
			my $rpath_install = $prop->{prefix}; # '%{.runtime.prefix}'
			my $rpath_blib = $prop->{distdir}; # '%{.install.stage}';
			my $blib_lib = "$rpath_blib/$lib";

			push @install_name_tool_commands,
				"install_name_tool -add_rpath $rpath_install -add_rpath $rpath_blib $blib_lib";
			push @install_name_tool_commands,
				"install_name_tool -id \@rpath/$lib $blib_lib";
			for my $other_lib (@libs) {
				push @install_name_tool_commands,
					"install_name_tool -change $rpath_install/$other_lib \@rpath/$other_lib $blib_lib"
			}
		}
		for my $command (@install_name_tool_commands) {
			system($command);
		}
	}

	my $xs = do { local $/; <DATA> };
	xs_ok {
		xs => $xs,
		verbose => 5,
		cbuilder_link => {
			extra_linker_flags =>
				# add -dylib_file since during test, the dylib is under blib/
				$^O eq 'darwin'
					? ' -rpath ' . Alien::LinkGrammar->runtime_prop->{distdir}
					: ' '
		},
	}, with_subtest {
		my($module) = @_;
		is $module->version, "link-grammar-@{[ Alien::LinkGrammar->version ]}",
			"Got Link Grammar version @{[ Alien::LinkGrammar->version ]}";
	};

};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "link-grammar/link-includes.h"

const char *
version(const char *class)
{
	return linkgrammar_get_version();
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *version(class);
	const char *class;
