import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _fireStore = FirebaseFirestore.instance;
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageTextSController = TextEditingController();
  String messageText;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void getMessages() async {
    final messages = await _fireStore.collection('messages').get();
    for (var message in messages.docs) {
      print(message.data());
    }
  }

  void messageStream() async {
    await _fireStore.collection('messages').snapshots().forEach((element) {
      for (var snapshot in element.docs) {
        print(snapshot.data());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                messageStream();
                _auth.signOut();
                Navigator.pop(context);
                //Implement logout functionality
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: MessageTextSController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      MessageTextSController.clear();
                      //Implement send functionality.
                      _fireStore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'time': DateTime.now().millisecondsSinceEpoch,
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').orderBy('time').snapshots(),
      // ignore: missing_return
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final messages = snapshot.data;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages.docs) {
            final messageText = message.data()['text'];
            final messageSender = message.data()['sender'];
            final currentUser = loggedInUser.email;
            final messageBubble = MessageBubble(
              sender: messageSender,
              text: messageText,
              isMe: currentUser == messageSender,
            );
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              children: messageBubbles,
            ),
          );
        }
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe});
  final String sender;
  final String text;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            (isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start),
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 10.0,
              color: Colors.black,
            ),
          ),
          Material(
            borderRadius: BorderRadius.only(
              topRight: (!isMe ? Radius.circular(30.0) : Radius.circular(0.0)),
              topLeft: (isMe ? Radius.circular(30.0) : Radius.circular(0.0)),
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            ),
            elevation: 5.0,
            color: (isMe ? Colors.lightBlueAccent : Colors.white),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 15.0,
                    color: (isMe ? Colors.white : Colors.black54)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
