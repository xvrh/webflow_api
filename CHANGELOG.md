## 0.3.0

- `webhooks`, `createWebhook` and `removeWebhook` manage the site's webhooks;
  with a site token, `createWebhook` answers the webhook's `secretKey`
- `isWebflowSignature` checks a webhook request's signature and age

## 0.2.0

- `items(live: true)` lists a collection's published items
- `allItems` reads every page, and throws when they do not add up to the total
- A response that is not a success throws a `WebflowException` with its status
  and Webflow's message
- `Webflow` takes an optional `http.Client`

## 0.1.1

- Add dartdoc comments to document the public APIs
- Update the package description to fit the recommended length

## 0.1.0

- Initial version.
