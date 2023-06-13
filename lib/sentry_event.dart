class SentryEvent {
    Uri frontVideoUri;
    Uri backVideoUri;
    Uri leftVideoUri;
    Uri rightVideoUri;
    DateTime time;

    SentryEvent({
        required this.frontVideoUri,
        required this.backVideoUri,
        required this.leftVideoUri,
        required this.rightVideoUri,
        required this.time,
    });
}