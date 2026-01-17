# TheCoffeeLinks - Complete Backend Guide for Client App

> **Last Updated:** January 2026  
> **API Version:** v1  
> **Base URL:** `https://server-nu-three-90.vercel.app/`

This comprehensive guide documents all backend APIs, database schemas, and integration patterns for the TheCoffeeLinks iOS/Swift client application.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Authentication](#2-authentication)
3. [Menu & Products](#3-menu--products)
4. [Orders](#4-orders)
5. [Delivery](#5-delivery)
6. [User Management](#6-user-management)
7. [Social Features](#7-social-features)
8. [Vouchers & Rewards](#8-vouchers--rewards)
9. [Stores](#9-stores)
10. [Database Schema Reference](#10-database-schema-reference)
11. [Error Handling](#11-error-handling)
12. [Security](#12-security)
13. [Best Practices](#13-best-practices)

---

## 1. Overview

### 1.1 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    iOS Client (Swift)                            │
│         NetworkService → Repositories → ViewModels               │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS / WSS
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Next.js API Server                            │
│                 /api/* Route Handlers                            │
├─────────────────────────────────────────────────────────────────┤
│                    Supabase Backend                              │
│         PostgreSQL + Auth + Storage + Realtime                   │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Request Format

**Headers:**
```http
Authorization: Bearer <accessToken>
Content-Type: application/json
Accept: application/json
User-Agent: TheCoffeeLinks-iOS/1.0
```

**JSON Naming Convention:**  
- API uses `snake_case` for all field names
- Client auto-converts to `camelCase`

**Date Format:**  
ISO 8601 with optional fractional seconds:
```
2026-01-15T10:30:00Z
2026-01-15T10:30:00.123Z
```

### 1.3 Response Format

All responses follow this structure:

```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message"
}
```

Or for entity-specific responses:
```json
{
  "success": true,
  "order": { ... }
}
```

---

## 2. Authentication

### 2.1 Login

**Email/Password Login**
```http
POST /api/auth/login
```

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "success": true,
  "session": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "v1.MGRjY2...",
    "expires_at": "2026-01-15T11:30:00Z",
    "expires_in": 3600,
    "token_type": "bearer"
  },
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "Nguyen Van A",
    "avatar_url": "https://..."
  }
}
```

---

### 2.2 Token Refresh

```http
POST /api/auth/refresh
```

**Request:**
```json
{
  "refresh_token": "v1.MGRjY2..."
}
```

**Response:** New session object.

---

### 2.3 Registration

```http
POST /api/auth/register
```

**Request:**
```json
{
  "email": "newuser@example.com",
  "password": "securePassword123",
  "full_name": "Nguyen Van B",
  "phone": "+84901234567"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User created successfully",
  "user": { ... }
}
```

> **Note:** New users receive 50 bonus points upon registration.

---

### 2.4 Logout

```http
POST /api/auth/logout
```

> Client-side token clear. No body required.

---

### 2.5 LinkedIn Authentication

**LinkedIn OAuth Login**
```http
POST /api/auth/linkedin
```

**Request:**
```json
{
  "code": "linkedin_authorization_code",
  "redirect_uri": "https://server-nu-three-90.vercel.app/auth/callback"
}
```

**Required Fields:**
- `code`: Authorization code from LinkedIn OAuth flow
- `redirect_uri`: Must match the redirect URI configured in LinkedIn app

**Response (200):**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "John Doe",
    "avatar_url": "https://media.licdn.com/...",
    "is_new_user": true
  },
  "auth_url": "https://server-nu-three-90.vercel.app/auth/confirm?token=...",
  "message": "Use auth_url to complete authentication"
}
```

**Client Integration Steps:**
1. Redirect user to LinkedIn OAuth URL with required scopes (`openid`, `profile`, `email`)
2. Receive authorization code in callback
3. POST to `/api/auth/linkedin` with code and redirect_uri
4. Use the returned `auth_url` to complete authentication (contains session tokens)
5. Extract and store access/refresh tokens from the auth_url

**Features:**
- OpenID Connect integration
- Automatic account linking by email
- New user creation with 50 bonus points
- Profile data extraction (name, email, avatar)

---

### 2.6 Session Validation

**Validate Current Session**
```http
GET /api/auth/session
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "valid": true,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "John Doe"
  }
}
```

**Response (401):**
```json
{
  "valid": false,
  "error": "Invalid session"
}
```

**Use Cases:**
- Check if current token is still valid
- Get updated user information
- Verify authentication state

---

## 3. Menu & Products

### 3.1 Get Full Menu

Retrieves everything in one call for efficient caching.

```http
GET /api/menu
```

**Response (200):**
```json
{
  "categories": [
    {
      "id": "uuid",
      "name": "Coffee",
      "type": "coffee",
      "display_order": 1
    }
  ],
  "products": [
    {
      "id": "uuid",
      "name": "Cà Phê Sữa Đá",
      "description": "Traditional Vietnamese iced milk coffee",
      "image": "https://storage.../products/caphe.webp",
      "category_id": "uuid",
      "category_name": "Coffee",
      "size_options": {
        "small": { "enabled": false, "price": 0 },
        "medium": { "enabled": true, "price": 45000 },
        "large": { "enabled": true, "price": 55000 }
      },
      "available_toppings": ["uuid1", "uuid2", "uuid3"],
      "is_available": true,
      "is_deliverable": true,
      "best_in_store": false,
      "delivery_notes": null,
      "created_at": "2026-01-01T00:00:00Z"
    }
  ],
  "toppings": [
    {
      "id": "uuid",
      "name": "Extra Shot",
      "price": 15000,
      "is_available": true
    }
  ]
}
```

> **Cache TTL:** 5 minutes recommended

---

### 3.2 Get Products

```http
GET /api/products
GET /api/products?category_id=uuid
GET /api/products?search=coffee
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `category_id` | UUID | Filter by category |
| `search` | string | Search by name |
| `is_available` | boolean | Filter available only |
| `is_deliverable` | boolean | Filter deliverable only |

---

### 3.3 Get Single Product

```http
GET /api/products/{productId}
```

**Response:** Single product object with full details.

---

### 3.4 Popular Products

```http
GET /api/products/popular
GET /api/products/popular?period=24h&limit=5
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `period` | string | `24h` | `24h` or `7d` |
| `limit` | number | 3 | Max products to return |
| `store_id` | UUID | - | Filter by store (optional) |

**Response:**
```json
{
  "success": true,
  "popular_products": [
    {
      "product_id": "uuid",
      "name": "Cà Phê Sữa Đá",
      "order_count": 42,
      "image": "https://..."
    }
  ],
  "cached_at": "2026-01-15T10:25:00Z"
}
```

> **Cache:** Results cached for 5 minutes

---

### 3.5 Categories

```http
GET /api/categories
```

**Response:**
```json
{
  "success": true,
  "categories": [
    {
      "id": "uuid",
      "name": "Coffee",
      "type": "coffee"
    },
    {
      "id": "uuid",
      "name": "Tea",
      "type": "tea"
    }
  ]
}
```

---

### 3.6 Toppings

```http
GET /api/toppings
```

**Response:**
```json
{
  "success": true,
  "toppings": [
    {
      "id": "uuid",
      "name": "Extra Shot",
      "price": 15000,
      "is_available": true
    },
    {
      "id": "uuid",
      "name": "Vanilla Syrup",
      "price": 12000,
      "is_available": true
    }
  ]
}
```

**Available Toppings:**
| Topping | Price (VND) |
|---------|-------------|
| Extra Shot | 15,000 |
| Vanilla/Hazelnut/Caramel Syrup | 12,000 |
| Coconut/Almond/Oat Milk | 18,000 |
| Whipped Cream | 15,000 |
| Chocolate/Caramel Drizzle | 10,000 |
| Cinnamon | 5,000 |
| Honey | 8,000 |

---

## 4. Orders

### 4.1 Create Order

```http
POST /api/orders
Authorization: Bearer <token>
```

**Request:**
```json
{
  "store_id": "uuid",
  "delivery_option": "pickup",
  "payment_method": "apple_pay",
  "source": "manual",
  "items": [
    {
      "product_id": "uuid",
      "quantity": 2,
      "size": "large",
      "toppings": [
        {
          "id": "uuid",
          "name": "Extra Shot",
          "price": 15000
        }
      ],
      "notes": ["Less ice", "Extra hot"],
      "is_favorite": false
    }
  ],
  "voucher_code": "SAVE20",
  "notes": "Please call when arriving",
  "delivery_address_id": "uuid"
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `store_id` | UUID | Yes | Target store |
| `delivery_option` | string | Yes | `pickup`, `dine_in`, `delivery` |
| `payment_method` | string | Yes | `apple_pay`, `card`, `momo`, `zalopay`, `cash` |
| `source` | string | No | `manual`, `ai_suggested`, `reorder`, `favorite` |
| `items` | array | Yes | Order items |
| `voucher_code` | string | No | Applied voucher |
| `notes` | string | No | Order notes |
| `delivery_address_id` | UUID | Conditional | Required if delivery |
| `table_id` | string | Conditional | Required if dine_in |

**Item Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `product_id` | UUID | Yes | Product ID |
| `quantity` | number | Yes | Quantity (min: 1) |
| `size` | string | Yes | `small`, `medium`, `large` |
| `toppings` | array | No | Selected toppings |
| `notes` | string[] | No | Max 3 notes, 140 chars each |
| `is_favorite` | boolean | No | Ordered from favorites |

**Response (201):**
```json
{
  "success": true,
  "order": {
    "id": "uuid",
    "status": "pending",
    "pending_until": "2026-01-15T10:30:30Z",
    "undo_available": true,
    "total_amount": 145000,
    "subtotal": 140000,
    "delivery_fee": 0,
    "discount": 0,
    "items": [ ... ],
    "created_at": "2026-01-15T10:30:00Z"
  },
  "message": "Order placed! You have 30 seconds to cancel."
}
```

---

### 4.2 Order Undo Window

> **Critical Feature:** Orders have a 30-second undo window

When an order is created:
- Status is `pending` for 30 seconds
- `pending_until` shows when window expires
- After 30s, status auto-changes to `placed`
- Only `pending` orders can be cancelled without penalty

---

### 4.3 Cancel Order

```http
POST /api/orders/{orderId}/cancel
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Order cancelled successfully",
  "refund_status": "processed"
}
```

**Cancel Restrictions:**
- Within 30s (pending): Always allowed
- After 30s: Only if `preparing` not started
- Delivery in transit: Not allowed

---

### 4.4 Undo Cancellation

```http
POST /api/orders/{orderId}/undo-cancel
Authorization: Bearer <token>
```

> Only works if cancelled within undo window and window hasn't expired.

---

### 4.5 Get Orders

```http
GET /api/orders
GET /api/orders?status=placed&limit=10&offset=0
Authorization: Bearer <token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status |
| `limit` | number | Max results (default: 20) |
| `offset` | number | Pagination offset |

**Response:**
```json
{
  "success": true,
  "orders": [
    {
      "id": "uuid",
      "status": "placed",
      "delivery_option": "pickup",
      "total_amount": 145000,
      "items_count": 3,
      "store": {
        "id": "uuid",
        "name": "42 Trần Vỹ"
      },
      "created_at": "2026-01-15T10:30:00Z"
    }
  ],
  "total": 50,
  "has_more": true
}
```

---

### 4.6 Get Active Orders

```http
GET /api/orders/active
Authorization: Bearer <token>
```

Returns orders with status: `pending`, `placed`, `preparing`, `ready`, `delivering`

---

### 4.7 Get Single Order

```http
GET /api/orders/{orderId}
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "order": {
    "id": "uuid",
    "status": "preparing",
    "delivery_option": "pickup",
    "payment_method": "apple_pay",
    "payment_status": "paid",
    "source": "reorder",
    "total_amount": 145000,
    "subtotal": 145000,
    "delivery_fee": 0,
    "discount": 0,
    "store": {
      "id": "uuid",
      "name": "42 Trần Vỹ",
      "address": "42 Trần Vỹ, Cầu Giấy"
    },
    "items": [
      {
        "id": "uuid",
        "product_id": "uuid",
        "product_name": "Cà Phê Sữa Đá",
        "quantity": 2,
        "size": "large",
        "price": 55000,
        "final_price": 140000,
        "toppings": [
          { "name": "Extra Shot", "price": 15000 }
        ],
        "notes": ["Less ice"]
      }
    ],
    "notes": "Please call when arriving",
    "created_at": "2026-01-15T10:30:00Z",
    "updated_at": "2026-01-15T10:32:00Z"
  }
}
```

---

### 4.8 Order Preview (Price Calculation)

```http
POST /api/orders/preview
Authorization: Bearer <token>
```

**Request:** Same as create order

**Response:**
```json
{
  "success": true,
  "preview": {
    "subtotal": 140000,
    "delivery_fee": 25000,
    "discount": 28000,
    "voucher_applied": "SAVE20",
    "total_amount": 137000,
    "estimated_time": 15
  }
}
```

---

### 4.9 Order Status Values

| Status | Description | Can Cancel |
|--------|-------------|------------|
| `pending` | Just created (30s window) | ✅ Yes |
| `placed` | Confirmed, waiting prep | ⚠️ Maybe |
| `preparing` | Being prepared | ❌ No |
| `ready` | Ready for pickup | ❌ No |
| `delivering` | Out for delivery | ❌ No |
| `completed` | Fulfilled | ❌ No |
| `cancelled` | Cancelled | N/A |

---

## 5. Delivery

### 5.1 Get User Addresses

```http
GET /api/addresses
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "addresses": [
    {
      "id": "uuid",
      "label": "Home",
      "full_address": "123 Nguyễn Trãi, Thanh Xuân, Hà Nội",
      "latitude": 21.0045,
      "longitude": 105.8234,
      "is_default": true,
      "delivery_notes": "Gate code: 1234",
      "usage_count": 15
    }
  ]
}
```

> **Limit:** Maximum 10 addresses per user

---

### 5.2 Save Address

```http
POST /api/addresses
Authorization: Bearer <token>
```

**Request:**
```json
{
  "label": "Office",
  "full_address": "Tower A, 123 Phạm Hùng, Nam Từ Liêm",
  "latitude": 21.0289,
  "longitude": 105.7822,
  "delivery_notes": "Floor 15, Ring bell on arrival",
  "is_default": false
}
```

---

### 5.3 Update Address

```http
PUT /api/addresses/{addressId}
Authorization: Bearer <token>
```

---

### 5.4 Delete Address

```http
DELETE /api/addresses/{addressId}
Authorization: Bearer <token>
```

---

### 5.5 Set Default Address

```http
PUT /api/addresses/{addressId}/default
Authorization: Bearer <token>
```

> Only one default address allowed. Setting new default unsets previous.

---

### 5.6 Check Delivery Availability

```http
GET /api/delivery/availability?store_id=uuid&latitude=21.0045&longitude=105.8234
```

**Response:**
```json
{
  "success": true,
  "available": true,
  "zone": {
    "id": "uuid",
    "name": "Zone A - Standard",
    "base_fee": 15000,
    "estimated_minutes": 25
  },
  "delivery_fee": 22000,
  "eta_minutes": 30,
  "surge_active": false,
  "surge_multiplier": 1.0,
  "min_order_amount": 50000
}
```

**If not available:**
```json
{
  "success": true,
  "available": false,
  "reason": "Address is outside delivery range"
}
```

---

### 5.7 Get Delivery Zones

```http
GET /api/delivery/zones?store_id=uuid
```

**Response:**
```json
{
  "success": true,
  "zones": [
    {
      "id": "uuid",
      "name": "Zone A - Free Delivery",
      "base_fee": 0,
      "per_km_fee": 0,
      "max_distance_km": 3,
      "min_order_amount": 100000,
      "estimated_minutes_base": 20
    },
    {
      "id": "uuid",
      "name": "Zone B - Standard",
      "base_fee": 15000,
      "per_km_fee": 3000,
      "max_distance_km": 7,
      "min_order_amount": 50000,
      "estimated_minutes_base": 30
    }
  ]
}
```

---

### 5.8 Track Delivery

```http
GET /api/delivery/tracking/{orderId}
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "tracking": {
    "order_id": "uuid",
    "status": "delivering",
    "driver": {
      "name": "Nguyễn Văn Driver",
      "phone": "+84901234567"
    },
    "estimated_arrival": "2026-01-15T11:00:00Z",
    "current_location": {
      "latitude": 21.0123,
      "longitude": 105.8345
    },
    "updates": [
      {
        "status": "out_for_delivery",
        "timestamp": "2026-01-15T10:45:00Z"
      }
    ]
  }
}
```

---

## 6. User Management

### 6.1 Get Current User

```http
GET /api/users/me
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "Nguyễn Văn A",
    "phone": "+84901234567",
    "avatar_url": "https://storage.../avatars/user.webp",
    "points": 1500,
    "tier": "gold",
    "total_orders": 45,
    "member_since": "2025-06-15T00:00:00Z"
  }
}
```

---

### 6.2 Update Profile

```http
PUT /api/users/me
Authorization: Bearer <token>
```

**Request:**
```json
{
  "full_name": "Nguyễn Văn A Updated",
  "phone": "+84909876543"
}
```

---

### 6.3 Update Preferences

```http
PUT /api/users/me/preferences
Authorization: Bearer <token>
```

**Request:**
```json
{
  "notification_orders": true,
  "notification_promotions": true,
  "notification_social": true,
  "default_store_id": "uuid",
  "language": "vi"
}
```

---

### 6.4 Favorites

**Get Favorites:**
```http
GET /api/favorites
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "favorites": [
    {
      "id": "uuid",
      "product_id": "uuid",
      "product_name": "Cà Phê Sữa Đá",
      "customization": {
        "size": "large",
        "sugar": "50%",
        "ice": "less",
        "toppings": [
          { "id": "uuid", "name": "Extra Shot" }
        ]
      },
      "display_order": 1
    }
  ]
}
```

**Add Favorite:**
```http
POST /api/favorites
```

**Request:**
```json
{
  "product_id": "uuid",
  "customization": {
    "size": "large",
    "sugar": "50%",
    "ice": "less",
    "toppings": ["uuid1"]
  }
}
```

**Update Favorite:**
```http
PUT /api/favorites/{favoriteId}
```

**Delete Favorite:**
```http
DELETE /api/favorites/{favoriteId}
```

**Reorder Favorites:**
```http
PUT /api/favorites/reorder
```

**Request:**
```json
{
  "order": ["uuid3", "uuid1", "uuid2"]
}
```

---

## 7. Social Features

### 7.1 Store Check-in

**Check In:**
```http
POST /api/presence/check-in
Authorization: Bearer <token>
```

**Request:**
```json
{
  "store_id": "uuid",
  "mode": "open"
}
```

| Mode | Description |
|------|-------------|
| `open` | Visible to others, available for networking |
| `focus` | Private, focused work mode |

**Check Out:**
```http
POST /api/presence/check-out
Authorization: Bearer <token>
```

**Update Status:**
```http
PUT /api/presence/status
Authorization: Bearer <token>
```

**Request:**
```json
{
  "mode": "focus"
}
```

---

### 7.2 Discover People at Store

```http
GET /api/presence?store_id=uuid
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "users": [
    {
      "id": "uuid",
      "full_name": "Trần Văn B",
      "avatar_url": "https://...",
      "headline": "Product Manager @ StartupX",
      "mode": "open",
      "entered_at": "2026-01-15T09:30:00Z"
    }
  ],
  "total_at_store": 15
}
```

> **Note:** Only shows users in `open` mode. Respects block list.

---

### 7.3 Connections

**Send Connection Request:**
```http
POST /api/connections/request
Authorization: Bearer <token>
```

**Request:**
```json
{
  "user_id": "uuid",
  "message": "Hi! Would love to connect over coffee."
}
```

> **Rate Limit:** Max 10 requests per hour

**Get Connections:**
```http
GET /api/connections
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "connections": {
    "accepted": [
      {
        "id": "uuid",
        "user": { ... },
        "connected_at": "2026-01-10T00:00:00Z"
      }
    ],
    "pending_sent": [ ... ],
    "pending_received": [ ... ]
  }
}
```

**Respond to Request:**
```http
POST /api/connections/{connectionId}/respond
Authorization: Bearer <token>
```

**Request:**
```json
{
  "action": "accept"
}
```

Actions: `accept`, `decline`

---

### 7.4 Block & Report

**Block User:**
```http
POST /api/users/block
Authorization: Bearer <token>
```

**Request:**
```json
{
  "user_id": "uuid",
  "reason": "harassment"
}
```

Reasons: `spam`, `harassment`, `inappropriate`, `other`

**Unblock User:**
```http
DELETE /api/users/block/{userId}
Authorization: Bearer <token>
```

**Report User:**
```http
POST /api/users/report
Authorization: Bearer <token>
```

**Request:**
```json
{
  "user_id": "uuid",
  "reason": "inappropriate",
  "description": "Sent inappropriate messages"
}
```

> **Note:** Reporting automatically blocks the user.

---

### 7.5 Coffee Treats

**Send Treat:**
```http
POST /api/treats
Authorization: Bearer <token>
```

**Request:**
```json
{
  "recipient_id": "uuid",
  "product_id": "uuid",
  "message": "Coffee's on me! Great meeting you."
}
```

**Claim Treat:**
```http
POST /api/treats/{treatId}/claim
Authorization: Bearer <token>
```

---

## 8. Vouchers & Rewards

### 8.1 Get Available Vouchers

```http
GET /api/vouchers
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "vouchers": [
    {
      "id": "uuid",
      "code": "SAVE20",
      "type": "percent",
      "discount_percent": 20,
      "min_order_amount": 100000,
      "max_discount_amount": 50000,
      "expiry_date": "2026-02-01T23:59:59Z",
      "description": "20% off orders over 100k"
    }
  ]
}
```

---

### 8.2 Validate Voucher

```http
GET /api/vouchers/validate?code=SAVE20&subtotal=150000&mode=pickup
Authorization: Bearer <token>
```

**Response (Valid):**
```json
{
  "success": true,
  "valid": true,
  "voucher": {
    "code": "SAVE20",
    "type": "percent",
    "discount_percent": 20
  },
  "calculated_discount": 30000,
  "message": "Voucher applied! You save 30,000đ"
}
```

**Response (Invalid):**
```json
{
  "success": true,
  "valid": false,
  "reason": "Minimum order amount is 100,000đ"
}
```

---

### 8.3 Rewards & Points

**Get Points Balance:**
```http
GET /api/rewards
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "points": 1500,
  "tier": "gold",
  "tier_progress": {
    "current_tier": "gold",
    "next_tier": "platinum",
    "points_needed": 500,
    "points_for_next": 2000
  },
  "available_rewards": [
    {
      "id": "uuid",
      "name": "Free Medium Coffee",
      "points_required": 500,
      "description": "Redeem for any medium coffee"
    }
  ]
}
```

**Points History:**
```http
GET /api/rewards/history
Authorization: Bearer <token>
```

---

## 9. Stores

### 9.1 Get Stores

```http
GET /api/stores
GET /api/stores?latitude=21.0045&longitude=105.8234
```

**Response:**
```json
{
  "success": true,
  "stores": [
    {
      "id": "uuid",
      "name": "42 Trần Vỹ",
      "address": "42 Trần Vỹ, Cầu Giấy, Hà Nội",
      "latitude": 21.0367,
      "longitude": 105.7833,
      "phone": "+84243123456",
      "image_url": "https://storage.../stores/tranvy.webp",
      "is_active": true,
      "delivery_enabled": true,
      "delivery_hours": {
        "start": "09:00",
        "end": "21:00"
      },
      "distance_km": 1.2,
      "current_occupancy": 45,
      "operating_hours": {
        "weekday": "07:00-22:00",
        "weekend": "08:00-23:00"
      }
    }
  ]
}
```

---

### 9.2 Get Single Store

```http
GET /api/stores/{storeId}
```

**Response:** Full store details including:
- Operating hours
- Current occupancy
- Available amenities (WiFi, Power outlets, Meeting rooms)
- Delivery zones
- Active events

---

### 9.3 Get Store Events

```http
GET /api/events?store_id=uuid
```

**Response:**
```json
{
  "success": true,
  "events": [
    {
      "id": "uuid",
      "title": "Startup Pitch Night",
      "description": "Monthly pitch event for startups",
      "date": "2026-01-20T19:00:00Z",
      "host_name": "The Coffee Links",
      "type": "networking",
      "image_url": "https://...",
      "registration_required": true,
      "spots_left": 15
    }
  ]
}
```

---

## 10. Database Schema Reference

### 10.1 Core Tables

#### Products

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `name` | TEXT | Product name |
| `description` | TEXT | Product description |
| `image` | TEXT | Image URL |
| `category_id` | UUID | FK → categories |
| `size_options` | JSONB | Size/price configuration |
| `available_toppings` | UUID[] | Array of topping IDs |
| `is_available` | BOOLEAN | Availability |
| `is_deliverable` | BOOLEAN | Can be delivered |
| `best_in_store` | BOOLEAN | Best fresh at store badge |

**`size_options` Structure:**
```json
{
  "small": { "enabled": false, "price": 0 },
  "medium": { "enabled": true, "price": 45000 },
  "large": { "enabled": true, "price": 55000 }
}
```

---

#### Orders

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | FK → users |
| `store_id` | UUID | FK → stores |
| `status` | TEXT | Order status |
| `total_amount` | DECIMAL | Order total |
| `pending_until` | TIMESTAMPTZ | Undo window expiry |
| `source` | TEXT | Order source |
| `delivery_option` | TEXT | pickup/dine_in/delivery |
| `delivery_fee` | DECIMAL | Delivery fee |
| `delivery_address_id` | UUID | FK → addresses |
| `notes` | TEXT | Order notes |

**Valid `source` values:** `manual`, `ai_suggested`, `reorder`, `favorite`

---

#### Order Items

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `order_id` | UUID | FK → orders |
| `product_id` | UUID | FK → products |
| `product_name` | TEXT | Snapshot |
| `quantity` | INTEGER | Item quantity |
| `size` | TEXT | Selected size |
| `price` | DECIMAL | Price at order time |
| `toppings` | JSONB | Selected toppings |
| `notes` | TEXT[] | Max 3 notes, 140 chars each |
| `is_favorite` | BOOLEAN | From favorites |

---

#### Addresses

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | FK → users |
| `full_address` | TEXT | Complete address |
| `label` | VARCHAR(50) | Home, Work, etc. |
| `latitude` | DECIMAL | GPS latitude |
| `longitude` | DECIMAL | GPS longitude |
| `is_default` | BOOLEAN | Default address |
| `delivery_notes` | TEXT | Access instructions |

---

#### Stores

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `name` | TEXT | Store name |
| `address` | TEXT | Store address |
| `latitude` | DECIMAL | Latitude |
| `longitude` | DECIMAL | Longitude |
| `delivery_enabled` | BOOLEAN | Accepts delivery |
| `delivery_hours_start` | TIME | Delivery start |
| `delivery_hours_end` | TIME | Delivery end |
| `min_delivery_amount` | DECIMAL | Min order for delivery |

---

### 10.2 Relationship Diagram

```
users ─┬─── orders
       ├─── addresses
       ├─── store_checkins
       ├─── connections
       ├─── user_presence
       ├─── user_blocks
       └─── user_reports

stores ─┬─── orders
        ├─── store_checkins
        ├─── user_presence
        └─── delivery_zones

products ─┬─── order_items
          ├─── product_popularity
          └─── categories (via category_id)

orders ────── order_items

addresses ─── orders.delivery_address_id
```

---

## 11. Error Handling

### 11.1 HTTP Status Codes

| Code | Meaning | When Used |
|------|---------|-----------|
| 200 | OK | Successful GET/PUT/DELETE |
| 201 | Created | Successful POST (new resource) |
| 400 | Bad Request | Invalid request body/params |
| 401 | Unauthorized | Missing/invalid auth token |
| 403 | Forbidden | No permission for resource |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate/constraint violation |
| 422 | Validation Error | Business logic validation failed |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Server Error | Unexpected server error |

---

### 11.2 Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Order minimum is 50,000đ for delivery",
    "field": "total_amount"
  }
}
```

---

### 11.3 Common Error Codes

| Code | Description |
|------|-------------|
| `INVALID_CREDENTIALS` | Wrong email/password |
| `TOKEN_EXPIRED` | Auth token expired |
| `VALIDATION_ERROR` | Request validation failed |
| `RESOURCE_NOT_FOUND` | Entity not found |
| `PERMISSION_DENIED` | No access to resource |
| `RATE_LIMITED` | Too many requests |
| `PRODUCT_UNAVAILABLE` | Product out of stock |
| `STORE_CLOSED` | Store not accepting orders |
| `DELIVERY_UNAVAILABLE` | Address not in delivery zone |
| `VOUCHER_INVALID` | Voucher code invalid |
| `VOUCHER_EXPIRED` | Voucher has expired |
| `MIN_ORDER_NOT_MET` | Below minimum order amount |

---

## 12. Security

### 12.1 Authentication

- JWT-based authentication via Supabase Auth
- Access tokens expire in 1 hour
- Refresh tokens valid for 7 days
- Tokens stored in iOS Keychain

### 12.2 Rate Limiting

| Endpoint Type | Limit |
|---------------|-------|
| Public (auth, menu) | 100 req/min |
| Authenticated | 1000 req/min |
| Connection requests | 10/hour |
| Orders | 30/hour |

### 12.3 Data Encryption

- All traffic over HTTPS
- Sensitive data (passwords) encrypted with AES
- Apple Sign In tokens validated server-side

### 12.4 Row Level Security

All database tables have RLS policies:
- Users can only access their own data
- Public data (products, stores) readable by all
- Service role for admin operations

---

## 13. Best Practices

### 13.1 Caching Strategy

| Data | Cache Duration | Invalidation |
|------|----------------|--------------|
| Menu | 5 minutes | On app foreground |
| Popular products | 5 minutes | Automatic |
| User profile | 1 minute | After update |
| Stores | 30 minutes | Manual refresh |
| Active orders | Real-time | WebSocket |

### 13.2 Offline Handling

1. Cache menu data locally
2. Allow browsing and cart building offline
3. Queue orders for sync when online
4. Show clear offline indicator

### 13.3 Image Loading

- All image URLs support WebP format
- Use lazy loading for lists
- Cache images locally
- Fallback to placeholder on failure

### 13.4 Error Recovery

1. Retry failed requests 3 times with exponential backoff
2. Show user-friendly error messages
3. Provide alternative actions (different payment method, etc.)
4. Log errors for debugging

### 13.5 Performance

- Minimize API calls (use /api/menu for full data)
- Batch updates where possible
- Use pagination for large lists
- Implement optimistic UI updates

---

## Appendix A: Quick Reference

### Common Endpoints

| Action | Method | Endpoint |
|--------|--------|----------|
| Login | POST | `/api/auth/login` |
| Get menu | GET | `/api/menu` |
| Create order | POST | `/api/orders` |
| Get orders | GET | `/api/orders` |
| Cancel order | POST | `/api/orders/{id}/cancel` |
| Get addresses | GET | `/api/addresses` |
| Check delivery | GET | `/api/delivery/availability` |
| Get stores | GET | `/api/stores` |
| Check in | POST | `/api/presence/check-in` |
| Connect | POST | `/api/connections/request` |

### Size Options

| Size | Key |
|------|-----|
| Small | `small` |
| Medium | `medium` |
| Large | `large` |

### Delivery Options

| Option | Value |
|--------|-------|
| Pickup | `pickup` |
| Dine In | `dine_in` |
| Delivery | `delivery` |

### Payment Methods

| Method | Value |
|--------|-------|
| Apple Pay | `apple_pay` |
| Credit Card | `card` |
| MoMo | `momo` |
| ZaloPay | `zalopay` |
| Cash | `cash` |

---

*This guide is generated for TheCoffeeLinks iOS client development team. For questions, contact the backend team.*
