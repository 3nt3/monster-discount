# monster discount

Notifies you about monster being discounted

## API routes found

Example market code: `1940156`

| route                                                                   | what does it do                                                                                                                                  |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `https://mobile-api.rewe.de/mobile/markets/markets/<marketCode>`        | Get basic info: name, location, opening hours etc.                                                                                               |
| `https://mobile-api.rewe.de/mobile/markets/market-search?query=<query>` | Search by text query                                                                                                                             |
| `https://mobile-api.rewe.de/api/v3/all-offers?marketCode=<marketCode>`  | Get all offers                                                                                                                                   |
| `https://mobile-api.rewe.de/api/v3/productrecalls`                      | Get all product recalls (or just nothing sometimes?)                                                                                             |
| `https://mobile-api.rewe.de/mobile/products/<listingID>`                | Get a single product. No idea where the listingID comes from but this one seems to work: `13-5060337500401-f2bf8a20-3ff3-4fbc-9cea-984edf862b0f` |
