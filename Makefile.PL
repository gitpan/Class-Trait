use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    => 'Class::Trait',
    'VERSION_FROM'	=> 'lib/Class/Trait.pm',
    'PREREQ_PM'		=> {
        'Test::More'      => .47
    }
);
