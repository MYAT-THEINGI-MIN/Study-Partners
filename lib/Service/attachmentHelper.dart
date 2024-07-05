import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AttachmentHelper {
  File? creatorAttachment;
  String? creatorAttachmentLink;
  String? attachmentType;

  Future<void> pickImageAttachment(
      BuildContext context, Function setStateCallback) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setStateCallback(() {
        creatorAttachment = File(pickedFile.path);
        attachmentType = 'image';
      });
    }
  }

  Future<void> pickFileAttachment(
      BuildContext context, Function setStateCallback) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setStateCallback(() {
        creatorAttachment = File(result.files.single.path!);
        attachmentType = result.files.single.extension;
      });
    }
  }

  void showLinkAttachmentDialog(BuildContext context, Function setStateCallback,
      TextEditingController linkController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Link'),
          content: TextField(
            controller: linkController,
            decoration: InputDecoration(
              labelText: 'Attachment Link',
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setStateCallback(() {
                  creatorAttachmentLink = linkController.text;
                  attachmentType = 'link';
                });
                Navigator.of(context).pop();
              },
              child: Text('Add Link'),
            ),
          ],
        );
      },
    );
  }

  void showAttachmentMenu(BuildContext context, Function setStateCallback,
      TextEditingController linkController) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Insert Photo'),
              onTap: () {
                pickImageAttachment(context, setStateCallback);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_file),
              title: Text('Attach File'),
              onTap: () {
                pickFileAttachment(context, setStateCallback);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('Insert Link'),
              onTap: () {
                Navigator.pop(context);
                showLinkAttachmentDialog(
                    context, setStateCallback, linkController);
              },
            ),
          ],
        );
      },
    );
  }
}
