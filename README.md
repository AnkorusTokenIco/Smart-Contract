# Smart-Contract
Ankorus Initial Coin Offering Smart Contract

This is a basic contract which handles ICO contributions in two stages.

The first phase of the transaction is a contribution to the Ankorus contract itself, which after receiving a contribution, determines the
ethereum to ANK token conversion rate and then disburses the tokens back to the contributor.

The second phase is the Ankorus contract immediatlely deposits the contibution to a secure multi siginature wallet.

Code source for the multi sig wallet comes from https://github.com/Gnosis/MultiSigWallet and is used in several high profile high value ICOs including
Aragon, Bancor, Brace, District0x, Cobinhood and several more.