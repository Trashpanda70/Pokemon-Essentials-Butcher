=begin
Butcher script by Trashpanda70

Implements a butcher functionality to game. The amount of money for each 
Pokemon given will depend on the type provided (customizable). If a dual type 
Pokemon is given then the type of lowest ranking (less money) is used. Edit the
variables below for how you want the butcher in the game.

The script was written using gen 5 types (no Fairy). If you have a Fairy type or 
other custom type then just be sure to add it to one of the "level" arrays below.

USE:
To use the script, make an event with an NPC you want to be the butcher and create a 
Conditional Branch using a script. In the script call put "pbButcher()". Inside the
conditional you need to add 3 things in the following order:

1. A "change gold" operation set to "Increase" with the operand option as "Variable"
and use the variable you define below (29 by default)

2. A "Play ME" operation set to play "Pkmn get" (or whatever sound you want to play to
let the player know the transaction went through)

3. Text that says the player has recieved the money. In the most basic form this will be
something along the lines of: "\PN received $\v[var]" (where var is the number you define 
below for the given money to be stored in)
=end

#Pokemon you cannot sell to the butcher are in array below
#Enter Pokemon as entries with a colon followed by their name in all caps. 
#Use a comma to separate entries. They do not need to be on a newline.
Except=[
:DITTO,
:MEWTWO,
:ARCEUS
]

=begin
Below are the arrays of types used to see how much money the player will get.
There are 4 levels (levels 0-3) with 0 being the lowest (no money recieved) and 
3 being the most money recieved. Dual types do not add more money but simply use
the type with the lowest ranking. Add the type in all caps with a colon in front
(such as :ROCK) as an entry in the array similar to the except array above.

I have put the ranking I personally use as a starting point, but feel free to
customize. If a type is listed twice then the lowest ranking will be used, if a
type is not listed the butcher will not give money for it.
=end
Level0=[:ROCK, :STEEL, :POISON, :GHOST] # level 0 array
Level1=[:ELECTRIC, :GROUND, :PSYCHIC, :ICE, :DARK] # level 1 array
Level2=[:NORMAL, :DRAGON, :BUG, :FIGHTING, :FAIRY] # level 2 array
Level3=[:FIRE, :WATER, :GRASS, :FLYING] # level 3 array

# Below is the variable to store the amount of money the butcher will give.
# For me it is variable 29, but change it to whatever your game needs.
Var=29

# Most amount of types a Pokemon can have, 2 by default. Used to search for what
# "level" a specific Pokemon ranks in.
Types=2

# Currently only money calculation by height is supported since I am a little unsure
# about how to get the weight. I will update with wegiht functionality if/when I figure it out
# Method=h

# Below are numbers to indicate the price per centimeter a Pokemon of a particular level is worth.
# This value is to be multiplied by the height (in cm) for the final cost
# price per centimeter for a level 1 Pokemon
Lv1Price=2
# price per centimeter for a level 2 Pokemon
Lv2Price=3
# price per centimeter for a level 3 Pokemon
Lv3Price=4

# The maximum amount of money the butcher can give. Some Pokemon have large height values that might
# yeild a higher than wanted payout. This value is meant to prevent that. If it is 0 or negative then
# there will be no limit
Limit=2000

# Start of method, end of customizing
def pbButcher()
  pbMessage(_INTL("Hey trainer! Looking to sell a Pokémon for some quick money?"))
  pbMessage(_INTL("What Pokémon do you have for me?"))
  # Statement below is from the WonderTrade script by Black Eternity
  chosen=pbChoosePokemon(1,2,
                         proc {|poke| !poke.egg? && !(poke.isShadow?) && !(Except.include?(poke.species))
                         }) #Choose a Pokemon that is not an Egg, Shadow Pokemon, or on the exception list
  if pbGet(1)>=0
    if $Trainer.able_pokemon_count > 1 #True if Trainer has more than 1 usable Pokemon
      len1 = Level0.length > Level1.length ? Level0.length : Level1.length
      len2 = Level2.length > Level3.length ? Level2.length : Level3.length
      len = len1 > len2 ? len1 : len2 # get array with largest length
      num = -1
      for k in 0..len # iterate through entries
        # check for each type in each array if Pokemon is of that type
        zero = pbGetPokemon(1).hasType?(Level0[k]) if k < Level0.length
        one = pbGetPokemon(1).hasType?(Level1[k]) if k < Level1.length
        two = pbGetPokemon(1).hasType?(Level2[k]) if k < Level2.length
        three = pbGetPokemon(1).hasType?(Level3[k]) if k < Level3.length
        found = 0
        # assign value based on what array type was found in
        if three
            num = 3 if num < 0
            found += 1
        end
        if two
            num = 2 if num != 1
            found += 1
        end
        if one
            num = 1
            found += 1
        end
        if zero
            num = 0
            break
        end
        # break if found types is number of max types
        break if found > Types
      end
      if num == -1 # Pokemon's type not found
        pbMessage(_INTL("I'm not entirely sure what to do with this"))
        return false
      end
      money = 0
      # assign money variable and print message depending on value
      if num == 1
        pbMessage(_INTL("This will do I guess, here is your money."))
        money += Lv1Price
      elsif num == 2
        pbMessage(_INTL("This will do nicely.\nHere's your pay and please come again."))
        money += Lv2Price
      elsif num == 3
        pbMessage(_INTL("Very nice! I can get a lot of money from this.\nPlease do come again!"))
        money += Lv3Price
      else # if num is 0 can't sell
        pbMessage(_INTL("We can't sell meat from that type of Pokémon."))
        return false
      end
      money *= pbSize(pbGetPokemon(1)) / 10 #Multiply by size in cm
      if money > Limit && Limit > 0
        money = Limit
        pbMessage(_INTL("That's the most money I can give an unofficial provider such as yourself."))
      end
      pbSet(Var,money) # set chosen variable to added money
      $Trainer.party.delete_at(pbGet(1)) # remove pokemon from party
      return true
    else #If the trainer has only 1 usable Pokemon
      pbMessage(_INTL("You know, it's against company policy to take a trainer's last Pokémon."))
      return false
    end
  else
    return false
  end
end  
