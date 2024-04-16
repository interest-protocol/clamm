module clamm::policy {
  // === Imports ===

  use std::string::String;
  use std::type_name::TypeName;

  use sui::vec_map::VecMap;
  use sui::vec_set::{Self, VecSet};

  use clamm::errors;
  use clamm::interest_pool::InterestPool;

  // === Constants ===

  const PRE_SWAP: vector<u8> = b"PRE_SWAP";
  const POST_SWAP: vector<u8> = b"POST_SWAP";
  
  const PRE_ADD_LIQUIDITY: vector<u8> = b"PRE_ADD_LIQUIDITY";
  const POST_ADD_LIQUIDITY: vector<u8> = b"POST_ADD_LIQUIDITY";

  const PRE_REMOVE_LIQUIDITY: vector<u8> = b"PRE_ADD_LIQUIDITY";
  const POST_REMOVE_LIQUIDITY: vector<u8> = b"POST_ADD_LIQUIDITY";

  // === Structs ===

  public struct Policy has key {
   id: UID,
   pool_address: address,
   rules: VecMap<String, VecSet<TypeName>>,
   /// SDK to know the id of the package to call
   packages: VecMap<String, vector<address>>,
  }

  public struct PolicyBuilder {
   rules: VecMap<String, VecSet<TypeName>>,
   /// SDK to know the id of the package to call
   packages: VecMap<String, vector<address>>,
  }

  public struct ActionRequest {
   name: String,
   pool_address: address,
   approvals: VecSet<TypeName>
  }

  // === Public-Mutative Functions ===

  public fun new_policy_builder(
   rules: VecMap<String, VecSet<TypeName>>, 
   packages: VecMap<String, vector<address>>
  ): PolicyBuilder {
   PolicyBuilder {
    rules,
    packages
   }
  }

  public fun share(self: Policy) {
   transfer::share_object(self);
  }

  public fun new_action_request(self: &Policy, name: String): ActionRequest {
   assert!(self.rules.contains(&name), errors::invalid_action_name());
   ActionRequest {
    name,
    pool_address: self.pool_address,
    approvals: vec_set::empty()
   }
  }

  // === Public-View Functions ===

  public fun pre_swap(): vector<u8> {
   PRE_SWAP
  }

  public fun post_swap(): vector<u8> {
   POST_SWAP
  }

  public fun pre_add_liquidity(): vector<u8> {
   PRE_ADD_LIQUIDITY
  }

  public fun post_add_liquidity(): vector<u8> {
   POST_ADD_LIQUIDITY
  }

  public fun pre_remove_liquidity(): vector<u8> {
   PRE_REMOVE_LIQUIDITY
  }

  public fun post_remove_liquidity(): vector<u8> {
   POST_REMOVE_LIQUIDITY
  }

  // === Admin Functions ===

  // === Public-Package Functions ===

  public(package) fun new_policy(
   pool_address: address,
   rules: VecMap<String, VecSet<TypeName>>, 
   packages: VecMap<String, vector<address>>,
   ctx: &mut TxContext   
  ): Policy {
   Policy {
    id: object::new(ctx),
    pool_address,
    rules,
    packages
   }
  } 

  public(package) fun destroy_policy_builder(
   policy_builder: PolicyBuilder
  ): (VecMap<String, VecSet<TypeName>>, VecMap<String, vector<address>>) {
   let PolicyBuilder { rules, packages } = policy_builder;
   (rules, packages)
  }

  // === Private Functions ===

  // === Test Functions ===

}