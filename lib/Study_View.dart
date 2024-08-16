import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';


List<Map<String, String>> coursesData = [];

class StudyViewSpace extends StatefulWidget {
  const StudyViewSpace({Key? key}) : super(key: key);

  @override
  State<StudyViewSpace> createState() => _StudyViewSpaceState();
}

class _StudyViewSpaceState extends State<StudyViewSpace> {
  final bool _isLoading = false;
  List<dynamic> courses = [];
  InAppWebViewController? _webViewController;
  bool showPage = false;

  void showCustomSnackbarLong(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 20,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
      webBgColor: "#000000",
      webShowClose: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: Padding(
              padding: const EdgeInsets.only(top: 28.0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Icon(
                      CupertinoIcons.back,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    "All spaces",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          body: courses.isNotEmpty
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 15.0),
                child: Text(
                  "Your courses",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final data = courses[index];
                    return ListTile(
                      trailing: const Icon(CupertinoIcons.forward),
                      leading: CircleAvatar(
                        backgroundColor: const Color.fromARGB(
                          255,
                          71,
                          24,
                          201,
                        ),
                        child: Text(
                          data['refId'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      title: Text(data['name']),
                      onTap: () {},
                    );
                  },
                ),
              ),
            ],
          )
              : showPage
              ? InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(
                'https://login.hs-heilbronn.de/realms/hhn/protocol/openid-connect/auth?response_mode=form_post&response_type=id_token&redirect_uri=https%3A%2F%2Filias.hs-heilbronn.de%2Fopenidconnect.php&client_id=hhn_common_ilias&nonce=badc63032679bb541ff44ea53eeccb4e&state=2182e131aa3ed4442387157cd1823be0&scope=openid+openid',
              ),
            ),
            onLoadStart: (controller, url) {
              setState(() {
                _webViewController = controller;
              });
            },
            onLoadStop: (controller, url) async {
              if (url.toString() ==
                  "https://ilias.hs-heilbronn.de/ilias.php?baseClass=ilDashboardGUI&cmd=jumpToSelectedItems") {
                controller.loadUrl(
                  urlRequest: URLRequest(
                    url: WebUri(
                      "https://ilias.hs-heilbronn.de/ilias.php?cmdClass=ilmembershipoverviewgui&cmdNode=jr&baseClass=ilmembershipoverviewgui",
                    ),
                  ),
                );
                Future.delayed(const Duration(seconds: 2), () async {
                  final result = await controller.evaluateJavascript(
                    source: '''
                               const courseRows = document.querySelectorAll('.il-std-item');
                               const courses = [];

                              function getRefId(url) {
                              const match = url.match(/ref_id=(\\d+)/);
                              return match ? match[1] : '';
                              }

                              courseRows.forEach((courseRow) => {
                              const imgElement = courseRow.querySelector('img.icon');
                              if (imgElement && imgElement.getAttribute('alt') !== 'Symbol Gruppe') {
                              const courseNameElement = courseRow.querySelector('.il-item-title a');
                              if (courseNameElement) {
                              const courseName = courseNameElement.innerText;
                              const courseUrl = courseNameElement.getAttribute('href');
                              const courseRefId = getRefId(courseUrl);
                              courses.push({
                              'name': courseName,
                              'refId': courseRefId,
                              'url': courseUrl,
                              });
                              }
                              }
                              });

                              courses;
                              ''',
                  );
                  // intiliaze the global and scoped list with scrapped data
                  setState(() {
                    courses = result;
                    print('Scrapped_result');
                    print(result);
                    showPage = !showPage;
                  });
                  for (final name in courses) {
                    coursesData.add({
                      'name': name['name'],
                      'refId': name['refId'],
                    });
                  }
                  // move back to previous page with scrapped data.
                  Navigator.of(context).pop(coursesData);
                });
              }
            },
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Courses not synchronized"),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      showPage = !showPage;
                    });
                    showCustomSnackbarLong(
                      context,
                      "Please wait while fetch data from the server",
                    );
                  },
                  child: const Text("Synchronize"),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: SizedBox(
                height: 50,
                child: Lottie.asset(
                  "assets/loading.json",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

