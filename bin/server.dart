import 'dart:convert';
import 'dart:io';

import 'package:employers_widget_backend/entities/manager_entity.dart';
import 'package:neat_periodic_task/neat_periodic_task.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:employers_widget_backend/callgear_requests.dart';

// Configure routes.
final _router = Router()
  ..get('/getNumbersList', _getNumbersList)
  ..get('/getIdsList', _getIdsList);

Future<Response> _getNumbersList(Request request) async {
  var body = jsonEncode(await getManagersNumberList());
  print(body);

  return Response.ok(
    body,
  );
}

Future<Response> _getIdsList(Request request) async {
  var body = jsonEncode(await getManagersIdList());
  print(body);
  return Response.ok(
    body,
  );
}

final overrideHeaders = {
  "Access-Control-Allow-Origin": "*",
  'Access-Control-Allow-Methods': 'GET, POST',
  "Access-Control-Allow-Headers": "X-Requested-With",
};

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: overrideHeaders))
      .addHandler(_router);
  print(await getManagersNumberList());
  var group = await getGroupEmployees();
  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8088');
  final scheduler = NeatPeriodicTaskScheduler(
    interval: Duration(minutes: 1),
    name: 'dailyDecreaseBalance',
    timeout: Duration(seconds: 10),
    task: () async {
      var data = jsonDecode((await http.get(Uri.parse(
              "https://dknwidgets-default-rtdb.europe-west1.firebasedatabase.app/managers_roles.json")))
          .body);
      final usersId = await getManagersIdList();
      DateTime now = DateTime.now().toUtc();
      data.entries.forEach((element) {
        var manager = ManagerEntity.fromMap(element.value);
        final weekDay = now.weekday - 1;
        if (now.hour == manager.timeStart[weekDay].hour &&
            now.minute == manager.timeStart[weekDay].minute) {
          final userId = usersId[manager.name];
          if (userId != null) {
            for (var departmentEntry in manager.data.entries) {
              if (departmentEntry.value[weekDay * 2]) {
                addEmployer(userId, "${departmentEntry.key}_day");
                print(
                    "added employer ${manager.name} to ${departmentEntry.key}_day");
              }
            }
          }
        }
        if (now.hour == manager.timeEnd[weekDay].hour &&
            now.minute == manager.timeEnd[weekDay].minute) {
          final userId = usersId[manager.name];
          if (userId != null) {
            for (var departmentEntry in manager.data.entries) {
              if (departmentEntry.value[weekDay * 2]) {
                removeEmployer(userId, "${departmentEntry.key}_day");
                print(
                    "removed employer ${manager.name} from ${departmentEntry.key}_day");
              }
              if (departmentEntry.value[weekDay * 2 + 1]) {
                addEmployer(userId, "${departmentEntry.key}_night");
                print(
                    "added employer ${manager.name} to ${departmentEntry.key}_night");
              }
            }
          }
        }
        if (now.hour == 0 && now.minute == 0) {
          final userId = usersId[manager.name];
          if (userId != null) {
            for (var departmentEntry in manager.data.entries) {
              updateGroupEmployees([], "${departmentEntry.key}_night");
              print("clearEmployers");
            }
          }
        }
        //TODO create logic
      });
    },
    minCycle: Duration(seconds: 10),
    maxCycle: Duration(seconds: 30),
  );
  scheduler.start();

  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
