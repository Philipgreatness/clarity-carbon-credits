import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test validation system",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const issuer = accounts.get('wallet_1')!;
    const validator1 = accounts.get('wallet_2')!;
    const validator2 = accounts.get('wallet_3')!;
    const validator3 = accounts.get('wallet_4')!;
    
    // Setup issuer and validators
    let setupBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'add-issuer', [
        types.principal(issuer.address)
      ], deployer.address),
      Tx.contractCall('carbon-credits', 'add-validator', [
        types.principal(validator1.address)
      ], deployer.address),
      Tx.contractCall('carbon-credits', 'add-validator', [
        types.principal(validator2.address)
      ], deployer.address),
      Tx.contractCall('carbon-credits', 'add-validator', [
        types.principal(validator3.address)
      ], deployer.address)
    ]);
    
    setupBlock.receipts.forEach(receipt => {
      receipt.result.expectOk().expectBool(true);
    });

    // Issue credits
    let issueBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'issue-credits', [
        types.uint(1000),
        types.ascii("Solar Project"),
        types.uint(2000)
      ], issuer.address)
    ]);
    
    issueBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Validate credits
    let validateBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'validate-credits', [
        types.principal(issuer.address)
      ], validator1.address),
      Tx.contractCall('carbon-credits', 'validate-credits', [
        types.principal(issuer.address)
      ], validator2.address),
      Tx.contractCall('carbon-credits', 'validate-credits', [
        types.principal(issuer.address)
      ], validator3.address)
    ]);
    
    validateBlock.receipts.forEach(receipt => {
      receipt.result.expectOk().expectBool(true);
    });

    // Check issuer data after validation
    let dataBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'get-issuer-data', [
        types.principal(issuer.address)
      ], deployer.address)
    ]);
    
    let issuerData = dataBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(issuerData['validations'], types.uint(3));
    assertEquals(issuerData['price'], types.uint(2000));
  },
});

Clarinet.test({
  name: "Test dynamic pricing",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const issuer = accounts.get('wallet_1')!;
    
    // Add issuer
    let setupBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'add-issuer', [
        types.principal(issuer.address)
      ], deployer.address)
    ]);
    
    // Issue credits with initial price
    let issueBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'issue-credits', [
        types.uint(1000),
        types.ascii("Wind Project"),
        types.uint(1500)
      ], issuer.address)
    ]);
    
    // Update price
    let priceBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'set-credit-price', [
        types.uint(2000)
      ], issuer.address)
    ]);
    
    priceBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Check new price
    let getPriceBlock = chain.mineBlock([
      Tx.contractCall('carbon-credits', 'get-credit-price', [
        types.principal(issuer.address)
      ], deployer.address)
    ]);
    
    assertEquals(getPriceBlock.receipts[0].result.expectOk(), types.uint(2000));
  },
});
