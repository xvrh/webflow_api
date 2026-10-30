import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:webflow_api/webflow_api.dart';

Map<String, dynamic> _item(String id) => {
      "id": id,
      "isArchived": false,
      "isDraft": false,
      "fieldData": {"name": "Item $id", "slug": "item-$id"},
    };

http.Response _page(List<String> ids,
        {required int offset, required int total}) =>
    http.Response(
        jsonEncode({
          "items": [for (var id in ids) _item(id)],
          "pagination": {"limit": 100, "offset": offset, "total": total},
        }),
        200);

Webflow _webflow(Future<http.Response> Function(http.Request) handler) =>
    Webflow(token: "token", siteId: "site", client: MockClient(handler));

void main() {
  test("items lists the published items when live", () async {
    late Uri requested;
    var webflow = _webflow((request) async {
      requested = request.url;
      return _page(["a"], offset: 0, total: 1);
    });

    var page = await webflow.items("c", live: true);

    expect(requested.path, "/v2/collections/c/items/live");
    expect(requested.queryParameters, {"offset": "0", "limit": "100"});
    expect(page.items.single.id, "a");
  });

  test("items lists the staged items by default", () async {
    late Uri requested;
    var webflow = _webflow((request) async {
      requested = request.url;
      return _page([], offset: 0, total: 0);
    });

    await webflow.items("c");

    expect(requested.path, "/v2/collections/c/items");
  });

  test("a refused request throws with its status and Webflow's message",
      () async {
    var webflow = _webflow((request) async => http.Response(
        '{"message":"Request not authorized","code":"not_authorized"}', 401));

    expect(
        webflow.items("c", live: true),
        throwsA(isA<WebflowException>()
            .having((e) => e.statusCode, "statusCode", 401)
            .having((e) => e.message, "message",
                contains("Request not authorized"))));
  });

  test("allItems reads every page", () async {
    var offsets = <String?>[];
    var ids = [for (var i = 0; i < 150; i++) "$i"];
    var webflow = _webflow((request) async {
      var offset = int.parse(request.url.queryParameters["offset"]!);
      offsets.add(request.url.queryParameters["offset"]);
      return _page(ids.skip(offset).take(100).toList(),
          offset: offset, total: 150);
    });

    var items = await webflow.allItems("c", live: true);

    expect(offsets, ["0", "100"]);
    expect(items.map((i) => i.id), ids);
  });

  test("allItems of an empty collection is empty", () async {
    var webflow = _webflow((request) async => _page([], offset: 0, total: 0));

    expect(await webflow.allItems("c"), isEmpty);
  });

  test("allItems refuses pages that stop short of the total", () async {
    var webflow = _webflow((request) async {
      var offset = int.parse(request.url.queryParameters["offset"]!);
      return offset == 0
          ? _page([for (var i = 0; i < 100; i++) "$i"], offset: 0, total: 150)
          : _page([], offset: offset, total: 150);
    });

    expect(webflow.allItems("c"), throwsA(isA<WebflowException>()));
  });

  test("allItems refuses a total that moved while the pages were read",
      () async {
    var webflow = _webflow((request) async {
      var offset = int.parse(request.url.queryParameters["offset"]!);
      return offset == 0
          ? _page([for (var i = 0; i < 100; i++) "$i"], offset: 0, total: 150)
          : _page([for (var i = 100; i < 150; i++) "$i"],
              offset: offset, total: 149);
    });

    expect(webflow.allItems("c"), throwsA(isA<WebflowException>()));
  });
}
