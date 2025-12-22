Contributing to Lua Main Menu
=============

Here's what you need to know if you wish to submit Pull Requests to THIS repository, NOT THE [MAIN ONE](https://github.com/robotboy655/gmod-lua-menu).

Code Formatting
=============

Your code formatting must be consistent with the rest of the code:
* Use tabulation to indent your code - TAB size = 4 spaces
* Use all of the C style Lua in Garry's Mod
* Use UpperCamelCase for function names
* Use lowerCamelCase for variable names
* Do not include variable type in variable names

Examples
=============

These examples are of CODE FORMATTING, not examples of GOOD CODE.

Good:
```
local myTable = {
	meem = "no",
	test = true,
	foo = 1,
	bar = "yes"
}

if type(myTable) ~= "table" then error("bad") end

function Test(myVariable1, myVariable2)
	if not myVariable2 then return "hax" end

	if myTable[myVariable1] then
		return myTable[myVariable1]
	end
	if (myVariable1 == myVariable2 or not myVariable1) then
		return "hax pt2"
	end

	return myVariable2
end

print(Test('a',true), Test('a','a'), Test(nil,false), meem.test and "blue" or "red")
```

Bad:
```
local myTable =
{
 meem =			"no",
  test =true,
   foo= 1,
    bar				= "yes"
}

if not (type(myTable) == "table") then error "bad" end

function Test( myVariable1, myVariable2 )
 if myVariable2 == false then 
 return 
 "hax" end

 if (myTable[myVariable1] )then
  return myTable[myVariable1]
		end
	  if myVariable1 == myVariable2 or (not myVariable1) then
  return 
  "hax pt2"
    end
 return myVariable2
end
if(meem.test) then
        print(Test('a',true), Test('a','a'), Test(nil,false), "blue")
else			print(Test('a',true), Test('a','a'), Test(nil,false), "red")       end
```