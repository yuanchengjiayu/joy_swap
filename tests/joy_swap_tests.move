
#[test_only]
module joy_swap::joy_swap_tests;
// uncomment this line to import the module
    use joy_swap::joy_swap::{ Self, LP };
    use sui::coin::{ Self, Coin };
    use sui::test_scenario;
    use sui::coin::mint_for_testing;

    public struct Coin_A has drop {}
    public struct Coin_B has drop {}

    #[test]
    fun test_create_pool() {
        let addr1 = @0x1;
        let mut scenario_val = test_scenario::begin(addr1);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, addr1);
        {
            let coin_a1 = mint_for_testing<Coin_A>(1_000_000, test_scenario::ctx(scenario));
            let coin_b1 = mint_for_testing<Coin_B>(1_000_000, test_scenario::ctx(scenario));
            joy_swap::create_pool(coin_a1, coin_b1, test_scenario::ctx(scenario));
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_add_liquidity() {
        let addr1 = @0x1;
        let mut scenario_val = test_scenario::begin(addr1);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, addr1);
        {
            let coin_a1 = mint_for_testing<Coin_A>(1_000_000, test_scenario::ctx(scenario));
            let coin_b1 = mint_for_testing<Coin_B>(1_000_000, test_scenario::ctx(scenario));

            joy_swap::create_pool(coin_a1, coin_b1, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, addr1);
        {
            let mut pool = test_scenario::take_shared<joy_swap::Pool<Coin_A, Coin_B>>(scenario);
            let pool_ref = &mut pool;

            let coin_a2 = coin::mint_for_testing<Coin_A>(1_000_000, test_scenario::ctx(scenario));
            let coin_b2 = coin::mint_for_testing<Coin_B>(1_000_000, test_scenario::ctx(scenario));

            joy_swap::add_liquidity(pool_ref, coin_a2, coin_b2, test_scenario::ctx(scenario));

            test_scenario::return_shared(pool);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_remove_liquidity() {
        let addr1 = @0x1;
        let mut scenario_val = test_scenario::begin(addr1);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, addr1);
        {
            let coin_a1 = mint_for_testing<Coin_A>(1_000_000, test_scenario::ctx(scenario));
            let coin_b1 = mint_for_testing<Coin_B>(1_000_000, test_scenario::ctx(scenario));

            joy_swap::create_pool(coin_a1, coin_b1, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, addr1);
        {
            let mut pool = test_scenario::take_shared<joy_swap::Pool<Coin_A, Coin_B>>(scenario);
            let pool_ref = &mut pool;
            let lp_coin = test_scenario::take_from_sender<Coin<LP<Coin_A, Coin_B>>>(scenario);
           
            joy_swap::remove_liquidity(pool_ref, lp_coin, test_scenario::ctx(scenario));

            test_scenario::return_shared(pool);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_swap_a_to_b() {
        let addr1 = @0x1;
        let mut scenario_val = test_scenario::begin(addr1);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, addr1);
        {
            let coin_a1 = mint_for_testing<Coin_A>(1_000_000, test_scenario::ctx(scenario));
            let coin_b1 = mint_for_testing<Coin_B>(1_000_000, test_scenario::ctx(scenario));

            joy_swap::create_pool(coin_a1, coin_b1, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, addr1);
        {
            let mut pool = test_scenario::take_shared<joy_swap::Pool<Coin_A, Coin_B>>(scenario);
            let pool_ref = &mut pool;
            let coin_a2 = coin::mint_for_testing<Coin_A>(1_000_000, test_scenario::ctx(scenario));

            joy_swap::swap_a_to_b(pool_ref, coin_a2, test_scenario::ctx(scenario));

            test_scenario::return_shared(pool);
        };

        test_scenario::end(scenario_val);
    }