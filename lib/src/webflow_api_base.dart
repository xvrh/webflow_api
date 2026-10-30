import 'dart:convert';

import 'package:http/http.dart' as http;

import 'webflow_api_models.dart';
export 'webflow_api_models.dart';

/// The class that communicates with the Webflow API.
/// Expects at least two parameters: token and siteId.
/// These parameters are obrained from the Webflow web dashboard.
class Webflow {
  String endpoint;
  String token;
  String version;
  String siteId;
  Map<String, String>? headers;
  final http.Client client;

  Webflow({
    required this.token,
    required this.siteId,
    this.version = "1.0.0",
    this.endpoint = "api.webflow.com",
    http.Client? client,
  }) : client = client ?? http.Client() {
    headers = {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
      "accept-version": version,
      "Content-Type": "application/json",
    };
  }

  // Collections

  /// Retreives all the site's CMS collections
  Future<List<Collection>> collections() async {
    var url = Uri.https(endpoint, "v2/sites/$siteId/collections");

    var response = _check(await client.get(url, headers: headers));

    var json = jsonDecode(response.body) as Map<String, dynamic>;
    List<Collection> collections =
        (json['collections'] as List).map((e) => Collection.fromJson(e)).toList();
    return collections;
  }

  /// Retrieves a single CMS collection details, by collection ID
  Future<Collection> collection(String collectionId) async {
    var url = Uri.https(endpoint, "v2/collections/$collectionId");
    var response = _check(await client.get(url, headers: headers));
    dynamic json = jsonDecode(response.body);
    Collection collection = Collection.fromJson(json);
    return collection;
  }

  // Items

  /// Retrieves a page of the items in a collection, by collection ID.
  /// [live] lists the published items instead of the staged ones, which
  /// include drafts and unpublished changes.
  Future<ItemsResponse> items(String collectionId,
      {int offset = 0, int limit = 100, bool live = false}) async {
    var url = Uri.https(
        endpoint,
        "v2/collections/$collectionId/items${live ? "/live" : ""}",
        {"offset": offset.toString(), "limit": limit.toString()});

    var response = _check(await client.get(url, headers: headers));

    dynamic json = jsonDecode(response.body);
    ItemsResponse itemsResponse = ItemsResponse.fromJson(json);
    return itemsResponse;
  }

  /// Retrieves every item in a collection, one page after the other.
  ///
  /// Throws a [WebflowException] when the pages do not add up to the total
  /// Webflow reports, as when an item is published while the pages are read:
  /// a short listing is never returned as a complete one.
  Future<List<Item>> allItems(String collectionId, {bool live = false}) async {
    const limit = 100;
    var items = <Item>[];
    while (true) {
      var page = await this
          .items(collectionId, offset: items.length, limit: limit, live: live);
      items.addAll(page.items);
      var total = page.pagination.total;
      if (page.items.isEmpty || items.length >= total) {
        if (items.length != total) {
          throw WebflowException(
              "Collection $collectionId listed ${items.length} items "
              "of the $total it reports");
        }
        return items;
      }
    }
  }

  /// Retrieves a CMS Item, by collection ID and Item ID
  Future<ItemsResponse> item({
    required String collectionId,
    required String itemId,
  }) async {
    Uri url = Uri.https(endpoint, "v2/collections/$collectionId/items/$itemId");

    http.Response response = _check(await client.get(url, headers: headers));

    return ItemsResponse.fromJson(jsonDecode(response.body));
  }

  /// Creates a new CMS in a collection
  Future<Item> createItem({
    required String collectionId,
    Map<String, dynamic> fields = const {},
    bool live = false,
    bool archived = false,
    bool draft = true,
  }) async {
    var url = Uri.https(endpoint, "v2/collections/$collectionId/items", {
      "live": live.toString(),
    });

    http.Response response = _check(await client.post(url,
        headers: headers,
        body: jsonEncode(
          {
            "fields": {
              "_archived": archived,
              "_draft": draft,
              ...fields,
            }
          },
        )));

    return Item.fromJson(jsonDecode(response.body));
  }

  /// Removes (deletes) a CMS collection item, by item ID
  Future<int> removeItem({
    required String collectionId,
    required String itemId,
    bool live = false,
  }) async {
    Uri url = Uri.https(endpoint, "v2/collections/$collectionId/items/$itemId", {
      "live": live.toString(),
    });

    http.Response response =
        _check(await client.delete(url, headers: headers));

    dynamic json = jsonDecode(response.body);
    int deletedCount = json['deleted'];
    return deletedCount;
  }

  /// Updates the fields of a CMS collection item
  Future<Item> updateItem({
    required String collectionId,
    required String itemId,
    Map<String, dynamic> fields = const {},
    bool live = false,
  }) async {
    Uri url = Uri.https(endpoint, "v2/collections/$collectionId/items/$itemId", {
      "live": live.toString(),
    });

    http.Response response = _check(await client.patch(url,
        headers: headers, body: jsonEncode({"fields": fields})));

    return Item.fromJson(jsonDecode(response.body));
  }

  // Webhooks

  /// Retrieves every webhook registered on the site, whoever registered it.
  ///
  /// Throws a [WebflowException] when the listing is shorter than the total
  /// Webflow reports.
  Future<List<Webhook>> webhooks() async {
    var url = Uri.https(endpoint, "v2/sites/$siteId/webhooks");
    var response = _check(await client.get(url, headers: headers));

    var json = jsonDecode(response.body) as Map<String, dynamic>;
    var webhooks = ((json["webhooks"] ?? []) as List)
        .map((e) => Webhook.fromJson(e))
        .toList();
    var total = (json["pagination"] as Map<String, dynamic>?)?["total"];
    if (total is int && webhooks.length < total) {
      throw WebflowException(
          "Site $siteId listed ${webhooks.length} webhooks "
          "of the $total it reports");
    }
    return webhooks;
  }

  /// Registers a webhook: Webflow posts each [triggerType] event to [url].
  ///
  /// With a site token, the answer carries the webhook's
  /// [Webhook.secretKey], which signs its requests, and no other answer
  /// does.
  Future<Webhook> createWebhook({
    required String triggerType,
    required Uri url,
  }) async {
    var request = Uri.https(endpoint, "v2/sites/$siteId/webhooks");
    var response = _check(await client.post(request,
        headers: headers,
        body: jsonEncode({"triggerType": triggerType, "url": url.toString()})));

    return Webhook.fromJson(jsonDecode(response.body));
  }

  /// Removes a webhook, by webhook ID
  Future<void> removeWebhook(String webhookId) async {
    var url = Uri.https(endpoint, "v2/webhooks/$webhookId");
    _check(await client.delete(url, headers: headers));
  }

  /// An error's body is JSON too: decoded as the answer, it fails on the
  /// first missing field, with a cast error that names neither the status
  /// nor Webflow's message.
  http.Response _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebflowException(
          "${response.statusCode} on ${response.request?.method} "
          "${response.request?.url.path}: ${response.body}",
          statusCode: response.statusCode);
    }
    return response;
  }
}

/// A request the Webflow API did not answer with success, or a listing that
/// did not add up.
class WebflowException implements Exception {
  final String message;

  /// The response's status, when the API refused the request.
  final int? statusCode;

  WebflowException(this.message, {this.statusCode});

  @override
  String toString() => "WebflowException: $message";
}
