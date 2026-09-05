import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';

class AppwriteClientConfig {
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '6a991b46001c1972b134';
  static const String databaseId = '6a991ba5002a0022ed83';
  static const String reportsCollectionId = '6a991e450031cf1297df';
  static const String activityLogsCollectionId = '6a9a245500343a980967';
  static const String notificationsCollectionId = '6a9b3000000000000000';
  static const String storageBucketId = '6a99219d002f23752a34';

  late final Client client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  late final Functions functions;

  AppwriteClientConfig({String? customProjectId, String? customEndpoint}) {
    client = Client()
        .setEndpoint(customEndpoint ?? endpoint)
        .setProject(customProjectId ?? projectId)
        .setSelfSigned(status: !kReleaseMode);

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    functions = Functions(client);
  }

  /// Verify connectivity to the Appwrite server using the SDK's
  /// [Client.ping] method (HTTP GET /ping).
  ///
  /// Returns `null` when the server responds successfully, or a
  /// human-readable error string describing why the ping failed.
  Future<String?> ping() async {
    try {
      await client.ping().timeout(const Duration(seconds: 10));
      return null;
    } on AppwriteException catch (e) {
      return 'Appwrite ping failed (${e.code}): ${e.message}';
    } catch (e) {
      return 'Connection error: $e';
    }
  }
}

class Environment {
  static const String appwriteProjectId = AppwriteClientConfig.projectId;
  static const String appwriteProjectName = 'Nagar-Drishti';
  static const String appwritePublicEndpoint = AppwriteClientConfig.endpoint;
}
