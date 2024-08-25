#[allow(implicit_const_copy)]
module clamm::interest_pool {
  // === Imports ===

  use std::{
    string::String,
    type_name::{Self, TypeName}
  };

  use sui::{
    bag::{Self, Bag},
    versioned::Versioned,
    vec_map::{Self, VecMap},
    vec_set::{Self, VecSet}
  };

  use suitears::comparator::{compare, eq};

  use clamm::{
    curves,
    errors,
    pool_events as events,
    pool_admin::PoolAdmin
  };

  // === Constants ===

  const START_SWAP: vector<u8> = b"START_SWAP";
  const FINISH_SWAP: vector<u8> = b"FINISH_SWAP";
  
  const START_ADD_LIQUIDITY: vector<u8> = b"START_ADD_LIQUIDITY";
  const FINISH_ADD_LIQUIDITY: vector<u8> = b"FINISH_ADD_LIQUIDITY";

  const START_REMOVE_LIQUIDITY: vector<u8> = b"START_REMOVE_LIQUIDITY";
  const FINISH_REMOVE_LIQUIDITY: vector<u8> = b"FINISH_REMOVE_LIQUIDITY";

  const START_DONATE: vector<u8> = b"START_DONATE";
  const FINISH_DONATE: vector<u8> = b"FINISH_DONATE";

  // === Structs ===

  public struct InterestPool<phantom Curve> has key {
    id: UID,
    coins: VecSet<TypeName>,
    state: Versioned,
    hooks: Option<Hooks>,
    paused: bool
  }

  public struct Hooks has store {
    rules: VecMap<String, VecSet<TypeName>>,
    config: Bag
  }

  public struct HooksBuilder {
    pool_address: address,
    rules: VecMap<String, VecSet<TypeName>>,
    config: Bag
  }

  public struct Request {
    name: String,
    pool_address: address,
    approvals: VecSet<TypeName>
  }

  // === Public Mutative Functions ===

  #[allow(lint(share_owned))]
  public fun share<Curve>(self: InterestPool<Curve>) {
    transfer::share_object(self);
  }

  public fun start_swap<Curve>(self: &InterestPool<Curve>): Request {
    assert!(self.has_swap_hooks(), errors::pool_has_no_swap_hooks());
    new_request(self, START_SWAP.to_string())
  }

  public fun start_add_liquidity<Curve>(self: &InterestPool<Curve>): Request {
    assert!(self.has_add_liquidity_hooks(), errors::pool_has_no_add_liquidity_hooks());
    new_request(self, START_ADD_LIQUIDITY.to_string())
  }

  public fun start_remove_liquidity<Curve>(self: &InterestPool<Curve>): Request {
    assert!(self.has_remove_liquidity_hooks(), errors::pool_has_no_remove_liquidity_hooks());
    new_request(self, START_REMOVE_LIQUIDITY.to_string())
  }  

  public fun start_donate<Curve>(self: &InterestPool<Curve>): Request {
    assert!(self.has_donate_hooks(), errors::pool_has_no_donate_hooks());
    new_request(self, START_DONATE.to_string())
  }  

  public fun finish<Curve>(self: &InterestPool<Curve>, request: Request) {
    assert!(
      request.name().index_of(&b"F".to_string()) == 0, 
      errors::must_be_finish_request()
    );
    confirm(self, request);      
  }  

  // === Public-View Functions ===

  public fun start_swap_name(): vector<u8> {
    START_SWAP
  }

  public fun finish_swap_name(): vector<u8> {
    FINISH_SWAP
  }

  public fun start_add_liquidity_name(): vector<u8> {
    START_ADD_LIQUIDITY
  }

  public fun finish_add_liquidity_name(): vector<u8> {
    FINISH_ADD_LIQUIDITY
  }

  public fun start_remove_liquidity_name(): vector<u8> {
    START_REMOVE_LIQUIDITY
  }

  public fun finish_remove_liquidity_name(): vector<u8> {
    FINISH_REMOVE_LIQUIDITY
  }

  public fun start_donate_name(): vector<u8> {
    START_DONATE
  }

  public fun finish_donate_name(): vector<u8> {
    FINISH_DONATE
  }

  public fun has_hooks<Curve>(self: &InterestPool<Curve>): bool {
    self.hooks.is_some()
  }

  public fun has_swap_hooks<Curve>(self: &InterestPool<Curve>): bool {
    has_hook(self, START_SWAP, FINISH_SWAP)
  }

  public fun has_add_liquidity_hooks<Curve>(self: &InterestPool<Curve>): bool {
    has_hook(self, START_ADD_LIQUIDITY, FINISH_ADD_LIQUIDITY)
  }

  public fun has_remove_liquidity_hooks<Curve>(self: &InterestPool<Curve>): bool {
    has_hook(self, START_REMOVE_LIQUIDITY, FINISH_REMOVE_LIQUIDITY)
  }

  public fun has_donate_hooks<Curve>(self: &InterestPool<Curve>): bool {
    has_hook(self, START_DONATE, FINISH_DONATE)
  }

  public fun swap_hooks<Curve>(self: &InterestPool<Curve>): (vector<TypeName>, vector<TypeName>) {
    hook(self, START_SWAP, FINISH_SWAP)
  }

  public fun add_liquidity_hooks<Curve>(self: &InterestPool<Curve>): (vector<TypeName>, vector<TypeName>) {
    hook(self, START_ADD_LIQUIDITY, FINISH_ADD_LIQUIDITY)
  }

  public fun remove_liquidity_hooks<Curve>(self: &InterestPool<Curve>): (vector<TypeName>, vector<TypeName>) {
    hook(self, START_REMOVE_LIQUIDITY, FINISH_REMOVE_LIQUIDITY)
  }

  public fun donate_hooks<Curve>(self: &InterestPool<Curve>): (vector<TypeName>, vector<TypeName>) {
    hook(self, START_DONATE, FINISH_DONATE)
  }

  public fun has_rule_config<Curve, Rule: drop>(self: &InterestPool<Curve>): bool {
    self.hooks.borrow().config.contains(type_name::get<Rule>())
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

  public fun pool_address_(hooks_builder: &HooksBuilder): address {
    hooks_builder.pool_address
  }

  public fun rules(hooks_builder: &HooksBuilder): &VecMap<String, VecSet<TypeName>> {
    &hooks_builder.rules
  }

  public fun config_(hooks_builder: &HooksBuilder): &Bag {
    &hooks_builder.config
  }

  // === Witness Functions ===

  public fun add_hooks<Curve>(pool: &mut InterestPool<Curve>, hooks_builder: HooksBuilder) {
    curves::assert_curve<Curve>();

    let HooksBuilder { rules, config, pool_address  } = hooks_builder;

    assert!(pool.addy() == pool_address, errors::wrong_hooks_builder_pool());

    pool.hooks.fill(Hooks { rules, config });
  }

  public fun add_rule<Rule: drop>(
    hooks_builder: &mut HooksBuilder, 
    name: String,
    _: Rule,
  ) {
    hooks_builder.rules.get_mut(&name).insert(type_name::get<Rule>());
  }

  public fun add_rule_config<Rule: drop, Config: store>(
    hooks_builder: &mut HooksBuilder, 
    _: Rule,
    config: Config  
  ) {
    hooks_builder.config.add(type_name::get<Rule>(), config)
  }

  public fun config_mut<Curve, Rule: drop, Config: store>(self: &mut InterestPool<Curve>, _: Rule): &mut Config {
    self.hooks.borrow_mut().config.borrow_mut(type_name::get<Rule>())
  }

  public fun approve<Rule: drop>(request: &mut Request, _: Rule) {
    request.approvals.insert(type_name::get<Rule>());
  }

  // === Admin Functions ===

  public fun uid_mut<Curve>(self: &mut InterestPool<Curve>, _: &PoolAdmin): &mut UID {
    &mut self.id
  }

  public fun pause<Curve>(self: &mut InterestPool<Curve>, _: &PoolAdmin) {
    self.paused = true;

    events::pause(self.addy());
  }

  public fun unpause<Curve>(self: &mut InterestPool<Curve>, _: &PoolAdmin) {
    self.paused = false;

    events::unpause(self.addy());
  }

  // === Public-Package Functions ===

  public fun assert_is_live<Curve>(self: &InterestPool<Curve>) {
    assert!(!self.paused, errors::pool_is_paused());
  }

  public(package) fun addy<Curve>(self: &InterestPool<Curve>): address {
    self.id.to_address()
  }

  public(package) fun coins<Curve>(self: &InterestPool<Curve>): vector<TypeName> {
    *self.coins.keys()
  }

  public(package) fun are_coins_ordered<Curve>(self: &InterestPool<Curve>, coins: vector<TypeName>): bool {
    eq(&compare(&self.coins(), &coins))
  }

  public(package) fun state_mut<Curve>(self: &mut InterestPool<Curve>): &mut Versioned {
    &mut self.state
  }

  public(package) fun new_request<Curve>(self: &InterestPool<Curve>, name: String): Request {
    Request {
      name,
      pool_address: self.addy(),
      approvals: vec_set::empty()
    }
  }

  public(package) fun new<Curve>(coins: VecSet<TypeName>, state: Versioned, ctx: &mut TxContext): InterestPool<Curve>  {
    curves::assert_curve<Curve>();

    InterestPool {
      id: object::new(ctx),
      coins,
      state,
      hooks: option::none(),
      paused: false
    }
  }

  public(package) fun new_with_hooks<Curve>(
    coins: VecSet<TypeName>, 
    state: Versioned,
    ctx: &mut TxContext
  ): (InterestPool<Curve>, HooksBuilder)  {
    curves::assert_curve<Curve>();

    let self = InterestPool {
      id: object::new(ctx),
      coins,
      state,
      hooks: option::none(),
      paused: false
    };

    let hooks_builder = new_hooks_builder(self.addy(), ctx);

    (self, hooks_builder)
  }  

  public(package) fun finish_swap<Curve>(self: &InterestPool<Curve>, request: Request): Request {
    assert!(self.has_swap_hooks(), errors::pool_has_no_swap_hooks());
    assert!(request.name().as_bytes() == START_SWAP, errors::must_be_start_swap_request());
    
    self.confirm(request);

    self.new_request(FINISH_SWAP.to_string())     
  }

  public(package) fun finish_add_liquidity<Curve>(self: &InterestPool<Curve>, request: Request): Request {
    assert!(self.has_add_liquidity_hooks(), errors::pool_has_no_add_liquidity_hooks());
    assert!(
      request.name().as_bytes() == START_ADD_LIQUIDITY, 
      errors::must_be_start_add_liquidity_request()
    );
    
    self.confirm(request);

    self.new_request(FINISH_ADD_LIQUIDITY.to_string())    
  }

  public(package) fun finish_remove_liquidity<Curve>(self: &InterestPool<Curve>, request: Request): Request {
    assert!(self.has_remove_liquidity_hooks(), errors::pool_has_no_remove_liquidity_hooks());
    assert!(
      request.name().as_bytes() == START_REMOVE_LIQUIDITY, 
      errors::must_be_start_remove_liquidity_request()
    );
    
    self.confirm(request);

    self.new_request(FINISH_REMOVE_LIQUIDITY.to_string())
  }  

  public(package) fun finish_donate<Curve>(self: &InterestPool<Curve>, request: Request): Request {
    assert!(self.has_donate_hooks(), errors::pool_has_no_donate_hooks());
    assert!(request.name().as_bytes() == START_DONATE, errors::must_be_start_donate_request());
    
    self.confirm(request);

    self.new_request(FINISH_DONATE.to_string())     
  }

  // === Private Functions ===  

  fun new_hooks_builder(pool_address: address, ctx: &mut TxContext): HooksBuilder {
    let mut rules = vec_map::empty();

    rules.insert(START_SWAP.to_string(), vec_set::empty());
    rules.insert(FINISH_SWAP.to_string(), vec_set::empty());
    
    rules.insert(START_ADD_LIQUIDITY.to_string(), vec_set::empty());
    rules.insert(FINISH_ADD_LIQUIDITY.to_string(), vec_set::empty());
    
    rules.insert(START_REMOVE_LIQUIDITY.to_string(), vec_set::empty());
    rules.insert(FINISH_REMOVE_LIQUIDITY.to_string(), vec_set::empty());

    rules.insert(START_DONATE.to_string(), vec_set::empty());
    rules.insert(FINISH_DONATE.to_string(), vec_set::empty());

    HooksBuilder {
      pool_address,
      rules,
      config: bag::new(ctx)
    }
  }

  fun has_hook<Curve>(self: &InterestPool<Curve>, start: vector<u8>, finish: vector<u8>): bool {
    if (!has_hooks(self)) return false;

    let rules = self.hooks.borrow().rules;

    !rules.get(&start.to_string()).is_empty() || !rules.get(&finish.to_string()).is_empty()
  }  

  fun hook<Curve>(
    self: &InterestPool<Curve>, 
    start: vector<u8>, 
    finish: vector<u8>
  ): (vector<TypeName>, vector<TypeName>) {
    if (!has_hooks(self)) return (vector[], vector[]);

    let rules = self.hooks.borrow().rules;

    (
      (*rules.get(&start.to_string())).into_keys(),
      (*rules.get(&finish.to_string())).into_keys(),
    )
  }

  fun confirm<Curve>(self: &InterestPool<Curve>, request: Request) {
    let hooks = self.hooks.borrow();
    let Request { name, pool_address, approvals } = request;

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

  // === Test-Only Functions ===  

  #[test_only]
  public fun confirm_for_testing<Curve>(self: &InterestPool<Curve>, request: Request) {
    confirm(self, request)
  }

  #[test_only]
  public fun paused<Curve>(self: &InterestPool<Curve>): bool {
    self.paused
  }
}