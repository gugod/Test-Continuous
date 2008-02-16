#!perl

eval { require Test::Perl::Critic };
if ($@) {
    require Test::More;
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

Test::Perl::Critic::all_critic_ok();
