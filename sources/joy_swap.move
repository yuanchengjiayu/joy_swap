module joy_swap::joy_swap;
    use sui::tx_context::sender;
    use sui::balance::{Self, Balance, Supply};
    use sui::coin::{Self, Coin};
    use std::type_name::{Self, TypeName};
    use sui::event;
    use sui::table::{ Self, Table };

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

   public struct Factory has key {
        id: UID,
        table: Table<PoolItem, bool>,
    }

    public struct PoolItem has copy, drop, store {
        a: TypeName,
        b: TypeName,
    }

   fun add_pool<Coin_A, Coin_B>(factory: &mut Factory) {
        let a = type_name::get<Coin_A>();
        let b = type_name::get<Coin_B>();
        let item = PoolItem { a, b };
        assert!(table::contains(&factory.table, item) == false);
        table::add(&mut factory.table, item, true);
    }

    fun init(ctx: &mut TxContext) {
        let factory = Factory {
            id: object::new(ctx),
            table: table::new(ctx),
        };
        transfer::share_object(factory);
    }

    public entry fun create_pool<Coin_A, Coin_B>(factory: &mut Factory, coin_a: Coin<Coin_A>, coin_b: Coin<Coin_B>, ctx: &mut TxContext) {
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
        add_pool<Coin_A, Coin_B>(factory);
        let lp_coin = coin::from_balance(lp_supply_balance, ctx);

        transfer::share_object(pool);
        transfer::public_transfer(lp_coin, sender(ctx));
    }

    public entry fun add_liquidity<Coin_A, Coin_B>(pool: &mut Pool<Coin_A, Coin_B>, mut coin_a: Coin<Coin_A>, mut coin_b: Coin<Coin_B>, amount: u64, ctx: &mut TxContext) {
        let coin_a_value = coin::value(&coin_a);
        let coin_b_value = coin::value(&coin_b);
        let lp_supply_value = balance::supply_value(&pool.lp_supply);
        let balance_a_value = balance::value(&pool.balance_a);
        let balance_b_value = balance::value(&pool.balance_b);
        assert!(amount > 0);
        assert!(coin_a_value > 0 && coin_b_value > 0, EInValueZore);
        let mut coin_a_in_value = 0;
        let mut coin_b_in_value = 0;

        if (balance_a_value == 0 || balance_b_value == 0) {
            let coin_a_in = coin::split(&mut coin_a, amount, ctx);
            let coin_b_in = coin::split(&mut coin_b, amount, ctx);
            coin_a_in_value = coin::value(&coin_a_in);
            coin_b_in_value = coin::value(&coin_b_in);
            balance::join(&mut pool.balance_a, coin::into_balance(coin_a_in));
            balance::join(&mut pool.balance_b, coin::into_balance(coin_b_in));
        } else {
            if (amount == lp_supply_value) {
                let coin_a_in = coin::split(&mut coin_a, balance_a_value, ctx);
                let coin_b_in = coin::split(&mut coin_b, balance_b_value, ctx);
                coin_a_in_value = coin::value(&coin_a_in);
                coin_b_in_value = coin::value(&coin_b_in);
                balance::join(&mut pool.balance_a, coin::into_balance(coin_a_in));
                balance::join(&mut pool.balance_b, coin::into_balance(coin_b_in));
            } else if(amount > lp_supply_value) {
                let rate = amount * 1000 / lp_supply_value;
                let coin_a_in = coin::split(&mut coin_a, ((balance_a_value * rate)  / 1000) as u64, ctx);
                let coin_b_in = coin::split(&mut coin_b, ((balance_b_value * rate)  / 1000) as u64, ctx);
                coin_a_in_value = coin::value(&coin_a_in);
                coin_b_in_value = coin::value(&coin_b_in);
                balance::join(&mut pool.balance_a, coin::into_balance(coin_a_in));
                balance::join(&mut pool.balance_b, coin::into_balance(coin_b_in));
            } else {
                let rate = lp_supply_value * 1000 / amount;
                let coin_a_in = coin::split(&mut coin_a, ((balance_a_value * 1000) / rate) as u64, ctx);
                let coin_b_in = coin::split(&mut coin_b, ((balance_b_value * 1000) / rate) as u64, ctx);
                coin_a_in_value = coin::value(&coin_a_in);
                coin_b_in_value = coin::value(&coin_b_in);
                balance::join(&mut pool.balance_a, coin::into_balance(coin_a_in));
                balance::join(&mut pool.balance_b, coin::into_balance(coin_b_in));
            };
        };
        
        event::emit(LiquidityAdded {
            pool_id: object::id(pool),
            coin_a: type_name::get<Coin_A>(),
            coin_b: type_name::get<Coin_B>(),
            coin_a_value: coin_a_in_value,
            coin_b_value: coin_b_in_value,
            lp_minted: amount,
        });
        
        transfer::public_transfer(coin_a, sender(ctx));
        transfer::public_transfer(coin_b, sender(ctx));
        let lp_supply_balance = balance::increase_supply(&mut pool.lp_supply, amount);
        let lp_coin = coin::from_balance(lp_supply_balance, ctx);
        transfer::public_transfer(lp_coin, sender(ctx));
    }

    public entry fun remove_liquidity<Coin_A, Coin_B>(pool: &mut Pool<Coin_A, Coin_B>, mut lp_coin: Coin<LP<Coin_A, Coin_B>>, amount: u64, ctx: &mut TxContext) {
        let lp_coin_value = coin::value(&lp_coin);
        assert!(amount > 0 && lp_coin_value >= amount, EPoolValueZore);
        let balance_lp_supply_value = balance::supply_value(&pool.lp_supply);
        let rete = (balance_lp_supply_value * 1000) / amount;
        let remove_a_value = ((balance::value(&pool.balance_a) * 1000) / rete) as u64;
        let remove_b_value = ((balance::value(&pool.balance_b) * 1000) / rete) as u64;
        let lp_coin_re = coin::split(&mut lp_coin, amount, ctx);
        balance::decrease_supply(&mut pool.lp_supply, coin::into_balance(lp_coin_re));

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
            lp_burned: amount,
        });

        transfer::public_transfer(remove_coin_a, sender(ctx));
        transfer::public_transfer(remove_coin_b, sender(ctx));
        transfer::public_transfer(lp_coin, sender(ctx));
    }

    public entry fun swap_a_to_b<Coin_A, Coin_B>(pool: &mut Pool<Coin_A, Coin_B>, mut coin_a: Coin<Coin_A>, amount: u64, ctx: &mut TxContext) {
        let coin_a_value = coin::value(&coin_a);
        let balance_a_value = balance::value(&pool.balance_a);
        let balance_b_value = balance::value(&pool.balance_b);
        assert!(amount > 0 && coin_a_value >= amount, EInValueZore);
        assert!(balance_a_value > 0 && balance_b_value > 0, EPoolValueZore);

        let coin_a_in = coin::split(&mut coin_a, amount, ctx);
        balance ::join(&mut pool.balance_a, coin::into_balance(coin_a_in));

        let lp_supply_value = balance::supply_value(&pool.lp_supply);
        // let b_value = balance_b_value - ((lp_supply_value * lp_supply_value) / (balance_a_value + amount));
        let b_value = balance_b_value - ((((lp_supply_value as u128) * (lp_supply_value as u128)) / ((balance_a_value as u128) + (amount as u128))) as u64);//类型转换
        let pay_fee_value = b_value * 30 / 10000;
        let out_b_value = b_value - pay_fee_value;

        let out_coin_b_balance = balance::split(&mut pool.balance_b, out_b_value);
        let out_coin_b = coin::from_balance(out_coin_b_balance, ctx);

        event::emit(Swaped {
            pool_id: object::id(pool),
            coin_in: type_name::get<Coin_A>(),
            value_in: amount,
            coin_out: type_name::get<Coin_B>(),
            value_out: out_b_value,
        });

        transfer::public_transfer(out_coin_b, sender(ctx));
        transfer::public_transfer(coin_a, sender(ctx));
    }

    public entry fun swap_b_to_a<Coin_A, Coin_B>(pool: &mut Pool<Coin_A, Coin_B>, mut coin_b: Coin<Coin_B>, amount: u64, ctx: &mut TxContext) {
        let coin_b_value = coin::value(&coin_b);
        let balance_a_value = balance::value(&pool.balance_a); 
        let balance_b_value = balance::value(&pool.balance_b);
        assert!(amount > 0 && coin_b_value >= amount, EInValueZore);
        assert!(balance_b_value > 0 && balance_a_value > 0, EPoolValueZore);

        let coin_b_in = coin::split(&mut coin_b, amount, ctx);
        balance ::join(&mut pool.balance_b, coin::into_balance(coin_b_in));

        let lp_supply_value = balance::supply_value(&pool.lp_supply);
        // let a_value = balance_a_value - ((lp_supply_value * lp_supply_value) / (balance_b_value + amount));
        let a_value = balance_a_value - ((((lp_supply_value as u128) * (lp_supply_value as u128)) / ((balance_b_value as u128) + (amount as u128))) as u64);
        let pay_fee_value = a_value * 30 / 10000;
        let out_a_value = a_value - pay_fee_value;

        let out_coin_a_balance = balance::split(&mut pool.balance_a, out_a_value);
        let out_coin_a = coin::from_balance(out_coin_a_balance, ctx);

        event::emit(Swaped {
            pool_id: object::id(pool),
            coin_in: type_name::get<Coin_B>(),
            value_in: amount,
            coin_out: type_name::get<Coin_A>(),
            value_out: out_a_value,
        });

        transfer::public_transfer(out_coin_a, sender(ctx));
        transfer::public_transfer(coin_b, sender(ctx));
    }