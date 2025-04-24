import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserBubble extends StatelessWidget {
  final String text;

  const UserBubble({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: CircleAvatar(
        backgroundImage: AssetImage('assets/user_avatar.png'),
        radius: 20.r,
      ),
      title: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              bottomLeft: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r),
            ),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
