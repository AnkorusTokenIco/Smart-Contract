# Smart-Contract
Ankorus Initial Coin Offering Smart Contract

This is a basic contract which handles ICO contributions in two stages.

The first phase of the transaction is a contribution to the Ankorus contract itself, which after receiving a contribution, determines the
ethereum to ANK token conversion rate and then disburses the tokens back to the contributor's ethereum wallet.

The second phase is the Ankorus contract immediatlely deposits the contibution to a secure multi siginature wallet.

Owner functions overview:

addWhitelist - This function allows an address to reserve tokens before the ICO date. Note that this does not allow for a pre ico purchase price, it merely allows
the purchasing of tokens at the introductory rate before the start date.

setLockout - This function adds an address and a time to the lockout list, where the specified address may not transfer tokens out of their wallet before this time
period has expired.

finalize - This function is called once the sale period has expired, and distributes unsold tokens back to Ankorus.

push - This function is used to push tokens held by the ankorus company wallet. Note that this function does not affect the token sale token pool, 
and distributes tokens only from the company wallet.

Code source for the multi sig wallet comes from https://github.com/Gnosis/MultiSigWallet and is used in several high profile high value ICOs including
Aragon, Bancor, Brace, District0x, Cobinhood and several more.

Multisig Wallet Etherum address: 0xf1C0C02355EF9cA31371C5660a36C1e83333e4e1 (Currently on RINKEBY (CLIQUE) Testnet)