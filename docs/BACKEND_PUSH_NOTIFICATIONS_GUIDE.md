# 🔔 EventSphere Backend Push Notification Integration Guide

This guide provides the complete specification, architecture, API endpoints, and code examples for the backend engineering team to integrate Firebase Cloud Messaging (FCM) push notifications with the EventSphere Flutter mobile app.

---

## 📑 Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Database Schema for Device Tokens](#2-database-schema-for-device-tokens)
3. [Device Token Management REST Endpoints](#3-device-token-management-rest-endpoints)
4. [FCM v1 Message Payload Standard](#4-fcm-v1-message-payload-standard)
5. [Deep Linking & In-App Navigation Targets](#5-deep-linking--in-app-navigation-targets)
6. [Backend Code Examples (Node.js & Python)](#6-backend-code-examples)
7. [Common Notification Scenarios & Event Triggers](#7-common-notification-scenarios)
8. [Testing & cURL Commands](#8-testing--curl-commands)

---

## 1. Architecture Overview

```
┌─────────────────┐        1. POST /notifications/device-token        ┌──────────────────────┐
│                 ├───────────────────────────────────────────────────►│                      │
│   Flutter App   │                                                    │   Backend Service    │
│  (iOS / Android)│◄───────────────────────────────────────────────────┤   (Node/Python/Go)   │
└────────┬────────┘        2. Token saved in DB against User ID        └──────────┬───────────┘
         ▲                                                                        │
         │                                                                        │ 3. Send Notification
         │                         4. High-Priority Push Alert                    │    via FCM v1 API
         └────────────────────────────────────────────────────────────────────────┴───┐
                                                                                      ▼
                                                                           ┌──────────────────────┐
                                                                           │ Firebase Cloud       │
                                                                           │ Messaging (FCM v1)   │
                                                                           └──────────────────────┘
```

### Critical Mobile Requirements:
- **Android Notification Channel ID**: `eventsphere_high_importance` *(Mandatory for Android 8.0+ heads-up banner notifications)*
- **Android Channel Name**: `High Importance Notifications`
- **Click Action**: `FLUTTER_NOTIFICATION_CLICK`
- **Data Payload Values**: **Must all be `string` values** (FCM does not permit nested JSON objects or booleans inside the `data` map).

---

## 2. Database Schema for Device Tokens

Store multiple device tokens per user (users may be logged in on multiple devices or tablets).

### PostgreSQL / MySQL Schema
```sql
CREATE TABLE user_device_tokens (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    fcm_token TEXT NOT NULL UNIQUE,
    device_type VARCHAR(16) NOT NULL, -- 'ANDROID', 'IOS', 'OTHER'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_device_tokens_user_id ON user_device_tokens(user_id);
```

---

## 3. Device Token Management REST Endpoints

The mobile app automatically calls these endpoints when a user logs in, when the token refreshes, and when the user logs out.

### 3.1 Register / Sync Device Token
- **Endpoint**: `POST /notifications/device-token`
- **Authentication**: `Bearer <JWT_ACCESS_TOKEN>`
- **Request Body**:
```json
{
  "fcmToken": "dK4X0a91L_...:APA91bFw...",
  "deviceType": "ANDROID"
}
```
- **Response**: `200 OK`
```json
{
  "success": true,
  "message": "Device token registered successfully"
}
```
- **Backend Logic (Upsert)**:
  - If `fcm_token` exists, update `user_id` and `updated_at`.
  - If `fcm_token` does not exist, insert `(user_id, fcm_token, device_type)`.

---

### 3.2 Unregister Device Token (On Logout)
- **Endpoint**: `DELETE /notifications/device-token`
- **Authentication**: `Bearer <JWT_ACCESS_TOKEN>`
- **Request Body**:
```json
{
  "fcmToken": "dK4X0a91L_...:APA91bFw..."
}
```
- **Response**: `200 OK`
```json
{
  "success": true,
  "message": "Device token removed"
}
```
- **Backend Logic**:
  - Delete records matching `fcm_token` for the authenticated user.

---

## 4. FCM v1 Message Payload Standard

Use Google's **FCM HTTP v1 API** (or `firebase-admin` SDK). Ensure the payload contains both a `notification` block (for system tray display) and a `data` block (for deep-linking & in-app logic).

### Standard Payload Structure:
```json
{
  "message": {
    "token": "RECIPIENT_DEVICE_FCM_TOKEN",
    "notification": {
      "title": "🎟️ Booking Confirmed!",
      "body": "Your tickets for Tech Innovators Summit 2026 are ready."
    },
    "data": {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "route": "/bookings",
      "type": "BOOKING_CONFIRMED",
      "id": "ord_849204",
      "timestamp": "1771914000"
    },
    "android": {
      "priority": "HIGH",
      "notification": {
        "channel_id": "eventsphere_high_importance",
        "sound": "default",
        "default_vibrate_timings": true,
        "default_light_settings": true,
        "click_action": "FLUTTER_NOTIFICATION_CLICK"
      }
    },
    "apns": {
      "payload": {
        "aps": {
          "alert": {
            "title": "🎟️ Booking Confirmed!",
            "body": "Your tickets for Tech Innovators Summit 2026 are ready."
          },
          "sound": "default",
          "badge": 1,
          "content-available": 1
        }
      }
    }
  }
}
```

---

## 5. Deep Linking & In-App Navigation Targets

When the user taps on the push notification banner, the Flutter app reads the `route` field in `data` and opens the corresponding screen.

| Screen Name | `route` Value | `type` Value | Extra Parameters / Notes |
| :--- | :--- | :--- | :--- |
| **Customer Bookings / Tickets** | `/bookings` | `BOOKING_CONFIRMED`, `TICKET_READY` | Opens the customer's tickets and orders list. |
| **Event Details** | `/detail/event/{eventId}` | `EVENT_UPDATE`, `EVENT_REMINDER` | e.g. `/detail/event/64f1a2b3c4d5` |
| **Package Details** | `/detail/package/{packageId}` | `PACKAGE_OFFER` | e.g. `/detail/package/pkg_101` |
| **Service Details** | `/detail/service/{serviceId}` | `SERVICE_UPDATE` | e.g. `/detail/service/srv_202` |
| **Organizer Profile** | `/organizer-profile/{organizerId}` | `NEW_EVENT_FROM_ORGANIZER` | e.g. `/organizer-profile/org_99` |
| **Host Attendee Queue** | `/host/attendees/{eventId}` | `HOST_NEW_REGISTRATION` | Host manages approval queue for registrations. |
| **Host Management Hub** | `/host/manage/{eventId}` | `HOST_EVENT_PUBLISHED` | Host event analytics & management hub. |
| **Host QR Scanner** | `/host/scanner/{eventId}` | `HOST_CHECKIN_OPEN` | Opens the QR camera scanner for entry. |
| **Organizer Booking Inbox** | `/organizer/inbox` | `ORGANIZER_NEW_BOOKING` | Organizer accepts/declines customer booking requests. |
| **Organizer Payout Ledger** | `/organizer/payouts` | `PAYOUT_TRANSFERRED` | Organizer views settlement breakdown. |
| **Events Discovery** | `/events` | `ANNOUNCEMENT` | General discovery screen. |

---

## 6. Backend Code Examples

### 6.1 Node.js / TypeScript (using `firebase-admin`)

#### Installation:
```bash
npm install firebase-admin
```

#### Initialization & Helper Service:
```typescript
import * as admin from 'firebase-admin';

// Initialize Firebase Admin (Using Service Account JSON)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

export interface PushNotificationPayload {
  token: string;
  title: string;
  body: string;
  route?: string;
  type?: string;
  id?: string;
  data?: Record<string, string>;
}

/**
 * Sends a high-priority push notification to a single mobile device.
 */
export async function sendPushNotification(payload: PushNotificationPayload) {
  const message: admin.messaging.Message = {
    token: payload.token,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: {
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      route: payload.route || '/',
      type: payload.type || 'GENERAL',
      id: payload.id || '',
      ...payload.data,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'eventsphere_high_importance',
        sound: 'default',
        priority: 'max',
        defaultVibrateTimings: true,
        defaultSound: true,
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
          contentAvailable: true,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`[FCM] Notification sent successfully: ${response}`);
    return { success: true, messageId: response };
  } catch (error: any) {
    console.error(`[FCM Error] Failed to send push:`, error);
    // If token is invalid or uninstalled, prune it from DB
    if (
      error.code === 'messaging/registration-token-not-registered' ||
      error.code === 'messaging/invalid-registration-token'
    ) {
      // TODO: Delete token from database
      console.warn(`[FCM] Token ${payload.token} is invalid or expired. Pruning from DB...`);
    }
    return { success: false, error: error.message };
  }
}

/**
 * Sends push notifications to all registered devices of a user.
 */
export async function sendPushToUser(
  userId: string,
  title: string,
  body: string,
  route: string,
  type: string,
  id?: string
) {
  // 1. Fetch all tokens for userId from your database
  const tokens = await getUserDeviceTokens(userId); // Returns string[]

  if (!tokens || tokens.length === 0) {
    console.log(`[FCM] No active device tokens found for user: ${userId}`);
    return;
  }

  // 2. Dispatch in parallel
  await Promise.all(
    tokens.map((token) =>
      sendPushNotification({
        token,
        title,
        body,
        route,
        type,
        id,
      })
    )
  );
}
```

---

### 6.2 Python (using `firebase-admin`)

#### Installation:
```bash
pip install firebase-admin
```

#### Push Service Implementation:
```python
import firebase_admin
from firebase_admin import credentials, messaging

# Initialize Firebase App
cred = credentials.Certificate("path/to/firebase-service-account.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

def send_push_notification(
    token: str,
    title: str,
    body: str,
    route: str = "/",
    notif_type: str = "GENERAL",
    entity_id: str = ""
):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data={
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "route": route,
            "type": notif_type,
            "id": entity_id,
        },
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                channel_id="eventsphere_high_importance",
                sound="default",
                priority="max",
                default_vibrate_timings=True,
                default_sound=True,
            ),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    sound="default",
                    badge=1,
                    content_available=True,
                )
            )
        ),
        token=token,
    )

    try:
        response = messaging.send(message)
        print(f"[FCM] Successfully sent message: {response}")
        return {"success": True, "message_id": response}
    except messaging.UnregisteredError:
        print(f"[FCM] Token {token} has expired/uninstalled. Remove from database.")
        # TODO: Delete token from database
        return {"success": False, "error": "Unregistered token"}
    except Exception as e:
        print(f"[FCM Error] {e}")
        return {"success": False, "error": str(e)}
```

---

## 7. Common Notification Scenarios & Event Triggers

### 1. 🎟️ Ticket Order / Booking Confirmed (To Customer)
- **Trigger**: Payment succeeds / Order placed.
- **Title**: `🎉 Tickets Confirmed!`
- **Body**: `You are going to {eventName}! Tap to view your QR ticket.`
- **Route**: `/bookings`
- **Type**: `BOOKING_CONFIRMED`

### 2. 📋 New Booking Request (To Organizer)
- **Trigger**: Customer books a service or package.
- **Title**: `📥 New Booking Request`
- **Body**: `{customerName} has requested a booking for {serviceName}.`
- **Route**: `/organizer/inbox`
- **Type**: `ORGANIZER_NEW_BOOKING`

### 3. 👤 New Attendee Registration (To Host)
- **Trigger**: User registers for a host's event.
- **Title**: `👥 New Attendee Registered`
- **Body**: `{attendeeName} registered for {eventName}.`
- **Route**: `/host/attendees/{eventId}`
- **Type**: `HOST_NEW_REGISTRATION`

### 4. 💰 Payout Processed (To Organizer)
- **Trigger**: Admin or automated cron settles organizer payout.
- **Title**: `💸 Payout Sent!`
- **Body**: `₹{amount} has been processed and transferred to your bank account.`
- **Route**: `/organizer/payouts`
- **Type**: `PAYOUT_TRANSFERRED`

### 5. ⏰ Event Reminder 24 Hours / 1 Hour Prior (To Attendee)
- **Trigger**: Scheduled cron job.
- **Title**: `⏰ Upcoming Event Tomorrow!`
- **Body**: `{eventName} starts at {eventTime} at {venueLocation}.`
- **Route**: `/detail/event/{eventId}`
- **Type**: `EVENT_REMINDER`

### 6. 💳 Refund Processed (To Customer)
- **Trigger**: Ticket or booking cancellation approved.
- **Title**: `🔄 Refund Processed`
- **Body**: `A refund of ₹{amount} has been initiated for booking #{bookingId}.`
- **Route**: `/bookings`
- **Type**: `REFUND_PROCESSED`

---

## 8. Testing & cURL Commands

You can test pushing a notification directly from the command line using Google OAuth2 Bearer token with the FCM v1 HTTP endpoint.

### Step 1: Obtain Google OAuth2 Access Token
Using Google Cloud CLI (`gcloud`):
```bash
gcloud auth application-default print-access-token
```

### Step 2: Execute cURL Request
```bash
curl -X POST https://fcm.googleapis.com/v1/projects/<YOUR_FIREBASE_PROJECT_ID>/messages:send \
  -H "Authorization: Bearer <GCLOUD_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "<TARGET_DEVICE_FCM_TOKEN>",
      "notification": {
        "title": "🎉 Test Notification from Backend",
        "body": "Firebase push notification pipeline is working flawlessly!"
      },
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "route": "/bookings",
        "type": "BOOKING_CONFIRMED",
        "id": "test_123"
      },
      "android": {
        "priority": "HIGH",
        "notification": {
          "channel_id": "eventsphere_high_importance",
          "sound": "default"
        }
      },
      "apns": {
        "payload": {
          "aps": {
            "sound": "default",
            "badge": 1
          }
        }
      }
    }
  }'
```

---

## 9. Important Developer Notes & Troubleshooting

1. **All Data Payload Fields Must Be Strings**:
   - ❌ Invalid: `"data": { "id": 123, "approved": true }`
   - ✅ Valid: `"data": { "id": "123", "approved": "true" }`
2. **Channel ID Match**:
   - If the `channel_id` is omitted or does not match `eventsphere_high_importance`, Android will not display heads-up alerts when the app is in the background.
3. **Invalid / Expired Tokens (`UNREGISTERED`)**:
   - Whenever FCM returns `messaging/registration-token-not-registered` or `UnregisteredError`, immediately delete that `fcm_token` from your database to prevent redundant API calls.
