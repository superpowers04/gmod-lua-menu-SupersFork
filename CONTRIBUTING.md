Contributing to Lua Main Menu
=============

Here's what you need to know if you wish to submit Pull Requests to THIS repository, NOT THE [MAIN ONE](https://github.com/robotboy655/gmod-lua-menu).
Note, a lot of code currently doesn't follow the current code styling rules and I DO plan on fixing that.

Code Formatting
=============

Your code formatting should be consistent with the rest of the code:
* Use tabs to indent your code instead of spaces. Tab size is per user which provides per tab sizing without affecting other users
* Try to keep to vanilla lua syntax whenever possible(i.e, don't use the C-style aliases like `!` or `&&`)
	* Using the C-style aliases makes code needlessly incompatible with text editors using normal lua syntax highlighting
	* This doesn't apply to stuff like continue, continue actually adds new functionality
* Use UpperCamelCase for method names
* Use lowerCamelCase for field names
* Use lower_snake_case for local variables
* Use lua-style ternaries instead of if-statements whenever possible without majorly affecting code performance(`bool and value1 or value2`), this prevents duplicate code. 
* As a rule of thumb, if a function is run several times for the same result(i.e, `CurTime()`), please store it in a local variable
* Do not include field type in field names if possible

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

if !(type(myTable) == "table") then error "bad" end

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