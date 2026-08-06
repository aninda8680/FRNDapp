# Push Notification Triggers Analysis

Based on my analysis of the API services and app features (like Discover, Chat, Posts, and Announcements), here is a comprehensive breakdown of exactly where and when FCM push notifications should be triggered by your backend.

## 1. Matching & Swiping (Discover / Matches Service)
These are the most critical notifications to drive engagement in a dating app.
* **New Like:** Triggered when User A calls `likeProfile(UserB)`. User B should receive a notification that someone liked them (often obfuscated to encourage upgrading, e.g., *"Someone new liked you! Swipe to find out who."*).
* **New Superlike:** Triggered when User A calls `superlikeProfile(UserB)`. User B receives *"Someone Superliked you! You stand out."*
* **New Match:** Triggered when a `likeProfile` or `superlikeProfile` returns `{matchFormed: true}`. Both User A and User B should receive *"You have a new match with [Name]! Say hi."* (With a deep link payload directly to the chat).

## 2. Real-Time Chat (Chat Service)
* **New Direct Message:** Triggered when a new chat message is sent. The receiver gets *"New message from [Name]: '...'"*. (With a deep link payload `{ type: "chat", chatId: "..." }` to open that specific conversation).
* **Missed Call / Audio-Video (If Applicable):** If your real-time chat expands to WebRTC, notifications for missed calls are vital.

## 3. Social Feed / Posts (Post Service)
Posts are anonymous by default, but engagement notifications still pull users back in.
* **Post Upvoted:** When someone calls `upvotePost(postId)`, the author of the post receives *"Your anonymous post just got an upvote!"* (Usually batched or delayed so they don't get spammed for every single vote).
* **New Comment (If added):** If a comment endpoint is added later, the author gets *"Someone commented on your post."*

## 4. System & Admin (Announcement Service)
* **Global Announcements:** When admins push a new record to the announcements collection, a broadcast FCM topic message should be sent to all users (e.g., *"Scheduled Maintenance tonight"* or *"Check out our new features!"*).

## 5. Payments & Quota (Payment Service / Auth)
* **Successful Purchase/Upgrade:** When Razorpay/Stripe webhooks succeed for pass purchases or subscriptions, notify the user: *"Your payment was successful! You have 5 new Superlikes."*
* **Quota Refill Reminder (Optional):** A scheduled backend chron-job that sends a push to users at midnight (or 24h since exhaustion): *"Your daily likes have been refilled! Start swiping."*

## 6. Retention / Lifecycle (Backend Scheduled)
* **Inactive User:** If a user hasn't opened the app in 3-7 days, a scheduled notification like *"You have missed connections waiting for you!"* can boost retention.

---

### Backend Implementation Note
To make this work seamlessly, your backend code (Node.js/Python) will need to watch these specific API routes or database events. Every time one of these events occurs, the backend will fetch the recipient's FCM token (which we are now successfully syncing on login) and dispatch the payload via the Firebase Admin SDK.
