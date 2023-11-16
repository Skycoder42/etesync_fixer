import 'dart:async';

import 'package:etebase/etebase.dart';

typedef ProcessInvitationCb = FutureOr<bool> Function(
  EtebaseSignedInvitation invitation,
);

extension EtebaseCollectionInvitationManagerX
    on EtebaseCollectionInvitationManager {
  Future<void> processIncoming(ProcessInvitationCb processInvitation) async {
    String? iterator;
    var isDone = true;
    do {
      final response = await listIncoming(
        EtebaseFetchOptions(iterator: iterator),
      );

      try {
        final invitations = await response.getData();

        for (final invitation in invitations) {
          final processingDone = await processInvitation(invitation);
          if (processingDone) {
            return;
          }
        }

        isDone = await response.isDone();
        iterator = await response.getIterator();
      } finally {
        await response.dispose();
      }
    } while (!isDone);
  }
}
