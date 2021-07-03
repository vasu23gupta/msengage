import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/AppUser.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget {
  final AppUser appUser;
  const Profile({required this.appUser});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late User? _user;
  late AppUser _appUser;
  late double _w;
  late double _h;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _appUser = widget.appUser;
  }

  @override
  Widget build(BuildContext context) {
    _w = MediaQuery.of(context).size.width;
    _h = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          _buildUserIcon(),
          SizedBox(height: 10),
          Divider(color: Colors.grey[300], thickness: 1, indent: _w * 0.04),
          _buildEmailHeading(),
          _buildEmail(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      iconTheme: APPBAR_ICON_THEME,
      title: Text(_appUser.name, style: APPBAR_TEXT_STYLE),
    );
  }

  Center _buildUserIcon() {
    return Center(
      child: Stack(
        children: [
          _appUser.imgUrl == null || _appUser.imgUrl!.isEmpty
              ? CircleAvatar(
                  radius: _h * 0.1,
                  child: Text(
                    _appUser.name.substring(0, 2).toUpperCase(),
                    style: TextStyle(fontSize: _w * 0.08),
                  ))
              : CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      ImageDatabaseService.getImageByImageId(_appUser.imgUrl!)),
          if (_user!.uid == _appUser.id) _buildEditImageButton()
        ],
      ),
    );
  }

  Padding _buildEmailHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
      child: Text("Email", style: TextStyle(fontSize: _w * 0.035)),
    );
  }

  Padding _buildEmail() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 0, 8),
      child: TextButton(
        onPressed: () => launch("mailto:${_appUser.email}?subject=&body="),
        child: Text(
          _appUser.email,
          style: TextStyle(
              color: Colors.indigo,
              decoration: TextDecoration.underline,
              fontSize: _w * 0.045),
        ),
      ),
    );
  }

  Positioned _buildEditImageButton() => Positioned(
        bottom: 6,
        right: 6,
        height: 20,
        width: 20,
        child: PopupMenuButton(
          onSelected: (choice) async {
            switch (choice) {
              case 'Edit':
                String? path = await _pickFile();
                String? newImg;
                if (path != null) {
                  newImg = await UserDBService.changeUserIcon(_user!, path);
                  _user!.updatePhotoURL(newImg);
                  setState(() => _appUser.imgUrl = newImg);
                }
                break;

              case 'Remove':
                bool done = await UserDBService.removeUserIcon(_user!);
                if (done) setState(() => _appUser.imgUrl = null);
                break;
            }
          },
          icon: Icon(Icons.edit),
          itemBuilder: (context) => ['Edit', 'Remove']
              .map(
                  (choice) => PopupMenuItem(child: Text(choice), value: choice))
              .toList(),
        ),
      );

  Future<String?> _pickFile() async {
    FilePickerResult? pickedFile = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.image);
    if (pickedFile != null) return pickedFile.files.first.path;
  }
}
