## Project Overview
This projects shows a proof of concept (POC) of a blockchain rental contract. The project consinsts of a serie of NFTs which represents the asset to rent. 

## Installation

1. Clone the repository in your machine: You can use the git console and simply write the command `git clone https://github.com/franvf/rentalAsset.git.` Alternatively, you can download and extract the project zip file on your machine.

2. Install all the dependencies: In order to make our project work, we need to install all the packages and libraries our project is 
using. To do this, we can simply open the terminal, go to the directory project and write the command `npm i`. Now all the required packages 
will be installed. 

**Note**: Probably you will have to modity the version of DateTime.sol contract. This contract is using an older version of solidity but in our project we are using a new one. In order to fix this, you must go to node_modules/ethereum-datetime/contracts/DateTime.sol and modify the current version to ^0.8.18 version. This will provoke an error at line 61 where you will have to select the storage of the returned variable (storage, calldata or memory)

3. Install Ganache and Truffle: If you don't have this software installed yet, it is time to install it. You can download the Ganache GUI installer from [here](https://trufflesuite.com/ganache/). And to install Truffle, you can follow [this](https://trufflesuite.com/docs/truffle/how-to/install/) guide.

4. Test the project: In order to check if the environment is ready, we can start the ganache GUI and then open the terminal and go to the project directory. Then we must execute the command `truffle migrate` to deploy the smart contracts of both collections in our local blockchain. When deployment finishes, we can return to our terminal and execute the test file. This can be done by executing the `truffle test` command in the project directory. Now the JS file in the *test* directory will be executed, and if all is correct, the test will pass.

## Use case
The contract owner (Who possesses the assets, like apartments, for example) mints an NFT for each asset. Then a user who wants to rent the asset calls the function rentAsset and pays the entry fee to the owner. Each month the tenant must pay the monthly price. If the monthly price is unpaid, the owner can add a charge for this month (to mark this month as unpaid). To pay this unpaid month, the tenant must call the function payCharge and select the month to pay. If the tenant accumulates five or more unpaid months, the owner will be able to remove the tenant's rights to the asset. In this case, we suppose that the owner's assets are apartments, so this smart contract requires a traditional legal contract to make the tenant and owner rights and obligations effective.

Note: This smart contract is not exclusive to renting apartments or similar assets. We could use it for other purposes like car renting or make some adjustments to use it for subscriptions like a Gym subscription. The possibilities of this smart contract are endless.
