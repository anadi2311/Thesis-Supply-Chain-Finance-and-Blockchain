# Thesis-Supply-Chain-Finance-and-Blockchain
The world experienced unprecedented growth in international trade in the past few decades. In this resulting environment of global competition, several new companies have spawned and are spawning. Sellers are often under immense pressure by the market players to accept open-account trade terms, shipping goods before receiving payment, leaving them exposed to increased risk. This creates working capital challenges for firms, especially small and medium enterprises. To mitigate this supply chain risk, several supplier-led and buyer-led supply chain finance solutions are facilitated by banks and financial technology companies. However, because of the new Basel III regulation framework for banks and several other Supply Chain Finance (SCF) adoption barriers, like fraudulent activities, many firms are unable to reap SCF’s full benefits. This study explains various SCF instruments, the key drivers in their growth and their adoption barriers.
This study then focuses on the novel blockchain technology and smart contracts by delving deep into their history, components, limitations, risks and use cases. Using the knowledge gathered in the process, a proof-of-concept blockchain and smart contract is developed using the Ethereum platform, which can facilitate normal business, purchase order finance, reverse factoring and reverse securitization. To test the smart contract, four use cases for each SCF instrument mentioned are demonstrated. A JavaScript-based unit test is done to test the smart contract’s correct deployment and onboarding of actors along with their business and financing interactions – access controls to business documents, reverting malicious transactions and correct fund transfer. As a result of various assumptions taken in the development process, the smart contract works only as a basic proof-of-concept and lacks robustness on the ground of scalability and security. As a result, a future model is laid out which will use various software and hardware oracles for autonomous operations while using a complex system of a storage contract, a permanent contract which stores all the data, and logic contract, upgradable contract which can be changed any number of times, with a proxy contract making delegated “function” calls to logic contract to reduce the
gas usage due to external function calls.


## To execute:
1) install truffle
2) install node.js
3) install ethereum
4) execute truffle migrate


# Proposed Future Model:
![image](https://user-images.githubusercontent.com/47948789/110713072-22a1eb80-81b6-11eb-9e15-ad7a977f496c.png)

