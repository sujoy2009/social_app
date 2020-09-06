import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });
  @override
  CommentsState createState() => CommentsState(

  );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();

  buildComments(){
    return StreamBuilder(
        stream: commentsRef
            .document(widget.postId)
            .collection('comments')
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<Comment> comments = [];
          snapshot.data.documents.forEach((doc) {
            comments.add(Comment.fromDocument(doc));
          });
          return ListView(
            children: comments,
          );
        });

  }
  addComment(){
    commentsRef.document(widget.postId).collection("comments").add({
      "username": currentuser.username,
      "comment": commentController.text,
      "timestamp": timestamp,
      "avatarUrl": currentuser.photoUrl,
      "userId": currentuser.id,
    });
    bool isNotPostOwner = widget.postOwnerId != currentuser.id;
    if (isNotPostOwner) {
      activityFeedRef.document(widget.postOwnerId).collection('feedItems').add({
        "type": "comment",
        "commentData": commentController.text,
        "timestamp": timestamp,
        "postId": widget.postId,
        "userId": currentuser.id,
        "username": currentuser.username,
        "userProfileImg": currentuser.photoUrl,
        "mediaUrl":widget.postMediaUrl,
      });
    }
    commentController.clear();

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: "Write a comment..."),
            ),
            trailing: OutlineButton(
              onPressed: addComment,
              borderSide: BorderSide.none,
              child: Text("Comment"),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    this.username,
    this.userId,
    this.avatarUrl,
    this.comment,
    this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(),
      ],
    );
  }
  }

