use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		    => 'Class::Trait',
    'VERSION_FROM'	=> 'lib/Class/Trait.pm',
    'PREREQ_PM'		=> {
        'Test::More'  => 0.47,
        'File::Spec'  => 0,
    }
);
