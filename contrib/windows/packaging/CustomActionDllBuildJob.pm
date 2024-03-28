package
    CustomActionDllBuildJob;

use parent 'Exporter';

use ToolchainBuildJob;

sub build_steps {
    my ($arch) = @_;

    return {
        app_simplename  => "ca.dll",
        app_version     => sprintf("%d.%d.%d.%d", (localtime)[5 ,7 ,2 ,1]),
        bits            => $arch eq 'x64' ? 64 : 32,
        build_job_steps => [
            ### FIRST STEP 0 : Binaries donwloads ##############################
            {
                plugin  => 'Perl::Dist::Strawberry::Step::ToolChain',
                packages => [
                    {
                        name        => 'winlibs-x86_64',
                        file        => ToolchainBuildJob::TOOLCHAIN_ARCHIVE(),
                        not_if_file => 'mingw64/bin/gcc.exe',
                    },
                ],
            },
            ### NEXT STEP 1 Binaries cleanup ###################################
            {
                plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
                commands => [
                    { do => 'removefile_recursive', args => [ '<image_dir>/mingw64', qr/.+\.la$/i ] }, # https://rt.cpan.org/Public/Bug/Display.html?id=127184
                    { do => 'copyfile', args => [ '<image_dir>/mingw64/bin/mingw32-make.exe', '<image_dir>/mingw64/bin/gmake.exe', 1 ] },
                ],
            },
            ### NEXT STEP 2 : Build ca.dll ###############################
            {
                plugin  => 'Perl::Dist::Strawberry::Step::BuildLibrary',
                name    => 'ca',
                version => '__GLPI_AGENT_VERSION__',
                folder  => 'contrib/windows/packaging/tools/ca',
                skip_if_file    => 'tools/ca/ca.dll',
                manifest        => 'dll/ca.dll.manifest',
                skip_configure  => 1,
                build_in_srcdir => 1,
                make_use_cpus   => 1,
                skip_install    => 1,
                skip_test       => 1,
            },
        ]
    };
}

1;
