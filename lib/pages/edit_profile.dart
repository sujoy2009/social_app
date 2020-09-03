import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentuserid;
  EditProfile({this.currentuserid});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
 final _scafoldkey=GlobalKey<ScaffoldState>();
  TextEditingController displaynamecontroler=TextEditingController();
  TextEditingController biocontroler=TextEditingController();

  bool isloading=false;
  User user;
  bool _displaynamevalid=true;
  bool _biovalid=true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getuser();
  }
  getuser()async{
    setState(() {
      isloading=true;
    });
    DocumentSnapshot doc=await userref.document(widget.currentuserid).get();
 user=  User.fromDocument(doc);
 displaynamecontroler.text=user.displayName;
 biocontroler.text=user.bio;
    setState(() {
      isloading=false;
    });


  }
 logout()async{
  await  googlesignin.signOut();
  Navigator.push(context, MaterialPageRoute(builder: (context)=>
  Home()));


 }
  updatedata(){
    setState(() {
      displaynamecontroler.text.trim().length<3 ||
      displaynamecontroler.text.trim().isEmpty ?_displaynamevalid=false :
          _displaynamevalid=true;
      biocontroler.text.trim().length>100 ? _biovalid=false:
          _biovalid=true;
      if(_biovalid && _displaynamevalid){
        userref.document(widget.currentuserid).updateData({
          'displayName':displaynamecontroler.text,
          'bio': biocontroler.text


        });
        SnackBar snackBar=SnackBar(content: Text('profile uploded'));
        _scafoldkey.currentState.showSnackBar(snackBar);

      }
    });


  }


 Column builddisplayField(){
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: <Widget>[
       Padding(
           padding: EdgeInsets.only(top: 12.0),
           child: Text(
             "Display Name",
             style: TextStyle(color: Colors.grey),
           )),
       TextField(
         controller: displaynamecontroler,
         decoration: InputDecoration(
           hintText: "Update Display Name",
           errorText: _displaynamevalid ? null : "Display Name too short",
         ),
       )
     ],
   );
 }

  Column  buildBioField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top:8.0),
          child: Text(
            'Display bio',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: biocontroler,
          decoration: InputDecoration(

            hintText: 'Update Bio',
            errorText: _biovalid ? null :"Bio should be less than 100 char",
          ),
        )
      ],

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key:  _scafoldkey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Edit profile',
          style: TextStyle(
            color: Colors.black,
          ),

        ),
        actions: <Widget>[
          IconButton(
            onPressed: ()=>Navigator.pop(context),
            icon: Icon(
              Icons.done,
              size: 30.0,
              color: Colors.green,
            )

          )
        ],
      ),
      body: isloading ? circularProgress():
      ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 16,bottom: 10),
               child: CircleAvatar(
                 backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                 radius: 50,

               ),
                ),
                Padding(
                  padding: const EdgeInsets.all(17.0),
                  child: Column(
                    children: <Widget>[
                      builddisplayField(),
                      buildBioField(),

                    ],
                  ),
                ),
                RaisedButton(
                  onPressed: updatedata,
                  child: Text(
                    'update profile',
                    style: TextStyle(
                      color:  Theme.of(context).primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,


                    ),

                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(17.0),
                  child: FlatButton.icon(
                    icon: Icon(Icons.cancel,color: Colors.red,),
                    onPressed: logout,
                    label: Text(
                      'LOG OUT',
                      style: TextStyle(
                        color:  Theme.of(context).primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,


                      ),

                    ),
                  ),
                ),


              ],

            ),

          )

        ],

      ),
    );
  }
}
