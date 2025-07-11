abstract class SyncStatus {
  const SyncStatus();
  double progress();
}

class StartingScanSyncStatus extends SyncStatus {
  StartingScanSyncStatus(this.beginHeight);

  final int beginHeight;
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Starting Scan $beginHeight';
}

class SyncingSyncStatus extends SyncStatus {
  SyncingSyncStatus(this.blocksLeft, this.ptc);

  final double ptc;
  final int blocksLeft;

  @override
  double progress() => ptc;

  @override
  String toString() => '$blocksLeft';

  factory SyncingSyncStatus.fromHeightValues(int chainTip, int initialSyncHeight, int syncHeight) {
    final track = chainTip - initialSyncHeight;
    final diff = track - (chainTip - syncHeight);
    final ptc = diff <= 0 ? 0.0 : diff / track;
    final left = chainTip - syncHeight;

    // sum 1 because if at the chain tip, will say "0 blocks left"
    return SyncingSyncStatus(left + 1, ptc);
  }
}

class ProcessingSyncStatus extends SyncStatus {
  final String? message;

  ProcessingSyncStatus({this.message});

  @override
  double progress() => 0.99;

  @override
  String toString() => 'Processing';
}

class SyncedSyncStatus extends SyncStatus {
  @override
  double progress() => 1.0;

  @override
  String toString() => 'Synced';
}

class SyncedTipSyncStatus extends SyncedSyncStatus {
  SyncedTipSyncStatus(this.tip);

  final int tip;

  @override
  String toString() => 'Synced Tip $tip';
}

class SyncronizingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Synchronizing';
}

class NotConnectedSyncStatus extends SyncStatus {
  const NotConnectedSyncStatus();

  @override
  double progress() => 0.0;

  @override
  String toString() => 'Not Connected';
}

class AttemptingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Attempting';
}

class AttemptingScanSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Attempting Scan';
}

class FailedSyncStatus extends NotConnectedSyncStatus {
  String? error;
  FailedSyncStatus({this.error});

  @override
  String toString() => error ?? super.toString();
}

class ConnectingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Connecting';
}

class ConnectedSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;

  @override
  String toString() => 'Connected';
}

class UnsupportedSyncStatus extends NotConnectedSyncStatus {}

class TimedOutSyncStatus extends NotConnectedSyncStatus {
  @override
  String toString() => 'Timed out';
}

class LostConnectionSyncStatus extends NotConnectedSyncStatus {
  @override
  String toString() => 'Reconnecting';
}
