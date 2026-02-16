local Ships = {
  Tiers = {
    { id="Scout-I", price=500, need = { EngineCore=1, HullPlate=5 }, speed=30, cargo=20 },
    { id="Explorer-II", price=1500, need = { EngineCore=2, HullPlate=15, FuelCell=3 }, speed=50, cargo=40 },
    { id="Voyager-III", price=5000, need = { EngineCore=4, HullPlate=30, FuelCell=10 }, speed=80, cargo=80 },
    { id="Lunar-Module", price=15000, need = { EngineCore=6, HullPlate=60, FuelCell=20 }, speed=60, cargo=120, canGoMoon=true },
  }
}
return Ships
