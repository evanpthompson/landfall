/// Timeouts for the long-poll the display keeps open against the server.
///
/// These two constants are a pair, and the relationship between them is the
/// whole point of this file.
///
/// The companion poll is a *long* poll: the server holds the request open,
/// answering only when there is an action or when the hold expires. Serverpod's
/// client wraps every request in `.timeout(connectionTimeout)`, and
/// `Future.timeout` abandons the future without closing the socket underneath
/// it. So if the client's timeout is shorter than the hold, every poll times
/// out and leaks its socket.
///
/// That is not hypothetical. With the library default of 20 s against a 30 s
/// hold, a Pi reached its 1024-descriptor limit and stayed pinned there:
/// 8.8 million "export failed" lines, 88,049 "Too many open files" errors, and
/// a dashboard where the clock ticked while nothing else could reach the
/// server, because no request could get a socket.
library;

/// How long the server is asked to hold a companion long-poll open.
const Duration kCompanionPollTimeout = Duration(seconds: 30);

/// The HTTP timeout applied to every Serverpod client call.
///
/// Must stay comfortably above [kCompanionPollTimeout] — see the library note.
/// The margin absorbs the round trip and any scheduling delay on a loaded Pi,
/// so a healthy long poll always returns before the client gives up on it.
const Duration kClientConnectionTimeout = Duration(seconds: 45);

/// The margin the invariant is tested against.
const Duration kPollTimeoutMargin = Duration(seconds: 10);
