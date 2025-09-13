# Social / Friends System

This document describes the database schema and client patterns for the **friends** and **contact discovery** features.

---

## 📊 Schema Overview

| Table | Purpose | Key Columns |
|------|--------|--------------|
| **profiles** | User profiles (existing) | `id` (PK → `auth.users.id`), `username`, `full_name`, `avatar_url`, `website`, `updated_at` |
| **friendships** | Friend relationships & requests | `id`, `user_id` *(requester)*, `friend_id` *(recipient)*, `status` (`pending` \| `accepted`), `created_at`, `updated_at` |
| **profile_identities** | Verified hashed identifiers (email/phone) for contact discovery | `profile_id`, `kind` (`email`\|`phone`), `hash_hex`, `verified` |
| **user_contacts** | Caller’s uploaded contact hashes for matching | `owner_id`, `kind`, `hash_hex` |

**Indexes & Constraints**

* `friendships_pair_unique` – one row per unordered pair.
* `no_self_friend` – prevents self-friendship.
* Triggers update `updated_at` and enforce valid status transitions.

---

## 🔐 Row-Level Security (RLS)

| Action | Who | Table |
|-------|----|------|
| **SELECT** friendships | Requester or recipient | `friendships` |
| **INSERT** friendships | Requester only | `friendships` |
| **UPDATE** friendships | Recipient only | `friendships` |
| **DELETE** friendships | Either party | `friendships` |
| **SELECT / INSERT / DELETE** user_contacts | Owner only | `user_contacts` |
| profile_identities | **No direct access** – used only through RPCs |

---

## 🔄 Status Flow

1. **Request** – requester inserts a row with `status = 'pending'`.
2. **Accept** – recipient updates the same row, setting `status = 'accepted'`.
3. **Cancel / Unfriend** – either side deletes the row.

A trigger enforces that status can only move `pending → accepted` or remain unchanged.

---

## 🧩 RPC Functions

| Function | Purpose | Notes |
|----------|--------|------|
| `get_mutual_friends(other_id uuid)` | List mutual friends with another user (only if you are friends). Returns `friend_id`, `username`, `avatar_url`. |
| `get_mutual_friends_count(other_id uuid)` | Count mutual friends. |
| `is_accepted_friend(a uuid, b uuid)` | Boolean check for friendship (internal use). |
| `add_verified_email(email_raw text)` | Hash and store caller’s verified email for discovery. |
| `add_verified_phone(phone_raw text)` | Hash and store caller’s verified phone. |
| `find_contact_matches()` | Return platform users who match the caller’s uploaded contact hashes (excludes existing friends). |

---

## 💻 Swift / Supabase Usage

### Add Supabase to your Swift project

Use [supabase-community/supabase-swift](https://github.com/supabase-community/supabase-swift) (Swift Package Manager).

```swift
import Supabase

let client = SupabaseClient(
    supabaseURL: URL(string: "https://YOUR-PROJECT.supabase.co")!,
    supabaseKey: "YOUR_ANON_KEY"
)