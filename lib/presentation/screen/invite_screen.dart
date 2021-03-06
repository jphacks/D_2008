import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_2008/di/get_it.dart';
import 'package:d_2008/firebase/dynamic_link/dynamic_link_service.dart';
import 'package:d_2008/model/request/twitter_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InviteScreen extends StatefulWidget {
  @override
  _InviteScreenState createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final titleController = TextEditingController();
  final detailController = TextEditingController();
  final targetController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    detailController.dispose();
    targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User currentUser = getItInstance.get<User>();
    String photoURL = currentUser.providerData.first.photoURL;

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Create ASOBI"),
        actions: [
          Container(
            //userPicture
            width: 40.0,
            height: 40.0,
            margin: EdgeInsets.fromLTRB(0, 10, 10, 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(fit: BoxFit.cover, image: NetworkImage(photoURL)
                  // image: NetworkImage("https://abs.twimg.com/sticky/default_profile_images/default_profile_normal.png")
                  ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: <Widget>[
                SizedBox(height: 40),
                TextField(
                  style: TextStyle(fontSize: 24),
                  decoration: InputDecoration(hintText: 'タイトル'),
                  controller: titleController,
                  minLines: 1,
                  maxLines: 2,
                  maxLength: 20,
                  maxLengthEnforced: true,
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'やりたいこと・日付・場所を簡潔に',
                    labelStyle: TextStyle(color: Colors.black38, height: 0),
                  ),
                  controller: detailController,
                  maxLength: 60,
                  maxLines: 3,
                  maxLengthEnforced: true,
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'それは誰とやりますか？',
                    labelStyle: TextStyle(color: Colors.black38, height: 0),
                  ),
                  controller: targetController,
                  maxLength: 15,
                  maxLengthEnforced: true,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: true
          ? FloatingActionButton(
              onPressed: () async {
                // TODO: loadingの実装
                final User currentUser = getItInstance.get<User>();
                final UserInfo userInfo = currentUser.providerData.first;
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                CollectionReference invitesRef = FirebaseFirestore.instance.collection('invites');
                DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userInfo.uid);
                debugPrint(currentUser.providerData.toString());

                String title = titleController.text;
                String detail = detailController.text;
                String target = targetController.text;

                invitesRef.add({
                  'ownerId': userInfo.uid,
                  'ownerName': userInfo.displayName,
                  'ownerPhotoURL': userInfo.photoURL,
                  'title': title,
                  'detail': detail,
                  'target': target,
                  'participantsRef': [userRef],
                  'participantsUid': [userInfo.uid],
                  'usersInfo': [
                    {
                      "uid": userInfo.uid,
                      "displayName": userInfo.displayName,
                      "photoURL": userInfo.photoURL,
                    },
                    {
                      "uid": userInfo.uid,
                      "displayName": userInfo.displayName,
                      "photoURL": userInfo.photoURL,
                    }
                  ],
                  'expulsionUserUid': [],
                  'isOpen': true,
                  'isClosed': false,
                }).then((DocumentReference ref) {
                  debugPrint("id: ${ref.path.split("/").last}");
                  DynamicLinkService().createInviteDynamicLink(inviteId: ref.path.split("/").last).then((dynamicLink) {
                    debugPrint(dynamicLink.toString());
                    TwitterRequest(prefs: prefs)
                        .postTweet("▽ ${title} ▽\n${detail}\n@ ${target}\n\n${dynamicLink}\n#REASOBI")
                        .then(
                          (_) => Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false),
                        );
                  });
                }).catchError((error) => print("Failed to add user: $error"));
              },
              child: Icon(Icons.check),
              backgroundColor: Color.fromRGBO(0, 150, 136, 1.0),
            )
          : null,
    );
  }
}
