# Uniplex Sync Todo

- [x] Inspect the existing app flow, storage, and current Uniplex webview sync.
- [x] Inspect the live Uniplex frontend bundle to identify likely auth and data endpoints.
- [x] Replace the current sync entry UI with a secure Student ID + Password form.
- [x] Add a direct Uniplex API sync service for login, course import, and marks fetch.
- [x] Map imported Uniplex data into the app's existing `CourseModel` structure.
- [x] Keep the downstream dashboard and course flow unchanged after sync completes.
- [x] Add retry/error handling for invalid credentials, network issues, and partial mark sync.
- [x] Verify the app compiles after the integration.
- [ ] Document what still needs real-account validation against live Uniplex responses.
