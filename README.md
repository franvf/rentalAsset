## Project Overview
This projects shows a proof of concept (POC) of a blockchain rental contract. The project consinsts of a serie of NFTs which represents the asset to rent. 

## Installation

1. Clone the repository in your machine: You can use the git console and simply write the command `git clone https://github.com/franvf/rentalAsset.git.` Alternatively, you can download and extract the project zip file on your machine.

2. Install all the dependencies: In order to make our project work, we need to install all the packages and libraries our project is 
using. To do this, we can simply open the terminal, go to the directory project and write the command `npm i`. Now all the required packages 
will be installed. 

3. Install Ganache and Truffle: If you don't have this software installed yet, it is time to install it. You can download the Ganache GUI installer from [here](https://trufflesuite.com/ganache/). And to install Truffle, you can follow [this](https://trufflesuite.com/docs/truffle/how-to/install/) guide.

4. Test the project: In order to check if the environment is ready, we can start the ganache GUI and then open the terminal and go to the project directory. Then we must execute the command `truffle migrate` to deploy the smart contracts of both collections in our local blockchain. When deployment finishes, we can return to our terminal and execute the test file. This can be done by executing the `truffle test` command in the project directory. Now the JS file in the *test* directory will be executed, and if all is correct, the test will pass.

## Use case
The contract owner (Who possess the asserts, like appartments, for example) mints an NFT for each asset. Then a user who wants to rent the asset call the function rentAsset and pay the entry fee to the owner. Each month the tenant must to pay the monthly price, if don't the owner can add a charge for this month (To mark this month as unpaid). To pay the unpaid month the tenant must to call the function payCharge and select the month to pay. In case the tenant accumulates five or more unpaid months, the owner will be able to remove the rights of the tenant to the asset. 
In this case we are supposing that the assets of the owner are appartments, so this smart contract requires a traditional legal contract to make effective the tenant and owner rights and obligations. 

Note: Notice that this kind of smart contract is not exclusive for appartments or similar assets, we could use it for other purposes like car renting or do som adjustments to use it for subscriptions like a Gym subscription. The possibilities of this smart contract are endless.