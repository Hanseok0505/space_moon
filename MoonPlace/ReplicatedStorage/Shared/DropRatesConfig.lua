local Drops = {
  IronNode = {
    {item="IronOre", chance=0.85, amount={min=1,max=2}},
    {item="TitaniumOre", chance=0.10, amount={min=1,max=1}},
    {item="FuelCell", chance=0.05, amount={min=1,max=1}},
  },
  TitaniumNode = {
    {item="TitaniumOre", chance=0.75, amount={min=1,max=2}},
    {item="IronOre", chance=0.20, amount={min=1,max=2}},
    {item="EngineCore", chance=0.05, amount={min=1,max=1}},
  },
  LunarNode = {
    {item="LunarSample", chance=0.60, amount={min=1,max=1}},
    {item="TitaniumOre", chance=0.25, amount={min=1,max=2}},
    {item="FuelCell", chance=0.15, amount={min=1,max=1}},
  }
}
return Drops
