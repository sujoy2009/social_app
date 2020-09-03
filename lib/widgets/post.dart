import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';


class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }
  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    username: this.username,
    location: this.location,
    description: this.description,
    mediaUrl: this.mediaUrl,
    likes: this.likes,
    likeCount: getLikeCount(this.likes),
  );
}

class _PostState extends State<Post> {

  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  final String currentuserid=currentuser?.id;
  bool isliked;
  // value of isliked is set in build widget
  bool showheart=false;



  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });
  buildpostHeader(){
    return FutureBuilder(
      future: userref.document(ownerId).get(),
      builder: (context,snapshot){
        if(!snapshot.hasData){
          return circularProgress();


        }
        User user=User.fromDocument(snapshot.data);
        bool isowner=currentuserid==ownerId;
        return ListTile(
          leading: GestureDetector(
            onTap: ()=> showProfile(context, profileId: user.id),

            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              backgroundColor:Colors.grey ,
            ),
          ),
          title: GestureDetector(
            onTap: ()=> showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,

              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isowner? IconButton(
            onPressed: ()=>handeldeletepost(context),
            icon: Icon(
              Icons.more_vert,
            ),

          ):Text(''),

        );

      },

    );

  }
  handeldeletepost(BuildContext parentcontext){
    return showDialog(
      context: parentcontext,
      builder: (context){
        return SimpleDialog(title: Text('remove this post?'),
         children: <Widget>[
           SimpleDialogOption(
             onPressed:(){
               Navigator.pop(context);
               deletepost();
             } ,
             child: Text('Delete',
             style: TextStyle(color: Colors.red),),

           ),
           SimpleDialogOption(
             onPressed: ()=>Navigator.pop(context),
             child: Text('Cancel'),
           )
         ],
        );
      }

    );

  }
  deletepost()async{
    postsRef.document(ownerId).collection('userPosts').document(postId)
        .get().then((doc) {
          if(doc.exists){
            doc.reference.delete();
          }

       });
    //storage pic delete
    storageRef.child("post_$postId.jpg").delete();
    //delete notification
   QuerySnapshot activityquerySnapshot=await activityFeedRef.document(ownerId).collection("feedItems")
    .where('postId',isEqualTo:postId).
    getDocuments();
   activityquerySnapshot.documents.forEach((doc) {
     if(doc.exists){
       doc.reference.delete();
     }

   });
   //delete comments
  QuerySnapshot commentquerySnapshot = await commentsRef.document(postId).collection('comments').getDocuments();
  commentquerySnapshot.documents.forEach((doc) {
    if(doc.exists){
      doc.reference.delete();

    }

  });

  }


  addLikeToActivityFeed() {
    // add a notification to the postOwner's activity feed only if comment made by OTHER user (to avoid getting notification for our own like)
    bool isNotPostOwner = currentuserid != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .setData({
        "type": "like",
        "username": currentuser.username,
        "userId": currentuser.id,
        "userProfileImg": currentuser.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timestamp": timestamp,
      });
    }
  }
  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentuserid != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }
  liking_post(){
   bool _isliked= likes[currentuserid]==true;
   if(_isliked){
     postsRef.document(ownerId).collection('userPosts').document(postId)
     .updateData({'likes.$currentuserid':false});
     removeLikeFromActivityFeed();
     setState(() {
       likeCount=likeCount-1;
       isliked=false;
       likes[currentuserid]=false;


     });


   }
   else if(!_isliked){
     postsRef.document(ownerId).collection('userPosts').document(postId)
         .updateData({'likes.$currentuserid':true});
     addLikeToActivityFeed();
     setState(() {
       likeCount=likeCount+1;
       isliked=true;
       likes[currentuserid]=true;
       showheart=true;


     });
     Timer(Duration(milliseconds: 500),(){
       setState(() {
         showheart=false;
       });

     });



   }



  }
  buildimage(){
    return GestureDetector(
      onDoubleTap: liking_post,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          //Image.network(mediaUrl),
          //rather use a custom image widget
          cachedNetworkImage(mediaUrl),
        showheart? Animator(
           duration: Duration(milliseconds: 300),
           tween: Tween(begin: 0.8,end: 1.4),
           curve: Curves.elasticOut,
           cycles: 0,
           builder: (anim)=>Transform.scale(
               scale: anim.value,
             child:Icon(Icons.favorite,size: 80,color: Colors.red,)
             ,
           ),

         ):Text(''),
         //without animation
         // showheart?Icon(Icons.favorite,size: 80,color: Colors.red,):Text(''),
        ],
      ),

    );
  }
  jumptocommentpage(){
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Comments(
        postId: postId,
        postOwnerId: ownerId,
        postMediaUrl: mediaUrl,
      );
    }));
  }

  buildfooter(){
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: liking_post,
              child: Icon(
               isliked? Icons.favorite: Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: jumptocommentpage,





              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$username ",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(description))
          ],
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
     isliked= likes[currentuserid]==true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildpostHeader(),
        buildimage(),
        buildfooter(),
      ],

    );
  }
}
/*
showComments(BuildContext context,
    {String postId, String ownerId, String mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl,
    );
  }));
}


 */

