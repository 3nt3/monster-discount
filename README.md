# monster discount

Find products that are discounted at REWE from the command line

## Example usage

```sh
$ python3 scraper.py möhre
Bundmöhren is discounted to 1.29 (Aktion)
```

## API routes found

Example market code: `1940156`

| route                                                                  | what does it do                                      |
| ---------------------------------------------------------------------- | ---------------------------------------------------- |
| `https://mobile-api.rewe.de/mobile/markets/markets/<marketCode>`       | Get basic info: name, location, opening hours etc.   |
| `https://mobile-api.rewe.de/api/v3/all-offers?marketCode=<marketCode>` | Get all offers                                       |
| `https://mobile-api.rewe.de/api/v3/productrecalls`                     | Get all product recalls (or just nothing sometimes?) |
