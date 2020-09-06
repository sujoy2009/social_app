

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

import 'activity_feed.dart';


class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchresult;
  handelsubmit(String query){
   Future<QuerySnapshot> users =userref.where('displayName',isGreaterThanOrEqualTo: query).getDocuments();
   setState(() {
     searchresult=users;
   });
  }
  clearSearch() {
    searchController.clear();
    setState(() {
      searchresult=null;
    });

  }

 AppBar buildsearchfield(){
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "SEARCH FOR USER",
              filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 28.0,

          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.clear,

            ),
            onPressed:clearSearch,

          )
        ),
        onFieldSubmitted: handelsubmit,

      ),


    );
  }
 Container buildnocontent(){
   return Container(
     child: Center(
       child: ListView(
         children: <Widget>[
          // SvgPicture.asset(assetName),
           Text('     Find user  ',
             style: TextStyle(
               color: Colors.white,
               fontWeight: FontWeight.w600,
               fontStyle: FontStyle.italic,
               fontSize: 60,

             ),
           )
         ],

       ),
     ),

   );

 }
  builssearchreasult(){
    return FutureBuilder(
      future: searchresult,
      builder: (context,snapshot){
        if(!snapshot.hasData){
          return circularProgress();

        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
         UserResult userResult= UserResult(user);

          searchResults.add(userResult);
        });
        return ListView(
          children: searchResults,
        );

    },
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),

      appBar: buildsearchfield(),
      body:searchresult==null? buildnocontent():builssearchreasult(),

    );
  }
}


class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: ()=>showProfile(context, profileId: user.id),
            child:ListTile(

              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(user.displayName,style: TextStyle(
                color: Colors.white,fontWeight: FontWeight.bold,
              ),
              ),
              subtitle:Text(user.username,style: TextStyle(
                color: Colors.white,fontWeight: FontWeight.bold,
              ),
              ),


            ) ,



          ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          )
        ],
      ),


    );
  }
}
