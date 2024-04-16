module clamm::interest_pool {
  // === Imports ===

  use std::string::String;
  use std::type_name::{Self, TypeName};

  use sui::bag::{Self, Bag};
  use sui::versioned::Versioned;
  use sui::vec_map::{Self, VecMap};
  use sui::vec_set::{Self, VecSet};

  use suitears::comparator::{compare, eq};

  use clamm::curves;
  use clamm::errors;
  use clamm::pool_admin::{Self, PoolAdmin};

  // === Constants ===

  const START_SWAP: vector<u8> = b"START_SWAP";
  const FINISH_SWAP: vector<u8> = b"FINISH_SWAP";
  
  const START_ADD_LIQUIDITY: vector<u8> = b"START_ADD_LIQUIDITY";
  const FINISH_ADD_LIQUIDITY: vector<u8> = b"FINISH_ADD_LIQUIDITY";

  const START_REMOVE_LIQUIDITY: vector<u8> = b"START_ADD_LIQUIDITY";
  const FINISH_REMOVE_LIQUIDITY: vector<u8> = b"FINISH_ADD_LIQUIDITY";

  // === Structs ===

  public struct InterestPool<phantom Curve> has key {
    id: UID,
    coins: VecSet<TypeName>,
    state: Versioned,
    pool_admin_address: address,
    hooks: Option<Hooks>
  }

  public struct Hooks has store {
    rules: VecMap<String, VecSet<TypeName>>,
    config: Bag
  }

  public struct HooksBuilder {
    rules: VecMap<String, VecSet<TypeName>>,
    config: Bag
  }

  public struct Request {
    name: String,
    pool_address: address,
    approvals: VecSet<TypeName>
  }

  // === Public Mutative Functions ===

  public fun share<Curve>(self: InterestPool<Curve>) {
    transfer::share_object(self);
  }

  public fun assert_pool_admin<Curve>(self: &InterestPool<Curve>, pool_admin: &PoolAdmin) {
    assert!(self.pool_admin_address == pool_admin.addy(), errors::invalid_pool_admin());
  }

  public fun new_hooks_builder(ctx: &mut TxContext): HooksBuilder {
    HooksBuilder {
      rules: vec_map::empty(),
      config: bag::new(ctx)
    }
  }

  // === Public-View Functions ===

  public fun addy<Curve>(self: &InterestPool<Curve>): address {
    self.id.to_address()
  }

  public fun coins<Curve>(self: &InterestPool<Curve>): vector<TypeName> {
    *self.coins.keys()
  }

  public fun pool_admin_address<Curve>(self: &InterestPool<Curve>): address {
    self.pool_admin_address
  }

  public fun are_coins_ordered<Curve>(self: &InterestPool<Curve>, coins: vector<TypeName>): bool {
    eq(&compare(&self.coins(), &coins))
  }

  public fun start_swap(): vector<u8> {
    START_SWAP
  }

  public fun finish_swap(): vector<u8> {
    FINISH_SWAP
  }

  public fun start_add_liquidity(): vector<u8> {
    START_ADD_LIQUIDITY
  }

  public fun finish_add_liquidity(): vector<u8> {
    FINISH_ADD_LIQUIDITY
  }

  public fun start_remove_liquidity(): vector<u8> {
    START_REMOVE_LIQUIDITY
  }

  public fun finish_remove_liquidity(): vector<u8> {
    FINISH_REMOVE_LIQUIDITY
  }

  public fun has_hooks<Curve>(self: &InterestPool<Curve>): bool {
    self.hooks.is_some()
  }

  public fun has_rule_config<Curve, Rule: drop>(pool: &InterestPool<Curve>): bool {
    pool.hooks.borrow().config.contains(type_name::get<Rule>())
  }

  public fun config<Curve, Rule: drop, Config: store>(self: &InterestPool<Curve>): &Config {
    self.hooks.borrow().config.borrow(type_name::get<Rule>())
  }

  public fun pool_address(request: &Request): address {
    request.pool_address
  }

  public fun name(request: &Request): String {
    request.name
  }

  public fun approvals(request: &Request): VecSet<TypeName> {
    request.approvals
  }

  // === Admin Functions ===

  public fun uid_mut<Curve>(self: &mut InterestPool<Curve>, pool_admin: &PoolAdmin): &mut UID {
    assert_pool_admin(self, pool_admin);
    &mut self.id
  }

  // === Witness Functions ===

  public fun add_rule<Rule: drop>(
    hooks_builder: &mut HooksBuilder, 
    name: String,
    _: Rule,
  ) {

    if (!hooks_builder.rules.contains(&name)) {
      hooks_builder.rules.insert(name, vec_set::empty());
    };

    hooks_builder.rules.get_mut(&name).insert(type_name::get<Rule>());
  }

  public fun add_rule_config<Rule: drop, Config: store>(
    hooks_builder: &mut HooksBuilder, 
    _: Rule,
    config: Config  
  ) {
    hooks_builder.config.add(type_name::get<Rule>(), config)
  }

  public fun config_mut<Curve, Rule: drop, Config: store>(pool: &mut InterestPool<Curve>, _: Rule): &mut Config {
    pool.hooks.borrow_mut().config.borrow_mut(type_name::get<Rule>())
  }

  public fun approve<Rule: drop>(request: &mut Request, _: Rule) {
    request.approvals.insert(type_name::get<Rule>());
  }

  // === Public-Package Functions ===

  public(package) fun state<Curve>(self: &InterestPool<Curve>): &Versioned {
    &self.state
  }

  public(package) fun state_mut<Curve>(self: &mut InterestPool<Curve>): &mut Versioned {
    &mut self.state
  }

  public(package) fun new<Curve>(coins: VecSet<TypeName>, state: Versioned, ctx: &mut TxContext): (InterestPool<Curve>, PoolAdmin)  {
    curves::assert_curve<Curve>();
    let pool_admin = pool_admin::new(ctx);
    let pool = InterestPool {
      id: object::new(ctx),
      coins,
      state,
      pool_admin_address: pool_admin.addy(),
      hooks: option::none()
    };

    (pool, pool_admin)
  }

  public(package) fun new_with_hooks<Curve>(
    coins: VecSet<TypeName>, 
    state: Versioned, 
    hooks_builder: HooksBuilder,
     ctx: &mut TxContext
  ): (InterestPool<Curve>, PoolAdmin)  {
    curves::assert_curve<Curve>();

    let HooksBuilder { rules, config  } = hooks_builder;

    let pool_admin = pool_admin::new(ctx);
    let pool = InterestPool {
      id: object::new(ctx),
      coins,
      state,
      pool_admin_address: pool_admin.addy(),
      hooks: option::some(Hooks { rules, config })
    };

    (pool, pool_admin)
  }  

  public(package) fun new_request<Curve>(self: &InterestPool<Curve>, name: String): Request {
    Request {
      name,
      pool_address: self.addy(),
      approvals: vec_set::empty()
    }
  }

  public(package) fun confirm<Curve>(self: &InterestPool<Curve>, request: Request) {
    let hooks = self.hooks.borrow();
    let Request { name, pool_address, approvals } = request;

    assert!(hooks.rules.contains(&name), errors::invalid_rule_name());
    assert!(self.addy() == pool_address, errors::wrong_request_pool_address());

    let rules = (*hooks.rules.get(&name)).into_keys();
    let rules_len = rules.length();
    let mut i = 0;

    while (rules_len > i) {
      let rule = &rules[i];
      assert!(approvals.contains(rule), errors::rule_not_approved());
      i = i + 1;
    }
  } 
}