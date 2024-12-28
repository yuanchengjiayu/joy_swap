    module joy_swap::joy_swap;
        use sui::tx_context::sender;
        use sui::balance::{Self, Balance, Supply};
        use sui::coin::{Self, Coin};
        use std::type_name::{Self, TypeName};
        use sui::event;

        const EInValueZore: u64 = 0;
        const EPoolValueZore: u64 = 1;

        public struct PoolCreated has copy, drop {
            pool_id: ID,
            coin_a: TypeName,
            coin_b: TypeName,
            coin_a_value: u64,
            coin_b_value: u64,
            lp_minted: u64,
        }

        public struct LiquidityAdded has copy, drop {
            pool_id: ID,
            coin_a: TypeName,
            coin_b: TypeName,
            coin_a_value: u64,
            coin_b_value: u64,
            lp_minted: u64,
        }

        public struct LiquidityRemoved has copy, drop {
            pool_id: ID,
            coin_a: TypeName,
            coin_b: TypeName,
            coin_a_value: u64,
            coin_b_value: u64,
            lp_burned: u64,
        }
        
        public struct Swaped has copy, drop {
            pool_id: ID,
            coin_in: TypeName,
            value_in: u64,
            coin_out: TypeName,
            value_out: u64,
        }

        public struct LP<phantom Coin_A, phantom Coin_B> has drop {}

        public struct Pool<phantom Coin_A, phantom Coin_B> has key {
            id: UID,
            balance_a: Balance<Coin_A>,
            balance_b: Balance<Coin_B>,
            lp_supply: Supply<LP<Coin_A, Coin_B>>,
        }

        public entry fun create_pool<Coin_A, Coin_B>(coin_a: Coin<Coin_A>, coin_b: Coin<Coin_B>, ctx: &mut TxContext) {
            let coin_a_value = coin::value(&coin_a);
            let coin_b_value = coin::value(&coin_b);

            assert!(coin_a_value > 0 && coin_b_value > 0, EInValueZore);

            let balance_a = coin::into_balance(coin_a);
            let balance_b = coin::into_balance(coin_b);
            
            let lp_value = std::u64::sqrt(coin_a_value) * std::u64::sqrt(coin_b_value);
            let mut lp_supply = balance::create_supply(LP<Coin_A, Coin_B> {});
            let lp_supply_balance = balance::increase_supply(&mut lp_supply, lp_value);
            let pool = Pool {
                id: object::new(ctx),
                balance_a,
                balance_b,
                lp_supply,
            };

            event::emit(PoolCreated {
                pool_id: object::id(&pool),
                coin_a: type_name::get<Coin_A>(),
                coin_b: type_name::get<Coin_B>(),
                coin_a_value: coin_a_value,
                coin_b_value: coin_b_value,
                lp_minted: balance::supply_value(&pool.lp_supply),
            });

            let lp_coin = coin::from_balance(lp_supply_balance, ctx);

            transfer::share_object(pool);
            transfer::public_transfer(lp_coin, sender(ctx));
        }

        public entry fun add_liquidity<Coin_A, Coin_B>(pool: &mut Pool<Coin_A, Coin_B>, coin_a: Coin<Coin_A>, coin_b: Coin<Coin_B>, ctx: &mut TxContext) {
            let mut coin_a_value = coin::value(&coin_a);
            let mut coin_b_value = coin::value(&coin_b);

            assert!(coin_a_value > 0 && coin_b_value > 0, EInValueZore);

            let balance_a_value = balance::value(&pool.balance_a);
            let balance_b_value = balance::value(&pool.balance_b);

            let rate_a = balance_a_value / coin_a_value;
            let rate_b = balance_b_value / coin_b_value;

            balance::join(&mut pool.balance_a, coin::into_balance(coin_a));
            balance::join(&mut pool.balance_b, coin::into_balance(coin_b));

            if (rate_a == rate_b) {

            } else if (rate_a < rate_b) {
                let extra_a_value = coin_a_value - (balance_a_value / rate_b);
                let extra_coin_a_balance = balance::split(&mut pool.balance_a, extra_a_value);
                let extra_coin_a = coin::from_balance(extra_coin_a_balance, ctx);

                transfer::public_transfer(extra_coin_a, sender(ctx));

                coin_a_value = coin_a_value - extra_a_value;
            } else {
                let extra_b_value = coin_b_value - (balance_b_value / rate_a);
                let extra_coin_b_balance = balance::split(&mut pool.balance_b, extra_b_value);
                let extra_coin_b = coin::from_balance(extra_coin_b_balance, ctx);

                transfer::public_transfer(extra_coin_b, sender(ctx));

                coin_b_value = coin_b_value - extra_b_value;
            };

            let balance_lp_supply_value = balance::supply_value(&pool.lp_supply);
            let new_lp_supply_value = std::u64::sqrt(coin_a_value + balance_a_value) * std::u64::sqrt(coin_b_value + balance_b_value);
            let add_lp_supply_value = new_lp_supply_value - balance_lp_supply_value;

            event::emit(LiquidityAdded {
                pool_id: object::id(pool),
                coin_a: type_name::get<Coin_A>(),
                coin_b: type_name::get<Coin_B>(),
                coin_a_value: balance::value(&pool.balance_a),
                coin_b_value: balance::value(&pool.balance_b),
                lp_minted: new_lp_supply_value,
            });

            let lp_supply_balance = balance::increase_supply(&mut pool.lp_supply, add_lp_supply_value);
            let lp_coin = coin::from_balance(lp_supply_balance, ctx);
            transfer::public_transfer(lp_coin, ctx.sender());
        }

        public entry fun remove_liquidity<Coin_A, Coin_B>(pool: &mut Pool<Coin_A, Coin_B>, lp_coin: Coin<LP<Coin_A, Coin_B>>, ctx: &mut TxContext) {
            let lp_coin_value = coin::value(&lp_coin);
            assert!(lp_coin_value > 0, EInValueZore);

            let balance_lp_supply_value = balance::supply_value(&pool.lp_supply);
            let balance_a_value = balance::value(&pool.balance_a);
            let balance_b_value = balance::value(&pool.balance_b);

            let rate_lp = lp_coin_value / balance_lp_supply_value;
            let remove_a_value = balance_a_value * rate_lp;
            let remove_b_value = balance_b_value * rate_lp;

            balance::decrease_supply(&mut pool.lp_supply, coin::into_balance(lp_coin));

            let remove_balance_a = balance::split(&mut pool.balance_a, remove_a_value);
            let remove_balance_b = balance::split(&mut pool.balance_b, remove_b_value);

            let remove_coin_a = coin::from_balance(remove_balance_a, ctx);
            let remove_coin_b = coin::from_balance(remove_balance_b, ctx);

            event::emit(LiquidityRemoved {
                pool_id: object::id(pool),
                coin_a: type_name::get<Coin_A>(),
                coin_b: type_name::get<Coin_B>(),
                coin_a_value: remove_a_value,
                coin_b_value: remove_a_value,
                lp_burned: lp_coin_value,
            });

            transfer::public_transfer(remove_coin_a, sender(ctx));
            transfer::public_transfer(remove_coin_b, sender(ctx));
        }

        public entry fun swap_a_to_b<Coin_A, Coin_B>(pool: &mut Pool<Coin_A, Coin_B>, coin_a: Coin<Coin_A>, ctx: &mut TxContext) {
            let coin_a_value = coin::value(&coin_a);
            let balance_a_value = balance::value(&pool.balance_a);
            let balance_b_value = balance::value(&pool.balance_b);
            assert!(coin_a_value > 0, EInValueZore);
            assert!(balance_a_value > 0, EPoolValueZore);

            let k = balance_a_value * balance_b_value;
            let new_coin_a_value = coin_a_value + balance_a_value;
            let out_b_value = balance_b_value - (k / new_coin_a_value);

            let pay_fee_value = out_b_value / 10000 * 30;
            let out_real_b_value = out_b_value - pay_fee_value;

            event::emit(Swaped {
                pool_id: object::id(pool),
                coin_in: type_name::get<Coin_A>(),
                value_in: coin_a_value,
                coin_out: type_name::get<Coin_B>(),
                value_out: out_real_b_value,
            });

            let in_balance_a = coin ::into_balance(coin_a);
            balance::join(&mut pool.balance_a, in_balance_a);

            let out_coin_b_balance = balance::split(&mut pool.balance_b, out_real_b_value);
            let out_coin_b = coin::from_balance(out_coin_b_balance, ctx);
            transfer::public_transfer(out_coin_b, sender(ctx));
        }

        public entry fun swap_b_to_a<Coin_A, Coin_B>(pool: &mut Pool<Coin_A, Coin_B>, coin_b: Coin<Coin_B>, ctx: &mut TxContext) {
            let coin_b_value = coin::value(&coin_b);
            let balance_a_value = balance::value(&pool.balance_a);
            let balance_b_value = balance::value(&pool.balance_b);
            assert!(coin_b_value > 0, EInValueZore);
            assert!(balance_b_value > 0, EPoolValueZore);

            let k = balance_a_value * balance_b_value;
            let new_coin_b_value = coin_b_value + balance_b_value;
            let out_a_value = balance_a_value - (k / new_coin_b_value);

            let pay_fee_value = out_a_value / 10000 * 30;
            let out_real_a_value = out_a_value - pay_fee_value;

            event::emit(Swaped {
                pool_id: object::id(pool),
                coin_in: type_name::get<Coin_B>(),
                value_in: coin_b_value,
                coin_out: type_name::get<Coin_A>(),
                value_out: out_real_a_value,
            });

            let in_balance_b = coin ::into_balance(coin_b);
            balance::join(&mut pool.balance_b, in_balance_b);

            let out_coin_a_balance = balance::split(&mut pool.balance_a, out_real_a_value);
            let out_coin_a = coin::from_balance(out_coin_a_balance, ctx);
            transfer::public_transfer(out_coin_a, sender(ctx));
        }