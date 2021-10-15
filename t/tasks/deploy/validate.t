#!/usr/bin/perl

use strict;
use warnings;

use JSON::PP;
use Test::More;

use UNIVERSAL::require;

plan(skip_all => "Required File::Copy::Recursive module not installed")
    unless File::Copy::Recursive->require();

GLPI::Agent::Task::Deploy->require();

my @tests = (
        {
            json => '{"jobs":[[],{"checks":[{"path":"\/etc\/fstab","type":"filePresent","return":"error"}],"associatedFiles":{"6b620ce663ba13061b480e9897bfa0ef98d039a7747c8286b37a967fb505b12e6e83f10bd0ac1b89a78d4c713a3251fb77ccf0a5cfc890cba43a3627e26ff9b3":{"uncompress":1,"name":"fusioninventory-for-glpi.tar.gz","is_p2p":0,"multiparts":[{"fusioninventory-for-glpi.tar.gz":"04c1ba7f890df17966725eb600fca1a28fb7bdc7573a30869ac2cc78796f6b72ee522276509e7e9350ef2fc9685df0cfc90b5e3546bb0437e661ccec7da97a49"}],"p2p-retention-duration":0}},"actions":{"move":[{"*":"\/tmp\/input"}]}}]}',
            ret => undef,
            msg => "missing associatedFiles key",
        },
        {
            json => '[]',
            ret => undef,
            msg => "Bad answer from server. Not a hash reference.",
        },
        {
            json => '',
            ret => undef,
            msg => "No answer from server.",
        },
        {
            json => '{"jobs":[{"uuid":"4e4e3bfd87e3b"},{"check":[{"path":"\/etc\/fstab","type":"filePresent","return":"error"}],"associatedFiles":["6b620ce663ba13061b480e9897bfa0ef98d039a7747c8286b37a967fb505b12e6e83f10bd0ac1b89a78d4c713a3251fb77ccf0a5cfc890cba43a3627e26ff9b3"],"actions":{"move":[{"*":"\/tmp\/input"}]},"uuid":"4e4e3bfd90cc5"}],"associatedFiles":{"6b620ce663ba13061b480e9897bfa0ef98d039a7747c8286b37a967fb505b12e6e83f10bd0ac1b89a78d4c713a3251fb77ccf0a5cfc890cba43a3627e26ff9b3":{"uncompress":1,"name":"fusioninventory-for-glpi.tar.gz","is_p2p":0,"multiparts":[{"fusioninventory-for-glpi.tar.gz":"04c1ba7f890df17966725eb600fca1a28fb7bdc7573a30869ac2cc78796f6b72ee522276509e7e9350ef2fc9685df0cfc90b5e3546bb0437e661ccec7da97a49"},{"fusioninventory-for-glpi.tar.gz":"04c1ba7f890df17966725eb600fca1a28fb7bdc7573a30869ac2cc78796f6b72ee522276509e7e9350ef2fc9685df0cfc90b5e3546bb0437e661ccec7da97a49"}],"p2p-retention-duration":0}}}',
            ret => undef,
            msg => "Missing key `mirrors' in associatedFiles"
       },
        {
            json => '{"jobs":[{"checks":[{"path":"\/etc\/fstab","type":"filePresent","return":"error"}],"associatedFiles":[],"actions":{"move":[{"*":"\/tmp\/input"}]},"uuid":"4e4e3bfd90cc5"}],"associatedFiles":{}}',
            ret => undef,
            msg => "jobs/actions must be an array"
       },
        {
            json => '{"jobs":[{"checks":[{"path":"\/etc\/fstab","type":"filePresent","return":"error"}],"associatedFiles":[],"actions":{"move":[{"*":"\/tmp\/input"}]}}],"associatedFiles":{}}',
            ret => undef,
            msg => "Missing key `uuid' in jobs"
       },
       {
           json => '{"jobs":[{"checks":[],"associatedFiles":["7689ace446290f6dcd96a1fd24e8bd51544b91bb3b0b596ba1bfc38d1b6bc61ca0f128c9451e2c5e862a95c4780513e04eaa62c1ee9b44eef14215c63b20c51c","cf2f14ad19fc23a9528a872b9c8b333f9fb11626276f914022a1e8ebeb91a5ce7516665fd8b83a40250dbff24e500cee2645126ff31f39709551d0b9a0365430","b922fec3d8097a395022c4a44a5901ad622f7032dcac228a8c29e4d6c224c002779b091749e918056f2aa7d3506641a654c10d40bff3278b4436c2c637b57d32","7e352af5d746ffee202f50db53a8d0d02c31afea56117c77c9dffd11a6f891528a3eccfcb11382718f4ad8c811dd564ef79d81848d2bf61b4bb17967a39c77f2"],"actions":{"move":[{"*":"\/home\/goneri\/tmp"}]},"uuid":"4e537f244438a"}],"associatedFiles":{"7689ace446290f6dcd96a1fd24e8bd51544b91bb3b0b596ba1bfc38d1b6bc61ca0f128c9451e2c5e862a95c4780513e04eaa62c1ee9b44eef14215c63b20c51c":{"uncompress":1,"name":"fusioninventory-for-glpi_2.3.6.orig.tar.gz","is_p2p":0,"mirrors":["http:\/\/glpideploy\/plugins\/fusinvdeploy\/b\/deploy\/?action=getFilePart&sha512="],"multiparts":["c82ff17b167af3cbd5e243adf6fbad74889d13c89fbb829ebd8802f555b460ef5c03cc26301f536cc2b4da91d24efe1f3c6a3e390a04696edb794c655bf06642"],"p2p-retention-duration":0},"cf2f14ad19fc23a9528a872b9c8b333f9fb11626276f914022a1e8ebeb91a5ce7516665fd8b83a40250dbff24e500cee2645126ff31f39709551d0b9a0365430":{"uncompress":0,"name":"video-2011-01-30-17-30-04.mp4","is_p2p":0,"mirrors":["http:\/\/glpideploy\/plugins\/fusinvdeploy\/b\/deploy\/?action=getFilePart&sha512="],"multiparts":["66cfb03917e55b04a01f8f0088a76aee95fc981b26689a1da3b6c824fbef39e0b630c08b8b09ac81013a1a2d23d48a5338325923f88bb4690a90fbabc47076a2","ac678cda70de79f681a673cd98216a8295a855c920b463d16924c6b624c15abb8c66c52524f3204bb809ceebe6301d5c6fc80c6b9570d20783303665bbfd8b7b","621963731b3bb8489e1cf1cd80cb4af0a931a5627cc0141d89555ff99dfa0c0e4160ba354d763df4b286c21ddc188338a3801946065e078cd7e8acc5d8a3a56a","e43b94ca8d17d9b06efc0939d9d55fb93ce75b80466f3c268d995e603994ce1990d47e0660f1999225997f9bafd058efa3625b0218a6ba1ac81882282c7fa7a2","4edc17abae34c35cf090cb60e308dc2c35a1d36342e482d55c0706bdbb4ca12f71ff46fac6acec1b38f9e84e3e551852955872d63317c9fde29710964d1cb140"],"p2p-retention-duration":0},"b922fec3d8097a395022c4a44a5901ad622f7032dcac228a8c29e4d6c224c002779b091749e918056f2aa7d3506641a654c10d40bff3278b4436c2c637b57d32":{"uncompress":0,"name":"Perl_Best.rar","is_p2p":0,"mirrors":["http:\/\/glpideploy\/plugins\/fusinvdeploy\/b\/deploy\/?action=getFilePart&sha512="],"multiparts":["c2ee9a9f3d2e7685a2f41fc814e9dcf6d432f3f88ad5f62906ff67f7da6e6a7ea3d9bd04935c75b56ce470f1f208e6d6ffbb2c64cb5e2b01354a5c5277a38af5","378936c520bf533c5f72de440c320753dad462cc9513fbf09b4ac4e43fc23661525b4ec0c88f976bc10535dc5e40b8aebf3301c6eca4930ad34c2c2c26916fe9","18fb3970c59a7d44f93a290cec6a400bbb8f706f10aacec053bbcfccdcef8c15ac5015d39812acb2502198b5ee33d7aeb12cdba164286cee5e8a8869c7980dc1"],"p2p-retention-duration":0},"7e352af5d746ffee202f50db53a8d0d02c31afea56117c77c9dffd11a6f891528a3eccfcb11382718f4ad8c811dd564ef79d81848d2bf61b4bb17967a39c77f2":{"uncompress":0,"name":"phpunit_3.4.14-1_all.deb","is_p2p":0,"mirrors":["http:\/\/glpideploy\/plugins\/fusinvdeploy\/b\/deploy\/?action=getFilePart&sha512="],"multiparts":["7099fa5c0ba7cc829310e0abdf24ebaf5f696e7b88e37da9e1394b94f013b52b31b7c1a57866ae632413daa28b1f26b495f2b9ee93d547fa9daa19524c9ba351"],"p2p-retention-duration":0}}}',
            ret => undef,
            msg => "Missing key `p2p' in associatedFiles"
       },
);

plan tests => scalar @tests * 2;

foreach my $test (@tests) {
    my $msg;
    my $struct = eval {decode_json($test->{json})};
    my $ret = GLPI::Agent::Task::Deploy::_validateAnswer(
        \$msg,
        $struct
    );
    ok(($ret ? 0 : 1) == ($test->{ret} ? 0 : 1), "returned code");
    is($msg,  $test->{msg}, "returned msg");
}
