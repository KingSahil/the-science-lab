#class_name ChemistryDB
#extends Node
#
## This dictionary stores your "Recipes"
## FORMAT: "ChemicalA + ChemicalB" : "Result Text"
## IMPORTANT: Keep the keys alphabetically sorted! (e.g., "HCl+NaOH", not "NaOH+HCl")
#static var reactions = {
	## Acids + Bases (Neutralization)
	#"HCl+NaOH": "NaCl + H2O (Salt Water)",
	#"HCl+KOH": "KCl + H2O (Potassium Chloride)",
	#"H2SO4+NaOH": "Na2SO4 + H2O (Sodium Sulfate)",
	#"HNO3+KOH": "KNO3 + H2O (Potassium Nitrate)",
#
	## Acids + Carbonates (Fizzing!)
	#"HCl+Na2CO3": "NaCl + H2O + CO2 (Fizzing!)",
	#"Vinegar+BakingSoda": "Sodium Acetate + H2O + CO2 (Volcano!)",
	#"H2SO4+CaCO3": "CaSO4 + H2O + CO2 (Gas Bubbles)",
#
	## Precipitation (Color Changes)
	#"AgNO3+NaCl": "AgCl (White Precipitate) + NaNO3",
	#"Pb(NO3)2+KI": "PbI2 (Yellow Precipitate) + KNO3",
	#"CuSO4+NaOH": "Cu(OH)2 (Blue Precipitate) + Na2SO4",
	#
	## Combustion / Fire
	#"H2+O2": "H2O (Explosion!)",
	#"CH4+O2": "CO2 + H2O (Blue Flame)",
	#
	## Simple Synthesis
	#"Fe+S": "FeS (Iron Sulfide - Black Solid)",
	#"Na+Cl2": "NaCl (Table Salt - Bright Flash!)"
#}
#
#static func get_reaction(chem_a: String, chem_b: String) -> String:
	## 1. Sort names alphabetically so "HCl + NaOH" is the same as "NaOH + HCl"
	#var ingredients = [chem_a, chem_b]
	#ingredients.sort()
	#var key = ingredients[0] + "+" + ingredients[1]
	#
	## 2. Check if we have a recipe for this
	#if key in reactions:
		#return reactions[key]
	#
	## 3. Default if no reaction is found
	#return "Mixed Solution"
