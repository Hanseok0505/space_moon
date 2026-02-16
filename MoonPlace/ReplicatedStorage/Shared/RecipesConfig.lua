local Recipes = {
  ["BasicEngine"] = {
    cost = { IronOre=10, FuelCell=1 },
    gives = { EngineCore=1 },
    cashCost = 100,
  },
  ["BasicHull"] = {
    cost = { IronOre=20, HullPlate=5 },
    gives = { HullPlate=10 },
    cashCost = 80,
  },
}
return Recipes
