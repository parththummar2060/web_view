import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Web view",
    home: WebView(),
  ));
}

class WebView extends StatefulWidget {
  const WebView({Key? key}) : super(key: key);

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  List bookMark = [];
  double prog = 0;

  GlobalKey webViewKey = GlobalKey();
  late PullToRefreshController pullToRefreshController;
  TextEditingController searchcontroller = TextEditingController();

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  webReload() {
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    webReload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff54759e),
        title: const Text("Browser"),
        actions: [
          IconButton(
            onPressed: () {
              webViewController?.goBack();
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () async {
              if (Platform.isAndroid) {
                webViewController?.reload();
              } else if (Platform.isIOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () {
              webViewController?.goForward();
            },
            icon: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onSubmitted: (value) {
                        var url = Uri.parse(value);
                        if (url.scheme.isEmpty) {
                          url = Uri.parse(
                              "https://www.google.com/search?q=" + value);
                        }
                        webViewController?.loadUrl(
                            urlRequest: URLRequest(url: url));
                      },
                      controller: searchcontroller,
                      decoration: const InputDecoration(
                        hintText: "  Search...",
                      ),
                    ),
                  ),
                  const Icon(Icons.search),
                ],
              ),
            ),
          ),
          prog < 1.0 ? LinearProgressIndicator(value: prog) : Container(),
          Expanded(
            flex: 10,
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest:
                  URLRequest(url: Uri.parse("https://www.google.com/")),
              initialOptions: options,
              pullToRefreshController: pullToRefreshController,
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, uri) {
                setState(() {
                  searchcontroller.text =
                      uri!.scheme.toString() + "://" + uri.host + uri.path;
                });
              },
              onLoadStop: (controller, uri) async {
                pullToRefreshController.endRefreshing();
                setState(() {
                  searchcontroller.text =
                      uri!.scheme.toString() + "://" + uri.host + uri.path;
                });
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100) {
                  pullToRefreshController.endRefreshing();
                }
                setState(() {
                  prog = progress / 100;
                  searchcontroller.text = prog.toString();
                });
              },
              androidOnPermissionRequest:
                  (controller, origin, resources) async {
                return PermissionRequestResponse(
                    resources: resources,
                    action: PermissionRequestResponseAction.GRANT);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: const Color(0xff54759e),
            onPressed: () async {
              Uri? uri = await webViewController!.getUrl();
              String myUrl =
                  uri!.scheme.toString() + "://" + uri.host + uri.path;
              bookMark.add(myUrl);
            },
            child: const Icon(Icons.bookmark_border),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            backgroundColor: const Color(0xff54759e),
            onPressed: () async {
              await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Center(child: Text("BookMark")),
                      content: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: bookMark
                              .map((e) => GestureDetector(
                                    onTap: () async {
                                      webViewController!.loadUrl(
                                          urlRequest: URLRequest(
                                              url: Uri.parse(e.toString())));
                                      Navigator.of(context).pop();
                                    },
                                    child: Container(
                                        margin: const EdgeInsets.all(10),
                                        height: 30,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(e.toString())),
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  });
            },
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}
