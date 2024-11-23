import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test issuer management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const issuer = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'add-issuer', [
        types.principal(issuer.address)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Test credit issuance and transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const issuer = accounts.get('wallet_1')!;
    const buyer = accounts.get('wallet_2')!;
    
    // Add issuer
    let setupBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'add-issuer', [
        types.principal(issuer.address)
      ], deployer.address)
    ]);
    
    // Issue credits
    let issueBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'issue-credits', [
        types.uint(1000),
        types.ascii("Solar Project")
      ], issuer.address)
    ]);
    
    issueBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Transfer credits
    let transferBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'transfer-credits', [
        types.uint(500),
        types.principal(issuer.address),
        types.principal(buyer.address)
      ], issuer.address)
    ]);
    
    transferBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Check balances
    let balanceBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'get-credit-balance', [
        types.principal(buyer.address)
      ], deployer.address)
    ]);
    
    assertEquals(balanceBlock.receipts[0].result.expectOk(), types.uint(500));
  },
});

Clarinet.test({
  name: "Test credit retirement",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const issuer = accounts.get('wallet_1')!;
    
    // Setup
    let setupBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'add-issuer', [
        types.principal(issuer.address)
      ], deployer.address),
      Tx.contractCall('carbon-credits', 'issue-credits', [
        types.uint(1000),
        types.ascii("Wind Project")
      ], issuer.address)
    ]);
    
    // Retire credits
    let retireBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'retire-credits', [
        types.uint(300)
      ], issuer.address)
    ]);
    
    retireBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Check total retired
    let retiredBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'get-total-credits-retired', [], deployer.address)
    ]);
    
    assertEquals(retiredBlock.receipts[0].result.expectOk(), types.uint(300));
  },
});
