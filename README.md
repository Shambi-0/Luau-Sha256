# Luau Sha256

A Open-Source Module which allows you to efficiently create sha256 hashes with ease.

Sha256 is a commonly used "one-way hash function", notably used in varies cryptocurrency, crypto-systems, as well as account/password verification.

## Installation

In ROBLOX Studio, you may load it in as a module script named `Sha256`, with the following :

```lua
local Sha256 = require(script.Sha256);
```
Or, if you are using the Luau Binary Files, you can load it by swapping the file directory :
```lua
local Sha256 = require("./Sha256");
```
## Usage

Creating a new hash :
```lua
local Message : string = "The message you want to hash would go here";
local Hash : string = Sha256(Message); -- Create our hash.

print(Hash); -- 81ed73c0221e8d76eda67a383e89d2186d46fef5ec6c0b68f51ca7d33a9193d7
```
Want to increase your security a bit more? try adding a **"salt"** :
```lua
local Message : string = "The message you want to hash would go here";
local Salt : string = "Your Super Secret Salt would go here";

local Hash : string = Sha256(Message, Salt); -- Create our salted hash.

print(Hash); -- cb73cee5064dd1c344c661c5a739fde92a5a4a7ed27d45d05aa5edef2250481e
```
adding a **salt** makes reverse engineering hashes far more difficult, since it changes the original input
so even if you had a database of hashes and inputs to compare to, it wouldn't match up since the inputs don't include the salt.
## License
[MIT](https://choosealicense.com/licenses/mit/)
