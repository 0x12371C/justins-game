return {
	activeSkyName = "_ActiveSky",
	dayLengthMinutes = 18,
	updateIntervalSeconds = 2,
	templateRescanSeconds = 15,
	weatherMinSeconds = 90,
	weatherMaxSeconds = 210,
	phaseStarts = {
		dawn = 5,
		day = 8,
		dusk = 18,
		night = 20,
	},
	weatherWeights = {
		clear = 5,
		cloudy = 3,
		rain = 2,
		storm = 1,
	},
	phaseAliases = {
		dawn = { "dawn", "sunrise", "morning" },
		day = { "day", "noon", "sunny" },
		dusk = { "dusk", "sunset", "evening" },
		night = { "night", "moon", "midnight", "starry", "stars" },
	},
	weatherAliases = {
		clear = { "clear", "sunny" },
		cloudy = { "cloud", "overcast" },
		rain = { "rain", "shower", "wet" },
		storm = { "storm", "thunder", "lightning" },
	},
}
