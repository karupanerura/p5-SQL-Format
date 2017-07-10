use strict;
use warnings;
use lib 't/lib';
use Util;
use Test::More;

my $test = mk_test 'select';

$test->(
    desc    => 'no conditions',
    input   => [foo => 'bar'],
    expects => {
        stmt => 'SELECT `bar` FROM `foo`',
        bind => [],
    },
);

$test->(
    desc    => 'no conditions (astarisk)',
    input   => [foo => '*'],
    expects => {
        stmt => 'SELECT * FROM `foo`',
        bind => [],
    },
);

$test->(
    desc    => 'no conditions (multi columns)',
    input   => [foo => [qw/bar baz/]],
    expects => {
        stmt => 'SELECT `bar`, `baz` FROM `foo`',
        bind => [],
    },
);

$test->(
    desc    => 'add where',
    input   => [foo => [qw/bar baz/], { hoge => 'fuga' }],
    expects => {
        stmt => 'SELECT `bar`, `baz` FROM `foo` WHERE (`hoge` = ?)',
        bind => [qw/fuga/],
    },
);

$test->(
    desc    => 'add where multi',
    input   => [foo => [qw/bar baz/], ordered_hashref(hoge => 'fuga', piyo => 'moge')],
    expects => {
        stmt => 'SELECT `bar`, `baz` FROM `foo` WHERE (`hoge` = ?) AND (`piyo` = ?)',
        bind => [qw/fuga moge/],
    },
);

$test->(
    desc    => 'add where, add order by',
    input   => [
        foo => [qw/bar baz/],
        { hoge => 'fuga' },
        { order_by => 'piyo' },
    ],
    expects => {
        stmt => 'SELECT `bar`, `baz` FROM `foo` WHERE (`hoge` = ?) ORDER BY `piyo`',
        bind => [qw/fuga/],
    },
);

$test->(
    desc => 'limmit offset',
    input => [
        foo => '*',
        undef,
        { limit => 1, offset => 2 },
    ],
    expects => {
        stmt => 'SELECT * FROM `foo` LIMIT 1 OFFSET 2',
        bind => [],
    },
);

$test->(
    desc  => 'custom prefix',
    input => [
        foo => '*',
        undef,
        { prefix => 'SELECT SQL_CALC_FOUND_ROWS' },
    ],
    expects => {
        stmt => 'SELECT SQL_CALC_FOUND_ROWS * FROM `foo`',
        bind => [],
    },
);

$test->(
    desc  => 'suffix',
    input => [
        foo => '*',
        { hoge => 'fuga' },
        { suffix => 'FOR UPDATE' },
    ],
    expects => {
        stmt => 'SELECT * FROM `foo` WHERE (`hoge` = ?) FOR UPDATE',
        bind => [qw/fuga/],
    },
);

$test->(
    desc  => 'for_update',
    input => [
        foo => '*',
        { hoge => 'fuga' },
        { for_update => 1 },
    ],
    expects => {
        stmt => 'SELECT * FROM `foo` WHERE (`hoge` = ?) FOR UPDATE',
        bind => [qw/fuga/],
    },
);

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings => @_ };
    $test->(
        desc  => 'conflict for_update and suffix',
        input => [
            foo => '*',
            { hoge => 'fuga' },
            { for_update => 1, suffix => 'LOCK IN SHARE MODE' },
        ],
        expects => {
            stmt => 'SELECT * FROM `foo` WHERE (`hoge` = ?) LOCK IN SHARE MODE',
            bind => [qw/fuga/],
        },
        subtest => sub {
            is @warnings, 1;
            like $warnings[0], qr/Conflict option \`for_update\` and \`suffix\`\. \`for_update\` option is ignored/;
        },
    );
};

$test->(
    desc => 'join',
    input => [
        { foo => 'f' },
        [qw/f.id b.name/],
        { 'f.created_at' => { '>' => \['UNIX_TIMESTAMP() - ?', 60 * 10] } },
        {
            order_by => 'f.id',
            limit    => 10,
            offset   => 20,
            join     => {
                type      => 'left',
                table     => { bar => 'b' },
                condition => [qw/id/],
            },
        },
    ],
    expects => {
        stmt => 'SELECT `f`.`id`, `b`.`name` FROM `foo` `f` LEFT JOIN `bar` `b` USING (`id`) WHERE (`f`.`created_at` > UNIX_TIMESTAMP() - ?) ORDER BY `f`.`id` LIMIT 10 OFFSET 20',
        bind => [qw/600/],
    },
);

$test->(
    desc  => 'where in empty hash',
    input => [
        foo => undef, {},
    ],
    expects => {
        stmt => 'SELECT * FROM `foo`',
        bind => [],
    },
);

$test->(
    desc  => 'where in empty array',
    input => [
        foo => undef, {},
    ],
    expects => {
        stmt => 'SELECT * FROM `foo`',
        bind => [],
    },
);

done_testing;
