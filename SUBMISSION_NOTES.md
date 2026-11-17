# Submission Note: API Status

## Summary
All API calls in the app follow the **Calley Mock API V2** Postman documentation. When I built and
tested the app (16–17 Nov 2026), though, the mock server was not serving the API. So the app ships
with a **demo mode** that turns on by itself, which lets every screen be reviewed without a backend.

## What I saw on the server
Base URL from the docs: `https://mock-api.calleyacd.com/api`

| Check | Result |
|---|---|
| `POST /auth/register` from the app | `HTTP 404`, an Apache HTML "Not Found" page instead of JSON |
| `http://mock-api.calleyacd.com/api/list` | Apache/Plesk 404 page, so no API is deployed at that path |
| HTTPS certificate | Issued for `cool-meninsky.74-208-123-142.plesk.page`, not `mock-api.calleyacd.com`, so normal clients reject it |

The endpoint paths and request bodies in the app match the Postman docs exactly. The 404 comes from
the server, not from the app. I emailed the company contact about this on 17 Nov 2026.

## Endpoints implemented (`lib/services/api_client.dart`)
| Screen | Method & path | Body / query |
|---|---|---|
| Register | `POST /auth/register` | `{username, email, password}` |
| OTP (send) | `POST /auth/send-otp` | `{email}` |
| OTP (verify) | `POST /auth/verify-otp` | `{email, otp}` |
| Sign in | `POST /auth/login` | `{email, password}` → `user._id` |
| Dashboard / calling lists | `GET /list?userId=<id>` | `{email}` (JSON body, as in the docs) |
| List detail | `GET /list/<listId>` | `{email}` (JSON body, as in the docs) |

Implementation notes:
- **Register returns no user id**, so after OTP verification the app calls `login` to get `_id`
  for the list endpoints.
- The docs send a **JSON body on the GET requests**, so the client uses a raw `http.Request`
  (`http.get` can't send a body).
- The list response is parsed whether it is a single object, an array, or `{lists: [...]}`.

## Demo mode
The app switches to demo mode when the server is unavailable: a non-JSON 404, a TLS/certificate
failure, no network, or a timeout. An amber banner shows while it is on.
- OTP: **`123456`**
- Sample calling list: "Test List" (27 pending / 23 done / 11 scheduled)
- Any username/email/password works for register and sign in.

Real API errors (for example, a JSON error message from a working server) are still shown to the
user. Demo mode never hides them. **Once the API is reachable again, the app uses it automatically,
with no code change.**

## TLS certificate workaround
In **debug builds only**, the client accepts the mismatched certificate for `mock-api.calleyacd.com`
and no other host (`ApiClient._createClient`). **Release builds keep full certificate checks**, so
the attached release APK goes into demo mode until the server certificate is fixed. Remove the
workaround after that.

## Testing
- `flutter analyze`: clean. `flutter test`: 13/13 passing, including API client tests with a
  mocked HTTP client.
- Tested on an Android emulator (debug and release APK): register → OTP → sign in → dashboard →
  list detail, all in demo mode.
- I could not test against the live API because it was not available.
