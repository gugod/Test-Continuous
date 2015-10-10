#!/usr/bin/env perl
use strict;
use lib 't';

use Test::More tests => 3;
use Test::Continuous;

use Cwd qw(cwd realpath chdir);
use File::Temp qw( tempdir );
use File::Spec;

my $home = cwd();
my $playground = realpath(tempdir(CLEANUP => 1));
my $r;

subtest 'git repo w/o .gitignore' => sub {
   plan tests => 3;
   # Create gitignore_less repo
   my $gitignore_less_repo = File::Spec->catdir( $playground, 'gitless' );
   mkdir $gitignore_less_repo;
   # Create repo and get Git::Repository object
   $r = eval {
      $r = Git::Repository->run( 'init', { cwd => $gitignore_less_repo  }  );
      Git::Repository->new( { cwd => $gitignore_less_repo  }  );
   };
   isa_ok $r, 'Git::Repository';

   # Go there
   chdir($gitignore_less_repo);
   is cwd(), $gitignore_less_repo, 'We made it!';
   is_deeply Test::Continuous::_get_exclude_list(), [
        qr/\.(bzr|
            cdv|
            dep|
            dot|
            nib|
            plst|
            git|
            hg|
            pc|
            svn|
            komodoproject|
            bak)$/x,

        qr/^(_MTN|
            blib|
            CVS|
            RCS|
            SCCS|
            _darcs|
            _sgbak|
            autom4te\.cache|
            cover_db|
            _build)$/x,

        qr(~$),
        qr/\.#.*$/,
        qr/^#.*#$/,
        qr/\..*\.swp$/,
        qr/^core\.\d+$/,
        qr/[.-]min\.js$/
   ], 'default exclude list returned in git-less environment';
};
subtest 'git repo w/ .gitignore and w/o files' => sub {
   plan tests => 3;
   # Create gitignore_less repo
   my $gitignore_repo = File::Spec->catdir( $playground, 'gitignore' );
   mkdir $gitignore_repo;
   # Create repo and get Git::Repository object
   $r = eval {
      $r = Git::Repository->run( 'init', { cwd => $gitignore_repo  }  );
      Git::Repository->new( { cwd => $gitignore_repo  }  );
   };
   isa_ok $r, 'Git::Repository';
   my $gitignore_handle;
   open ($gitignore_handle, '>', $gitignore_repo.'/.gitignore') or die('Unable to open '.$gitignore_repo.'/.gitignore');
   print $gitignore_handle join "\n", '*.swp', '!/.gitignore';
   close ($gitignore_handle) or die ("Unable to close ".$gitignore_repo.'/.gitignore');

   # Go there
   chdir($gitignore_repo);
   is cwd(), $gitignore_repo, 'We made it!';
   is_deeply Test::Continuous::_get_exclude_list(), [
        qr/\.(bzr|
            cdv|
            dep|
            dot|
            nib|
            plst|
            git|
            hg|
            pc|
            svn|
            komodoproject|
            bak)$/x,

        qr/^(_MTN|
            blib|
            CVS|
            RCS|
            SCCS|
            _darcs|
            _sgbak|
            autom4te\.cache|
            cover_db|
            _build)$/x,

        qr(~$),
        qr/\.#.*$/,
        qr/^#.*#$/,
        qr/\..*\.swp$/,
        qr/^core\.\d+$/,
        qr/[.-]min\.js$/
   ], 'default exclude list returned in environment with no files';
};
subtest 'git repo w/ .gitignore and w/ files' => sub {
   plan tests => 3;
   # Create gitignore_less repo
   my $gitignore_repo = File::Spec->catdir( $playground, 'ignorewfiles' );
   mkdir $gitignore_repo;
   # Create repo and get Git::Repository object
   $r = eval {
      $r = Git::Repository->run( 'init', { cwd => $gitignore_repo  }  );
      Git::Repository->new( { cwd => $gitignore_repo  }  );
   };
   isa_ok $r, 'Git::Repository';
   my $gitignore_handle;
   open ($gitignore_handle, '>', $gitignore_repo.'/.gitignore') or die('Unable to open '.$gitignore_repo.'/.gitignore');
   print $gitignore_handle join "\n", '*.swp', 'META.*', '!/.gitignore';
   close ($gitignore_handle) or die ("Unable to close ".$gitignore_repo.'/.gitignore');

   # Touch some files to be included in the exclude list
   my @files_to_touch = (
      'test.swp',
      'test.txt',
      'META.yml',
      'META.json',
   );
   open(my $fh, '>>', $gitignore_repo.'/'.$_) foreach @files_to_touch;

   # Go there
   chdir($gitignore_repo);
   is cwd(), $gitignore_repo, 'We made it!';
   is_deeply Test::Continuous::_get_exclude_list(), [
        qr/\.(bzr|
            cdv|
            dep|
            dot|
            nib|
            plst|
            git|
            hg|
            pc|
            svn|
            komodoproject|
            bak)$/x,

        qr/^(_MTN|
            blib|
            CVS|
            RCS|
            SCCS|
            _darcs|
            _sgbak|
            autom4te\.cache|
            cover_db|
            _build)$/x,

        qr(~$),
        qr/\.#.*$/,
        qr/^#.*#$/,
        qr/\..*\.swp$/,
        qr/^core\.\d+$/,
        qr/[.-]min\.js$/,
        $gitignore_repo.'/META.json',
        $gitignore_repo.'/META.yml',
        $gitignore_repo.'/test.swp',
   ], 'default exclude list returned in environment with files';
};

chdir $home; # so we can clean up the temp files
