import 'package:psps/features/reminders/adapters/flutter_notification_port.dart';
import 'package:psps/features/reminders/adapters/ohos_notification_port.dart';
import 'package:psps/features/reminders/notification_port.dart';

const _target = String.fromEnvironment('PSPS_TARGET');

NotificationPort createNotificationPort() =>
    _target == 'ohos' ? OhosNotificationPort() : FlutterNotificationPort();
