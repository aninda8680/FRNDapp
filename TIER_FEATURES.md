# Tier Features & Subscription Breakdown — FRND Backend

This document details the complete feature matrix, quota limits, capabilities, and system rules for all three user tiers (**Free Tier**, **Silver Pass**, and **Gold Pass**) across the FRND platform.

---

## Executive Summary & Comparison Matrix

| Feature / Limit | 🆓 Free Tier | 🥈 Silver Pass | 🥇 Gold Pass |
| :--- | :---: | :---: | :---: |
| **Price & Billing** | **₹0** (Free Forever) | **₹39** / 28 days (Autopay) | **₹49** / 28 days (Autopay) |
| **Daily Likes Quota** | **15** likes / day | **25** likes / day | **50** likes / day |
| **Daily Superlikes Quota** | **3** superlikes / day | **6** superlikes / day | **12** superlikes / day |
| **Discovery Feed Priority** | Baseline (1x Boost) | High Priority (3x Boost) | Maximum Priority (6x Boost) |
| **"Who Liked Me" Profiles** | 🔒 **Locked** (Count Only) | 🔓 **Unlocked** (Full Profiles) | 🔓 **Unlocked** (Full Profiles) |
| **Anonymous Posts / 24h** | **1** post / 24 hours | **3** posts / 24 hours | **6** posts / 24 hours |
| **Post Word Limit** | **250** words / post | **400** words / post | **900** words / post |
| **Custom Card Themes** | ❌ Default Only | ❌ Default Only | 👑 **Exclusive** (`customDesignId`) |
| **Autopay Renewal** | N/A | Automated (28-day cycle) | Automated (28-day cycle) |

---

## Detailed Tier Breakdown

### 1. 🆓 Free Tier (Default)
The standard experience for all newly registered users and users with expired subscriptions.

* **Cost & Billing**: ₹0 — No credit card or subscription required.
* **Daily Likes Quota**: **15 likes / 24 hours** (resets UTC midnight).
* **Daily Superlikes Quota**: **3 superlikes / 24 hours** (resets UTC midnight).
* **Discovery Feed Ranking**: Baseline (1x boost multiplier). Standard feed placement based on basic recommendation scoring.
* **"Who Liked Me" (Received Likes)**: 
  * **Locked/Hidden**. 
  * Free users can see the **total count** of people who liked them (`totalLikesCount`).
  * Full liker profile cards are obfuscated/hidden (`likers: []`, `hasAccess: false`, `isLocked: true`).
* **Anonymous Posts & Confessions**:
  * **Post Quota**: **1 post / 24 hours**.
  * **Word Limit**: **250 words** per post.
* **Custom Profile Design Themes**:
  * **Disabled** (`customDesignId: null`).
  * Attempting to set a custom card theme ID returns `403 Forbidden`.

---

### 2. 🥈 Silver Pass (Autopay Subscription)
The mid-tier subscription designed for active campus socializers wanting higher daily limits and full visibility into incoming likes.

* **Cost & Billing**: **₹39 / 28 days** (Automated recurring subscription via Razorpay Autopay).
* **Daily Likes Quota**: **25 likes / 24 hours** (resets UTC midnight).
* **Daily Superlikes Quota**: **6 superlikes / 24 hours** (resets UTC midnight).
* **Discovery Feed Ranking**: **3x Boost Multiplier** (+3,000 score bump in discovery algorithm). Profile appears significantly earlier in candidate feeds.
* **"Who Liked Me" (Received Likes)**: 
  * 🔓 **UNLOCKED**.
  * Complete access to view all full profiles, pictures, bios, and timestamps of users who liked or superliked them (`hasAccess: true`, `isLocked: false`).
* **Anonymous Posts & Confessions**:
  * **Post Quota**: **3 posts / 24 hours**.
  * **Word Limit**: **400 words** per post (enough for detailed confessions or stories).
* **Custom Profile Design Themes**:
  * **Disabled** (`customDesignId: null`).
  * Reserved exclusively for Gold tier.
* **Subscription Management**:
  * Auto-renews every 28 days via Razorpay webhooks (`subscription.charged`).
  * If payment fails or is halted (`subscription.halted`), tier automatically reverts to `free`.

---

### 3. 🥇 Gold Pass (Autopay Subscription)
The top-tier premium experience offering maximum daily limits, maximum discovery priority, long-form posting, and exclusive custom profile themes.

* **Cost & Billing**: **₹49 / 28 days** (Automated recurring subscription via Razorpay Autopay).
* **Daily Likes Quota**: **50 likes / 24 hours** (resets UTC midnight).
* **Daily Superlikes Quota**: **12 superlikes / 24 hours** (resets UTC midnight).
* **Discovery Feed Ranking**: **6x Boost Multiplier** (+6,000 score bump in discovery algorithm). Top-tier priority placement across discovery feeds.
* **"Who Liked Me" (Received Likes)**: 
  * 🔓 **UNLOCKED**.
  * Instant full profile access to all incoming likes and superlikes.
* **Anonymous Posts & Confessions**:
  * **Post Quota**: **6 posts / 24 hours**.
  * **Word Limit**: **900 words** per post (room for actual long-form writing, advice threads, and detailed stories).
* **Custom Profile Design Themes**:
  * 👑 **EXCLUSIVE & UNLOCKED**.
  * Gold users can claim, set, or update custom profile card theme IDs (`customDesignId`) via `PUT /api/users/me/design` or `PUT /api/users/me`.
  * The custom card theme is publicly rendered to all other users across `/discover`, `/matches`, `/likes/received`, `/likes/given`, and `/posts`.
  * If Gold subscription expires, the theme gracefully falls back to default (`null`) across all public feeds while preserving their saved preference.
* **Subscription Management**:
  * Auto-renews every 28 days via Razorpay webhooks (`subscription.charged`).
  * Instant access activation upon signature verification (`POST /api/payments/verify-subscription`).

---

## Technical Implementation & Enforcement

### 1. Active Subscription Validation
In Node.js routes, active subscription status is determined dynamically:
```javascript
const now = new Date();
const isSubActive = user.tier && user.tier !== 'free' && (!user.subscriptionExpiresAt || new Date(user.subscriptionExpiresAt) > now);
const activeTier = isSubActive ? user.tier : 'free';
```

### 2. Quota Enforcement Architecture
* **Likes & Superlikes**: Counter tracked in Upstash Redis (`user:{id}:likes` and `user:{id}:superlikes`) with UTC midnight auto-expiration (`EXPIREAT`).
* **Anonymous Post Creation**: Enforced via 24-hour MongoDB range query on `AnonymousPost` collection (`createdAt: { $gte: twentyFourHoursAgo }`).
* **Word Limit Validation**: Verified on `POST /api/posts` using space-delimited string word counting (`content.trim().split(/\s+/).filter(Boolean).length`).

---

## Summary Table for Quick Reference

| Action / Endpoint | Free | Silver | Gold |
|---|:---:|:---:|:---:|
| `POST /api/like/:targetId` | 15 / day | 25 / day | 50 / day |
| `POST /api/superlike/:targetId` | 3 / day | 6 / day | 12 / day |
| `GET /api/likes/received` | Count Only | Full Profiles | Full Profiles |
| `POST /api/posts` (Quota) | 1 / 24h | 3 / 24h | 6 / 24h |
| `POST /api/posts` (Word Limit) | 250 words | 400 words | 900 words |
| `PUT /api/users/me/design` | ❌ 403 Forbidden | ❌ 403 Forbidden | ✅ Allowed |
| Discovery Feed Boost | 1x Multiplier | 3x Multiplier | 6x Multiplier |
