--[[::

Copyright (C) 2021, Luc Rodriguez (Aliases : Shambi, StyledDev).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--::]]

-- Initalize the permutation table.
local Permutations : {[number] : number} = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
	0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
	0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
	0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
	0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
	0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
	0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
	0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
	0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

-- Convert a number into a string of a fixed length.
local function ProcessNumber(Input : number, Length : number) : string
	
	-- Initalize a blank string to contain our output.
	local Output : string = "";
	
	-- Count up to the given length.
	for Index : number = 1, Length do
		
		-- Get the remainder of a modulus of 256.
		local Remainder : number = bit32.band(Input, 255);
		
		-- Convert the remainder to a character
		-- then add that character to the output.
		Output ..= string.char(Remainder);
		
		-- Set our input as : our input minus our 
		-- remainder divided by 256.
		Input = bit32.rshift(Input - Remainder, 8);
	end;
	
	-- Reverse the output then return it.
	return (string.reverse(Output));
end;

-- Convert a string into
-- a 232 bit number.
local function StringTo232BitNumber(Input : string, Offset : number) : number
	
	-- Initalize our output at 0.
	local Output : number = 0;
	
	-- Count from our offset, to our offset plus 3.
	for Index : number = Offset, Offset + 3 do
		
		-- Multiply our output by 256.
		Output *= 256;
		
		-- Convert the input into a byte, then
		-- add it to our output.
		Output += string.byte(Input, Index);
	end;
	
	-- Return our output.
	return (Output);
end;

-- Preprocess data so that it can be
-- processed further down the line.
local function PreProcess(Content : string, Length : number) : string
	
	-- Solve for the numerical padding used to offset the data.
	local Padding : number = 64 - bit32.band(Length + 9, 63);
	
	-- Compress the length the message to a fixed length of 8 bytes.
	Length = ProcessNumber(8 * Length, 8);
	
	-- Concat the content, divider, padding, and length.
	Content = Content .. "\128" .. string.rep("\0", Padding) .. Length;
	
	-- Check that the result has an exact length of 64 bytes.
	assert(#Content % 64 == 0, "Preprocessed content does not have a valid length of 64 bytes, and can not continue.");
	
	-- If everything checks out, return the result.
	return (Content);
end;

-- Digest a 64 bit block for a 256 bit hash.
local function Digestblock(Content : string, Offset : number, Hash : {[number] : number}) : nil?
	
	-- Initalize a blank array to contain
	-- each of the offsets used in the digest.
	local Offsets : {[number] : number} = {};
	
	-- Calculate the offsets 
	-- for the first byte.
	for Index : number = 1, 16 do 
		
		-- Convert the string into a 232 bit number
		-- with the result being set at the index.
		Offsets[Index] = StringTo232BitNumber(Content, Offset + (Index - 1) * 4); 
	end;
	
	-- Count from 17 up to 64.
	for Index : number = 17, 64 do
		-- Calculate the value of the current index.
		local Value : number = Offsets[Index - 15];
		
		-- Solve for the current section given the value.
		local Section0 : number = bit32.bxor(bit32.rrotate(Value, 7), bit32.rrotate(Value, 18), bit32.rshift(Value, 3));
		
		-- Offset the value.
		Value = Offsets[Index - 2];
		
		-- Overwrite the offset at the current
		-- index with some more calculations.
		Offsets[Index] = Offsets[Index - 16] + Section0 + Offsets[Index - 7] + bit32.bxor(bit32.rrotate(Value, 17), bit32.rrotate(Value, 19), bit32.rshift(Value, 10));
	end;
	
	-- Unpack the hash into 8 permutated sections.
	local a : number, b : number, c : number, d : number, e : number, f : number, g : number, h : number = 
		Hash[1], Hash[2], Hash[3], Hash[4], Hash[5], Hash[6], Hash[7], Hash[8];
	
	-- Count from 1 up to 64.
	-- updating the block for each index.
	for Index : number = 1, 64 do
		
		-- Solve for the first section and the "maj"
		local Section0 : number = bit32.bxor(bit32.rrotate(a, 2), bit32.rrotate(a, 13), bit32.rrotate(a, 22));
		local maj : number = bit32.bxor(bit32.band(a, b), bit32.band(a, c), bit32.band(b, c));
		
		-- Solve the tail's secondary component.
		local Tail2 : number = Section0 + maj;
		
		-- Solve the second section & the main chunk.
		local Section1 : number = bit32.bxor(bit32.rrotate(e, 6), bit32.rrotate(e, 11), bit32.rrotate(e, 25));
		local Chunk : number = bit32.bxor(bit32.band(e, f), bit32.band(bit32.bnot(e), g));
		
		-- With the other components, solve for the tail's main component.
		local Tail1 = h + Section1 + Chunk + Permutations[Index] + Offsets[Index];
		
		-- Overwrite each of the permutated sections
		-- with offset and modified equivilents.
		h, g, f, e, d, c, b, a = g, f, e, d + Tail1, c, b, a, Tail1 + Tail2;
	end;
	
	-- Iterate over each digested value.
	for Index : number, Value : number in ipairs({a, b, c, d, e, f, g, h}) do
		
		-- Overite the current value with the digested one.
		Hash[Index] = bit32.band(Hash[Index] + Value);
	end;
end

-- Made this global
return function(Content : string, Salt : string?) : string
	-- Check that the content provided is valid.
	assert(type(Content) == "string", "Argument #1 must be type\"string\".");
	
	-- Apply salt if one is provided.
	Content ..= if (type(Salt) == "string") then "_" .. Salt else "";
	
	-- Process the data for further changes.
	Content = PreProcess(Content, #Content);
	
	-- Initalize a base hash.
	local Base : {[number] : number} = {
		0x6a09e667,
		0xbb67ae85,
		0x3c6ef372,
		0xa54ff53a,
		0x510e527f,
		0x9b05688c,
		0x1f83d9ab,
		0x5be0cd19	
	};
	
	-- Iterate over the length of
	-- the data in chunks of 64.
	for Index : number = 1, #Content, 64 do
		
		-- Digest the content with the base.
		Digestblock(Content, Index, Base);
	end;
	
	-- Initalize a blank table to contain our hash.
	local Hash : {[number] : string?} = {};
	
	-- Iterate over each chunk in the "base hash".
	for Index : number, Value : number in ipairs(Hash) do
		
		-- Convert the chunk into a string, the overwrite the current value.
		Hash[Index] = ProcessNumber(Value, 4);
	end;
	
	-- Concat the results, then convert to a hexadecimal format.
	return (string.gsub(table.concat(Hash), ".", function(Character : string) : string
		
		-- Convert the character into a byte, then format as a hexadecimal pair.
		return (string.format("%02x", string.byte(Character)));
	end));
end;
